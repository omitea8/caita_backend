require 'aws-sdk-s3'

class ImagesController < ApplicationController
  # 画像Listを作成
  def imagelist
    creator = Creator.find_by(twitter_id: params[:creatorID])
    data = Image.where(creator_id: creator.id).select(:caption, :image_url, :image_name).order(created_at: :desc)
    render json: data.to_json
  end

  # 画像Dataを作成
  def imagedata
    image = Image.find_by(image_name: params[:image_name])
    data = {
      caption: image.caption,
      image_url: image.image_url,
      created_at: image.created_at
    }
    render json: data.to_json
  end

  # 画像投稿
  def post # rubocop:disable Metrics/AbcSize
    unless logged_in
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    unless validate_image(params[:image]) && validate_caption(params[:caption])
      render json: { message: 'Unprocessable Entity' }, status: 422
      return
    end
    image = create_image_from(params)
    unless image.save
      render json: { message: 'Internal Server Error' }, status: 500
      return
    end
    create_image_name(image)
    storage_name = create_storage_name(image)
    upload_to_aws(params[:image], storage_name)
    image_url = "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{storage_name}"
    image.update(image_url: image_url, storage_name: storage_name)
    render json: { message: 'Created' }, status: 201
  end

  # 画像を更新
  def update # rubocop:disable Metrics/AbcSize
    logged_in
    image = Image.find_by(image_name: params[:image_name])
    unless image.creator_id == @current_creator.id
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    if params[:image].present? && validate_image(params[:image])
      delete_from_aws(image, image.storage_name.to_s)
      storage_name = create_storage_name(image)
      upload_to_aws(params[:image], storage_name)
      image_url = "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{storage_name}"
      image.update(image_url: image_url, storage_name: storage_name)
    end
    if image.update(caption: params[:caption])
      render json: { message: 'No Content' }, status: 204
    else
      render json: { message: 'Unprocessable Entity' }, status: 422
    end
  end

  # 画像を削除
  def delete
    logged_in
    image = Image.find_by(image_name: params[:image_name])
    # 本人の画像か確認
    unless image.creator_id == @current_creator.id
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    delete_from_aws(image, image.storage_name.to_s)
    # DBから画像を削除
    image.destroy
    render json: { message: 'No Content' }, status: 204
  end

  private

  def generate_random_string
    SecureRandom.urlsafe_base64(12)
  end

  def create_storage_name(image)
    result = false
    storage_name = generate_random_string
    while result == false
      begin
        result = image.update(storage_name: storage_name)
      rescue StandardError
        storage_name = generate_random_string
      end
    end
    storage_name
  end

  def create_image_name(image)
    result = false
    image_name = generate_random_string
    while result == false
      begin
        result = image.update(image_name: image_name)
      rescue StandardError
        image_name = generate_random_string
      end
    end
    image_name
  end

  # 画像のデータを作成
  def create_image_from(params)
    Image.new(caption: params[:caption], creator_id: @current_creator.id)
  end

  # バリデーション
  def validate_image(image)
    image.is_a?(ActionDispatch::Http::UploadedFile) &&
      ['image/png', 'image/gif', 'image/jpeg'].include?(image.content_type) &&
      image.size <= 20.megabytes
  end

  def validate_caption(caption)
    caption.is_a?(String) && caption.length <= 1000
  end

  # AWS S3のクライアントを設定
  def create_s3_client
    Aws::S3::Client.new(
      region: ENV.fetch('AWS_REGION').freeze,
      access_key_id: ENV.fetch('AWS_ACCESS_KEY'),
      secret_access_key: ENV.fetch('AWS_SECRET_KEY')
    )
  end

  # AWS S3に画像をアップロード
  def upload_to_aws(image, key)
    client = create_s3_client
    client.put_object(
      bucket: ENV.fetch('AWS_BUCKET'),
      key: key,
      body: image,
      content_type: 'image/png',
      cache_control: 'no-cache, no-store, must-revalidate'
    )
  end

  # AWS S3から画像を削除
  def delete_from_aws(image, _key)
    client = create_s3_client
    client.delete_object(
      bucket: ENV.fetch('AWS_BUCKET'),
      key: image.storage_name.to_s
    )
  end
end
