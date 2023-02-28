class ImagesController < ApplicationController
  def imagedata
    creator = Creator.find_by(twitter_id: params[:creatorID])
    creatorId = Creator.find_by(id: creator)
    senddata = Image.where(creator_id: creatorId)
    render json: senddata.to_json
  end
end
