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
    unless validate_image(params[:image]) && validate_caption(params[:caption])
      render json: 'NG'.to_json
      return
    end
    post_data = create_post_data(params)
    if post_data.save
      upload_to_aws(params[:image], post_data.id.to_s)
      post_data.update(image_url: "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{post_data.id}")
      head :ok
    else
      render json: 'NG'.to_json
    end
  end

  # 画像を削除
  def imagedelete
    current_creator
    image = Image.find_by(id: params[:imageID])
    # 本人の画像か確認
    unless image.creator_id == @current_creator.id
      render json: 'NG'.to_json
      return
    end
    delete_to_aws(image, image.id.to_s)
    # DBから画像を削除
    image.destroy
    head :ok
  end

  # 画像を更新
  def imageupdate # rubocop:disable Metrics/AbcSize
    current_creator
    image = Image.find_by(id: params[:imageID])
    # 本人の画像か確認
    unless image.creator_id == @current_creator.id
      render json: 'NG'.to_json
      return
    end
    # AWSを更新
    upload_to_aws(params[:image], image.id.to_s)
    # DBを更新
    image.update(caption: params[:caption])
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

  # キャプションのバリデーション
  def validate_caption(caption)
    caption.is_a?(String) && caption.length <= 1000
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
