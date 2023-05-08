require 'aws-sdk-s3'

class ImagesController < ApplicationController
  # 画像Listを作成
  def imagelist
    creator = Creator.find_by(twitter_id: params[:creatorID])
    senddata = Image.where(creator_id: creator.id).select(:caption, :image_url, :id).order(created_at: :desc)
    render json: senddata.to_json
  end

  # 画像Dataを作成
  def imagedata
    image = Image.find_by(id: params[:imageID])
    senddata = {
      caption: image.caption,
      image_url: image.image_url,
      created_at: image.created_at
    }
    render json: senddata.to_json
  end

  # 画像投稿
  def post # rubocop:disable Metrics/AbcSize
    current_creator
    unless logged_in
      render json: 'NG'.to_json
      return
    end
    unless validate_image(params[:image])
      render json: 'NG'.to_json
      return
    end
    post_data = create_post_data(params)
    if post_data.save
      upload_to_aws(params[:image], post_data.id.to_s)
      post_data.update(image_url: "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{post_data.id}")
      render json: 'OK'.to_json
    else
      render json: 'NG'.to_json
    end
  end

  # 画像を削除
  def imagedelete # rubocop:disable Metrics/AbcSize
    current_creator
    image = Image.find_by(id: params[:imageID])
    # 本人の画像か確認
    unless image.creator_id == @current_creator.id
      puts image.creator_id
      puts @current_creator.id
      render json: 'NG'.to_json
      return
    end
    delete_to_aws(image, image.id.to_s)
    # DBから画像を削除
    image.destroy
    head :ok
  end

  private

  # AWS S3に画像をアップロード
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

  # 画像のデータを作成
  def create_post_data(params)
    Image.new(caption: params[:caption], creator_id: @current_creator.id)
  end

  # 画像のバリデーション
  def validate_image(image)
    image.is_a?(ActionDispatch::Http::UploadedFile) &&
      ['image/png', 'image/gif', 'image/jpeg'].include?(image.content_type) &&
      image.size <= 20.megabytes
  end

  # AWS S3から画像を削除
  def delete_to_aws(image, _key)
    client = Aws::S3::Client.new(
      region: ENV.fetch('AWS_REGION').freeze,
      access_key_id: ENV.fetch('AWS_ACCESS_KEY'),
      secret_access_key: ENV.fetch('AWS_SECRET_KEY')
    )
    client.delete_object(
      bucket: ENV.fetch('AWS_BUCKET'),
      key: image.id.to_s
    )
  end
end
