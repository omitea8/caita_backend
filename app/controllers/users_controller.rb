class UsersController < ApplicationController

    include ActionController::Cookies
    require 'base64'
    require 'net/http'
    require 'uri'

    def login
        state = SecureRandom.hex(16)
        session[:state] = state
        challengeVerifier= SecureRandom.alphanumeric(50)
        session[:challengeVerifier] =challengeVerifier
        challengeHash = Digest::SHA256.digest(challengeVerifier)
        challenge = Base64.urlsafe_encode64(challengeHash, padding: false)
        render json: { url: 'https://twitter.com/i/oauth2/authorize?'\
            "response_type=code"\
            "&client_id=#{ENV['CLIENT_ID']}"\
            "&redirect_uri=#{ENV['TWITTER_CALLBACK_URL']}"\
            "&scope=tweet.read%20users.read"\
            "&state=#{state}"\
            "&code_challenge=#{challenge}"\
            '&code_challenge_method=S256'}
    end

    def gettoken 
        # stateの検証
        checkstate = params[:state] === session[:state]
        # stateの検証がtrueだったら
        if checkstate == true
            # リクエストトークンの作成
            url = URI.parse('https://api.twitter.com/2/oauth2/token')
            req = Net::HTTP::Post.new(url.path)
            req.basic_auth ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
            req.set_form_data({
                'grant_type'=>'authorization_code',
                'client_id'=>ENV['CLIENT_ID'],
                'code'=>params[:code],
                'code_verifier'=>session[:challengeVerifier],
                'redirect_uri'=>ENV['TWITTER_CALLBACK_URL']
            })
            http = Net::HTTP.new(url.host, 443)
            http.use_ssl = true
            res = http.start {|http| http.request(req) }
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
        uri = URI.parse("https://api.twitter.com/2/users/me")
        uri.query = URI.encode_www_form({"user.fields": "description,profile_image_url"})
        headers = {
            'Authorization'=>"Bearer #{session[:accessToken]}",
        }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        res = http.get(uri, headers)
        # frontednに任意のデータを送る
        body = JSON.parse(res.body)
        senddata = body['data'].extract!( 'username', 'profile_image_url', 'description')
        senddataJson = senddata.to_json
        render json: senddataJson
        # ユーザーを登録する
        usersdata = JSON.parse(res.body)
        users = [
            twitter_system_id: usersdata['data']['id'],
            twitter_id: usersdata['data']['name'],
            twitter_name: usersdata['data']['username'],
            twitter_profile_image: usersdata['data']['profile_image_url'],
            twitter_description: usersdata['data']['description'],
        ]
        User.upsert_all(users,unique_by: :twitter_system_id)
    end

end
