Rails.application.routes.draw do
  get 'creators/login_url'
  post 'creators/handle_token_callback'
  get 'creators/current_creator_profile'
  get 'creators/:creator_id', to: 'creators#creator_profile'
  post 'creators/logout'
  delete 'creators/delete_creator'
  get 'images/creator/:creator_id', to: 'images#imagelist'
  post 'images/post'
  get 'images/:image_name', to: 'images#imagedata'
  delete 'images/:image_name', to: 'images#delete'
  put 'images/:image_name', to: 'images#update'
end
