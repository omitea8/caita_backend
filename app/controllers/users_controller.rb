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
            'response_type='\
            'code&client_id=YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ'\
            '&redirect_uri=http://localhost:3000/auth/twitter/callback'\
            '&scope=users.read'\
            "&state=#{state}"\
            "&code_challenge=#{challenge}"\
            '&code_challenge_method=S256' }
    end

    def getToken 
        # stateの検証
        checkstate = params[:state] === session[:state]
        # リクエストトークンの作成
        if checkstate == true
            url = URI.parse('https://api.twitter.com/2/oauth2/token')
            req = Net::HTTP::Post.new(url.path)
            req.basic_auth ENV['CLIENT_ID'], ENV['CLIENT_SECRET']
            req.set_form_data({
                'grant_type'=>'authorization_code',
                'client_id'=>'YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ',
                'code'=>params[:code],
                'code_verifier'=>session[:challengeVerifier],
                'redirect_uri'=>'http://localhost:3000/auth/twitter/callback'
            })
            http = Net::HTTP.new(url.host, 443)
            http.use_ssl = true
            res = http.start {|http| http.request(req) }
            json = JSON.parse(res.body)
            session[:accessToken] = json['access_token']
        else
        puts checkstate
        end
    end

end
