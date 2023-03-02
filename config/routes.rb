Rails.application.routes.draw do
  get 'creators/login'
  post 'creators/gettoken'
  get 'creators/getprofile'
  get 'creators/:creatorID', to: 'creators#creator'
  get 'images/creator/:creatorID', to: 'images#imagelist'
  get 'images/:imageID', to: 'images#imagedata'
end
