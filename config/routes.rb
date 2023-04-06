Rails.application.routes.draw do
  get 'creators/login'
  post 'creators/get_token'
  get 'creators/getprofile'
  post 'images/post'
  get 'creators/:creatorID', to: 'creators#creator'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  get 'images/:imageID', to: 'images#imagedata'
end
