class ImagesController < ApplicationController
  def imagedata
    render json: Image.where(creator_id: '1').to_json
  end
end
