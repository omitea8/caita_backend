Rails.application.routes.draw do

  get 'creator/login'
  post 'creator/gettoken'
  get 'creator/getprofile'

end
