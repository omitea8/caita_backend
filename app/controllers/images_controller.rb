class ImagesController < ApplicationController
  def imagelist
    creator = Creator.find_by(twitter_id: params[:creatorID])
    senddata = Image.where(creator_id: creator.id).select(:caption, :image_url, :id)
    render json: senddata.to_json
  end

  def imagedata
    image = Image.find_by(id: params[:imageID])
    senddata = {
      caption: image.caption,
      image_url: image.image_url,
      created_at: image.created_at
    }
    render json: senddata.to_json
  end
end
