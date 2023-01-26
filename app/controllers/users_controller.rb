class UsersController < ApplicationController

    include ActionController::Cookies

    def login
        state = SecureRandom.hex(16)
        session[:state] = state
        challengeOrigin = SecureRandom.hex(16)
        session[:challengeOrigin] =challengeOrigin
        challenge = Digest::SHA256.hexdigest(challengeOrigin)
        render json: { url: 'https://twitter.com/i/oauth2/authorize?'\
            'response_type='\
            'code&client_id=YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ'\
            '&redirect_uri=http://127.0.0.1:3000/auth/twitter/callback'\
            '&scope=users.read'\
            "&state=#{state}"\
            "&code_challenge=#{challenge}"\
            '&code_challenge_method=s256' }
    end

end
