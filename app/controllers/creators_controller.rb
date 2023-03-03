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

  def gettoken
    # stateの検証
    checkstate = params[:state] === session[:state]
    # stateの検証がtrueだったら
    if checkstate == true
      # リクエストトークンの作成
      url = URI.parse('https://api.twitter.com/2/oauth2/token')
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth ENV.fetch('CLIENT_ID', nil), ENV.fetch('CLIENT_SECRET', nil)
      req.set_form_data({
                          'grant_type' => 'authorization_code',
                          'client_id' => ENV.fetch('CLIENT_ID', nil),
                          'code' => params[:code],
                          'code_verifier' => session[:challengeVerifier],
                          'redirect_uri' => ENV.fetch('TWITTER_CALLBACK_URL', nil)
                        })
      http = Net::HTTP.new(url.host, 443)
      http.use_ssl = true
      res = http.start { |h| h.request(req) }
      json = JSON.parse(res.body)
      # アクセストークンをsessionに保存
      session[:accessToken] = json['access_token']
      # フロントエンドにログイン成功を送る
      render json: { message: res.message }.to_json
    else
      # stateの検証がfalseだったら
      puts checkstate
    end
  end

  def getprofile
    # twitterのプロフィール情報を取得
    uri = URI.parse('https://api.twitter.com/2/users/me')
    uri.query = URI.encode_www_form({ 'user.fields': 'description,profile_image_url' })
    headers = {
      'Authorization' => "Bearer #{session[:accessToken]}"
    }
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    res = http.get(uri, headers)
    # frontednに任意のデータを送る
    body = JSON.parse(res.body)
    senddata = body['data'].extract!('name', 'profile_image_url', 'description')
    senddata_json = senddata.to_json
    render json: senddata_json
    # ユーザーを登録する
    creatordata = JSON.parse(res.body)
    creator = [
      twitter_system_id: creatordata['data']['id'],
      twitter_id: creatordata['data']['username'],
      twitter_name: creatordata['data']['name'],
      twitter_profile_image: creatordata['data']['profile_image_url'],
      twitter_description: creatordata['data']['description']
    ]
    Creator.upsert_all(creator, unique_by: :twitter_system_id)
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
