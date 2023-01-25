class UsersController < ApplicationController

    def login
        render json: { url: 'https://twitter.com/i/oauth2/authorize?'\
            'response_type='\
            'code&client_id=YWZ0cFpwWGVsSGlVcVgwTGJ6elo6MTpjaQ'\
            '&redirect_uri=http://127.0.0.1:3000/auth/twitter/callback'\
            '&scope=users.read'\
            '&state=abc'\
            '&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'\
            '&code_challenge_method=s256' }
    end

end
