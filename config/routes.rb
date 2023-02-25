Rails.application.routes.draw do

  get 'creators/login'
  post 'creators/gettoken'
  get 'creators/getprofile'
  get 'creators/imagedata'
  get 'creators/:creatorID', to:'creators#creator'

end
