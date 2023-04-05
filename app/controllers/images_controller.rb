require 'aws-sdk-s3'

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

  def upload_to_aws(image, key)
    client = Aws::S3::Client.new(
      region: ENV.fetch('AWS_REGION').freeze,
      access_key_id: ENV.fetch('AWS_ACCESS_KEY'),
      secret_access_key: ENV.fetch('AWS_SECRET_KEY')
    )
    client.put_object(
      bucket: ENV.fetch('AWS_BUCKET'),
      key: key,
      body: image,
      content_type: 'image/png'
    )
  end

  def post
    current_creator
    unless logged_in
      render json: 'NG'.to_json
      return
    end
    post_data = Image.new(caption: params[:caption], creator_id: @current_creator.id)
    if post_data.save
      upload_to_aws(params[:image], post_data.id.to_s)
      post_data.update(image_url: "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{post_data.id}")
      render json: 'OK'.to_json
    else
      render json: 'NG'.to_json
    end
  end
end
