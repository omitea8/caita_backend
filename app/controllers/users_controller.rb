class UsersController < ApplicationController

    def login
        render json: { url: 'http://google.com' }
    end

end
