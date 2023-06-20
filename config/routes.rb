Rails.application.routes.draw do
  get 'creators/login_url'
  post 'creators/handle_token_callback'
  get 'creators/current_creator_profile'
  get 'creators/:creatorID', to: 'creators#creator_profile'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  post 'images/post'
  get 'images/:storage_name', to: 'images#imagedata'
  delete 'images/:storage_name', to: 'images#delete'
  put 'images/:storage_name', to: 'images#update'
end
