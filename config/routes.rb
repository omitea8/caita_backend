Rails.application.routes.draw do
  get 'creators/login'
  post 'creators/token_get'
  get 'creators/profile_get'
  get 'creators/icon_image'
  get 'creators/:creatorID', to: 'creators#creator'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  post 'images/post'
  get 'images/:imageID', to: 'images#imagedata'
  delete 'images/:imageID', to: 'images#imagedelete'
end
