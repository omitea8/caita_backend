Rails.application.routes.draw do

  get 'creators/login'
  post 'creators/gettoken'
  get 'creators/getprofile'
  get 'creators/:creatorID', to:'creators#creator'
  get 'creatros/imagedata'

end
