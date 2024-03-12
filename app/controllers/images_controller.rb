require 'aws-sdk-s3'
require 'mini_magick'
require 'stringio'

class ImagesController < ApplicationController
  # 画像Listを作成
  def imagelist
    creator = Creator.search_creator_from_twitter_id(params[:creator_id])
    image_data = Image.create_imagelist(creator.id)
    data = image_data.map do |image|
      {
        caption: image.caption,
        image_name: image.image_name,
        resized_image_url: "#{aws_bucket_url}#{image.storage_name}.webp"
      }
    end
    render json: data.to_json
  end

  # 画像Dataを作成
  def imagedata
    image = Image.create_imagedata(params[:image_name])
    resized_image_url = "#{aws_bucket_url}#{image.storage_name}.webp"
    data = {
      caption: image.caption,
      image_url: image.image_url,
      resized_image_url: resized_image_url
    }
    render json: data.to_json
  end

  # 画像投稿機能
  def post # rubocop:disable Metrics/AbcSize
    unless logged_in
      render json: { message: 'Unauthorized' }, status: 401
      return
    end
    Benchmark.bm 20 do |r|
      r.report 'validate' do
        unless validate_image(params[:image]) && validate_caption(params[:caption])
          render json: { message: 'Unprocessable Entity' }, status: 422
          return
        end
      end
      # TODO: transactionの使い方をRails有識者に聞く
      begin
        ActiveRecord::Base.transaction do
          image = nil
          r.report 'create_image' do
            image = Image.create_image_from(params[:caption], @current_creator.id)
            raise ActiveRecord::Rollback unless Image.image_save(image)

            create_image_name(image)
          end
          r.report 'update_imagedata' do
            update_imagedata(image)
            render json: { message: 'Created' }, status: 201
          end
        end
      rescue ActiveRecord::Rollback
        render json: { message: 'Internal Server Error' }, status: 500
      end
    end
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
      delete_from_aws(image)
      update_imagedata(image)
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
    delete_from_aws(image)
    Image.image_delete(image)
    render json: { message: 'No Content' }, status: 204
  end

  private

  # ランダムな文字列を生成
  def generate_random_string
    SecureRandom.urlsafe_base64(12)
  end

  # TODO: コメントにstaraoge_nameとimage_nameの違いについて書く
  # strage_nameを作成
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

  # AWS S3投稿画像の作成
  def upload_multi_size_image_to_aws(image_data, storage_name, content_type)
    temp_image = image_data
    input_image = MiniMagick::Image.open(temp_image.tempfile.path)
    input_image.resize '1200x1200>'
    input_image.format 'webp'
    upload_to_aws(input_image.to_blob, "#{storage_name}.webp", 'image/webp')
    # content_typeを使って元画像に拡張子をつける
    storage_name_original = "#{storage_name}.#{content_type.sub(%r{image/}, '')}"
    upload_to_aws(image_data, storage_name_original, content_type)
  end

  # 画像をAWS S3にアップロードしURLをDBに保存
  def update_imagedata(image)
    storage_name = create_storage_name(image)
    content_type = params[:image].content_type
    upload_multi_size_image_to_aws(params[:image], storage_name, content_type)
    image_url = "#{aws_bucket_url}#{storage_name}.#{content_type.sub(%r{image/}, '')}"
    Image.update_url(image, image_url, storage_name)
  end

  # バリデーション
  def validate_image(image)
    image.is_a?(ActionDispatch::Http::UploadedFile) &&
      ['image/png', 'image/jpeg', 'image/webp'].include?(image.content_type) &&
      image.size <= 20.megabytes
  end

  def validate_caption(caption)
    caption.is_a?(String) && caption.length <= 1000
  end
end
