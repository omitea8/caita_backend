class CreatorsController < ApplicationController
  include ActionController::Cookies
  require 'base64'
  require 'net/http'
  require 'uri'

  # ログインURLの作成
  def login_url
    state = SecureRandom.hex(16)
    session[:state] = state
    challenge_verifier = SecureRandom.alphanumeric(50)
    session[:challengeVerifier] = challenge_verifier
    challenge_hash = Digest::SHA256.digest(challenge_verifier)
    challenge = Base64.urlsafe_encode64(challenge_hash, padding: false)
    render json: { url: 'https://twitter.com/i/oauth2/authorize?' \
                        'response_type=code' \
                        "&client_id=#{ENV.fetch('CLIENT_ID', nil)}" \
                        "&redirect_uri=#{ENV.fetch('TWITTER_CALLBACK_URL', nil)}" \
                        '&scope=tweet.read%20users.read' \
                        "&state=#{state}" \
                        "&code_challenge=#{challenge}" \
                        '&code_challenge_method=S256' }
  end

  # トークンを作成
  def handle_token_callback # rubocop:disable Metrics/AbcSize
    # stateの検証
    return unless params[:state].match?(session[:state])

    res = send_token_request(
      ENV.fetch('CLIENT_ID', nil),
      ENV.fetch('CLIENT_SECRET', nil),
      params[:code],
      session[:challengeVerifier],
      ENV.fetch('TWITTER_CALLBACK_URL', nil)
    )
    body = fetch_me_from_twitter(JSON.parse(res.body)['access_token'])['data']
    register_creator(body)
    session[:id] = Creator.find_by(twitter_system_id: body['id']).id
    session[:login_time] = Time.current
    render json: { message: 'ok' }, status: 200
  end

  # トークンをtwitterにリクエストする
  def send_token_request(client_id, client_secret, code, challenge, callback_url)
    url = URI.parse('https://api.twitter.com/2/oauth2/token')
    req = Net::HTTP::Post.new(url.path)
    req.basic_auth client_id, client_secret
    req.set_form_data({
                        'grant_type' => 'authorization_code',
                        'client_id' => client_id,
                        'code' => code,
                        'code_verifier' => challenge,
                        'redirect_uri' => callback_url
                      })
    http = Net::HTTP.new(url.host, 443)
    http.use_ssl = true
    http.start { |h| h.request(req) }
  end

  # twitterからユーザー情報を取得
  def fetch_me_from_twitter(access_token) # rubocop:disable Metrics/AbcSize
    uri = URI.parse('https://api.twitter.com/2/users/me')
    uri.query = URI.encode_www_form({ 'user.fields': 'description,profile_image_url' })
    headers = {
      'Authorization' => "Bearer #{access_token}"
    }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.get(uri, headers)
    # デバッグ用
    puts res.header['x-rate-limit-remaining'].to_i
    puts res.header['x-rate-limit-reset'].to_i

    JSON.parse(res.body)
  end

  # ログインクリエイターのプロフィールを取得
  def current_creator_profile
    unless logged_in
      render json: { error: 'Not Login' }, status: 401
      return
    end
    creator = Creator.search_creator_from_id(session[:id])
    data = {
      name: creator.twitter_name,
      username: creator.twitter_id,
      profile_image_url: creator.twitter_profile_image,
      description: creator.twitter_description
    }
    render json: data.to_json
  end

  # twitterIDを使ってプロフィールを取得
  def creator_profile
    creator = Creator.search_creator_from_twitter_id(params[:creator_id])
    data = {
      twitter_name: creator.twitter_name,
      twitter_profile_image: creator.twitter_profile_image,
      twitter_description: creator.twitter_description
    }
    render json: data.to_json
  end

  # ログアウト
  def logout
    session.clear
    session[:id] = nil
    render json: { message: 'ok' }, status: 200
  end

  # クリエイターを削除
  def delete_creator
    unless logged_in
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    if expired_session?
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    creator = Creator.search_creator_from_id(session[:id])
    delete_all_from_aws(creator)
    Image.where(creator_id: creator.id).destroy_all
    creator.destroy
    logout
  end

  private

  # クリエイターをDBに登録
  def register_creator(body)
    creator = [
      twitter_system_id: body['id'],
      twitter_id: body['username'],
      twitter_name: body['name'],
      twitter_profile_image: body['profile_image_url'],
      twitter_description: body['description']
    ]
    Creator.allupdate_creator(creator)
  end

  # session[:login_time]が3分以上経過しているか確認
  def expired_session?
    Time.current - Time.iso8601(session[:login_time]) > 3.minutes
  end
end
