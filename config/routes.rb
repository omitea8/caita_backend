Rails.application.routes.draw do
  get 'creators/login'
  post 'creators/token_get'
  get 'creators/getprofile'
  post 'images/post'
  get 'creators/:creatorID', to: 'creators#creator'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  get 'images/:imageID', to: 'images#imagedata'
end
