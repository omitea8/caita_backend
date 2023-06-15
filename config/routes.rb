Rails.application.routes.draw do
  get 'creators/login_url'
  post 'creators/handle_token_callback'
  get 'creators/current_creator_profile'
  get 'creators/icon_image'
  get 'creators/:creatorID', to: 'creators#creator_profile'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  post 'images/post'
  get 'images/:imageID', to: 'images#imagedata'
  delete 'images/:imageID', to: 'images#delete'
  put 'images/:imageID', to: 'images#update'
end
