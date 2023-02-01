class UsersController < ApplicationController

    include ActionController::Cookies

    def login
        state = SecureRandom.hex(16)
        session[:state] = state
        puts session[:state]
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
        puts session[:state]
        puts params[:state]
        checkstate = params[:state] === session[:state]
        puts checkstate
    end

end
