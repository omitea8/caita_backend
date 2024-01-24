class ApplicationController < ActionController::API
  private

  # ログインしているユーザーのcreator_idを取得
  def current_creator
    return unless session[:id]

    @current_creator ||= Creator.find_by(id: session[:id])
  end

  # creator_idのログインを確認
  def logged_in
    !current_creator.nil?
  end

  # AWS S3関連メソッド
  # AWS S3のクライアントを設定
  def create_s3_client
    Aws::S3::Client.new(
      region: ENV.fetch('AWS_REGION').freeze,
      access_key_id: ENV.fetch('AWS_ACCESS_KEY'),
      secret_access_key: ENV.fetch('AWS_SECRET_KEY')
    )
  end

  # AWS S3に画像をアップロード
  def upload_to_aws(image, key, content_type)
    client = create_s3_client
    client.put_object(
      bucket: ENV.fetch('AWS_BUCKET'),
      key: key,
      body: image,
      content_type: content_type,
      cache_control: 'no-cache, no-store, must-revalidate'
    )
  end

  # AWS S3から画像を削除
  def delete_from_aws(image)
    client = create_s3_client
    client.delete_objects(
      bucket: ENV.fetch('AWS_BUCKET'),
      delete: {
        objects: [
          {
            key: "#{image.storage_name}.webp"
          },
          {
            key: image.image_url.gsub(aws_bucket_url, '').to_s
          }
        ]
      }
    )
  end

  # AWS S3からクリエイターの画像を全て削除
  def delete_all_from_aws(creator)
    images = Image.where(creator_id: creator.id)
    images.each do |image|
      delete_from_aws(image)
    end
  end
end
