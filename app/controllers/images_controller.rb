class ImagesController < ApplicationController
  def imagedata
    creator = Creator.find_by(twitter_id: params[:creatorID])
    creatorId = Creator.find_by(id: creator)
    senddata = Image.where(creator_id: creatorId).select(:title, :caption, :image_url, :id)
    render json: senddata.to_json
  end
end
