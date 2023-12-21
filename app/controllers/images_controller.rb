require 'aws-sdk-s3'

class ImagesController < ApplicationController
  # 画像Listを作成
  def imagelist
    creator = Creator.search_creator_from_twitter_id(params[:creator_id])
    data = Image.create_imagelist(creator.id)
    render json: data.to_json
  end

  # 画像Dataを作成
  def imagedata
    image = Image.create_imagedata(params[:image_name])
    data = {
      caption: image.caption,
      image_url: image.image_url,
      created_at: image.created_at
    }
    render json: data.to_json
  end

  # 画像投稿機能
  def post # rubocop:disable Metrics/AbcSize
    unless logged_in
      render json: { message: 'Unauthorized' }, status: 401 # 未ログイン
      return
    end
    unless validate_image(params[:image]) && validate_caption(params[:caption])
      render json: { message: 'Unprocessable Entity' }, status: 422 # バリデーションエラー
      return
    end
    image = Image.create_image_from(params[:caption], @current_creator.id)
    unless Image.image_save(image)
      render json: { message: 'Internal Server Error' }, status: 500 # サーバーエラー
      return
    end
    create_image_name(image)
    storage_name = create_storage_name(image)
    upload_to_aws(params[:image], storage_name)
    image_url = "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{storage_name}"
    Image.update_url(image, image_url, storage_name)
    render json: { message: 'Created' }, status: 201
  end

  # 画像を更新
  def update # rubocop:disable Metrics/AbcSize
    logged_in
    image = Image.create_imagedata(params[:image_name])
    unless image.creator_id == @current_creator.id
      render json: { message: 'Unauthorized' }, status: 401 # 本人の画像か確認
      return
    end
    if params[:image].present? && validate_image(params[:image]) # 画像がある場合
      delete_from_aws(image, image.storage_name.to_s)
      storage_name = create_storage_name(image)
      upload_to_aws(params[:image], storage_name)
      image_url = "https://#{ENV.fetch('AWS_BUCKET')}.s3.#{ENV.fetch('AWS_REGION')}.amazonaws.com/#{storage_name}"
      Image.update_url(image, image_url, storage_name)
    end
    if Image.update_caption(image, params[:caption])
      render json: { message: 'No Content' }, status: 204
    else
      render json: { message: 'Unprocessable Entity' }, status: 422 # バリデーションエラー
    end
  end

  # 画像を削除
  def delete
    logged_in
    image = Image.create_imagedata(params[:image_name])
    unless image.creator_id == @current_creator.id
      render json: { message: 'Unauthorized' }, status: 401 # 本人の画像か確認
      return
    end
    delete_from_aws(image, image.storage_name.to_s)
    Image.image_delete(image)
    render json: { message: 'No Content' }, status: 204
  end

  private

  # ランダムな文字列を生成
  def generate_random_string
    SecureRandom.urlsafe_base64(12)
  end

  # storage_nameを作成
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

  # image_nameを作成
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

  # バリデーション
  def validate_image(image)
    image.is_a?(ActionDispatch::Http::UploadedFile) &&
      ['image/png', 'image/gif', 'image/jpeg'].include?(image.content_type) &&
      image.size <= 20.megabytes
  end

  def validate_caption(caption)
    caption.is_a?(String) && caption.length <= 1000
  end
end
