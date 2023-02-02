class UsersController < ApplicationController

    include ActionController::Cookies
    require 'net/http'
    require 'uri'

    def login
        state = SecureRandom.hex(16)
        session[:state] = state
        challengeOrigin = SecureRandom.hex(16)
        session[:challengeOrigin] =challengeOrigin
        challenge = Digest::SHA256.hexdigest(challengeOrigin)
        render json: { url: 'https://twitter.com/i/oauth2/authorize?'\
            'response_type='\
            'code&client_id=YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ'\
            '&redirect_uri=http://localhost:3000/auth/twitter/callback'\
            '&scope=users.read'\
            "&state=#{state}"\
            "&code_challenge=#{challenge}"\
            '&code_challenge_method=s256' }
    end

    def getToken 
        # stateの検証
        checkstate = params[:state] === session[:state]
        # リクエストトークンの作成
        puts params[:code]
        if checkstate == true
            req = Net::HTTP.(URI.parse('https://api.twitter.com/2/oauth2/token'),
            {
            'grant_type'=>'authorization_code',
            'client_id'=>'YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ',
            'code'=>params[:code],
            'redirect_uri'=>'http://localhost:3000/auth/twitter/callback',
            'code_verifier'=>session[:challengeOrigin]
            })
            puts req.body
            else
            puts checkstate
        end
    end

end
