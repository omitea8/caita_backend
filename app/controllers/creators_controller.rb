class CreatorsController < ApplicationController
  include ActionController::Cookies
  require 'base64'
  require 'net/http'
  require 'uri'

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
    render json: { message: res.message }.to_json
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

  # ログインクリエイター情報をDBから取得
  def current_creator_profile
    # session[:id]を使ってクリエイターを探す
    creator = Creator.find_by(id: session[:id])
    # frontendに任意のデータを送る
    data = {
      name: creator.twitter_name,
      username: creator.twitter_id,
      profile_image_url: creator.twitter_profile_image,
      description: creator.twitter_description
    }
    render json: data.to_json
  end

  # クリエイター情報をDBから取得
  def creator_profile
    creator = Creator.find_by(twitter_id: params[:creatorID])
    data = {
      twitter_name: creator.twitter_name,
      twitter_profile_image: creator.twitter_profile_image,
      twitter_description: creator.twitter_description
    }
    render json: data.to_json
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
    Creator.upsert_all(creator, unique_by: :twitter_system_id)
  end
end
