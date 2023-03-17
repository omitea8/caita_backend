class CreatorsController < ApplicationController
  include ActionController::Cookies
  require 'base64'
  require 'net/http'
  require 'uri'

  def login
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

  def request_url(client_id, client_secret, code, challenge, callback_url)
    # リクエストトークンの作成
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

  def gettoken # rubocop:disable Metrics/AbcSize
    # stateの検証
    checkstate = params[:state].match?(session[:state])
    # stateの検証がtrueだったら
    return unless checkstate == true

    res = request_url(ENV.fetch('CLIENT_ID', nil),
                      ENV.fetch('CLIENT_SECRET', nil),
                      params[:code],
                      session[:challengeVerifier],
                      ENV.fetch('TWITTER_CALLBACK_URL', nil))
    # アクセストークンをsessionに保存
    session[:accessToken] = JSON.parse(res.body)['access_token']
    # フロントエンドにログイン成功を送る
    render json: { message: res.message }.to_json
  end

  def getme(access_token)
    # プロフィール情報を取得
    uri = URI.parse('https://api.twitter.com/2/users/me')
    uri.query = URI.encode_www_form({ 'user.fields': 'description,profile_image_url' })
    headers = {
      'Authorization' => "Bearer #{access_token}"
    }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.get(uri, headers)
    JSON.parse(res.body)
  end

  def getprofile # rubocop:disable Metrics/AbcSize
    # frontednに任意のデータを送る
    body = getme(session[:accessToken])['data']
    render json: body.slice('name', 'profile_image_url', 'description').to_json
    # ユーザーを登録する
    creator = [
      twitter_system_id: body['id'],
      twitter_id: body['username'],
      twitter_name: body['name'],
      twitter_profile_image: body['profile_image_url'],
      twitter_description: body['description']
    ]
    Creator.upsert_all(creator, unique_by: :twitter_system_id)
    session[:id] = Creator.find_by(twitter_system_id: body['id']).id
  end

  def creator
    creator = Creator.find_by(twitter_id: params[:creatorID])
    senddata = {
      twitter_name: creator.twitter_name,
      twitter_profile_image: creator.twitter_profile_image,
      twitter_description: creator.twitter_description
    }
    render json: senddata.to_json
  end
end
