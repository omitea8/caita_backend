Rails.application.routes.draw do

  get 'users/login'
  post 'users/getToken'
  get 'users/getProifile'

end
