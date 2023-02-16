Rails.application.routes.draw do

  get 'users/login'
  post 'users/gettoken'
  get 'users/getprofile'

end
