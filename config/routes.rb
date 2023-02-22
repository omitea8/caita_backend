Rails.application.routes.draw do

  get 'creators/login'
  post 'creators/gettoken'
  get 'creators/getprofile'

end
