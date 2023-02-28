Rails.application.routes.draw do
  get 'creators/login'
  post 'creators/gettoken'
  get 'creators/getprofile'
  get 'images/imagedata'
  get 'creators/:creatorID', to: 'creators#creator'
end
