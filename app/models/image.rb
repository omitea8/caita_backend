class Image < ApplicationRecord
  belongs_to :creator

  validates :creator_id, presence: { message: 'ログインが必要です' }
  validates :caption, length: { maximum: 1000, message: 'キャプションは1000文字以下である必要があります' }

  # 該当クリエイターの全画像のデータを取得
  def self.create_imagelist(creator_id)
    Image.where(creator_id: creator_id).select(:caption, :image_url, :image_name).order(created_at: :desc)
  end

  # image_nameから画像を取得
  def self.create_imagedata(image_name)
    Image.find_by(image_name: image_name)
  end

  # 画像のデータを作成
  def self.create_image_from(caption, creator_id)
    Image.new(caption: caption, creator_id: creator_id)
  end

  # 画像を保存
  def self.image_save(image)
    image.save
  end

  # 画像のURLを更新
  def self.update_url(image, image_url, storage_name)
    image.update(image_url: image_url, storage_name: storage_name)
  end

  # キャプションの更新
  def self.update_caption(image, caption)
    image.update(caption: caption)
  end

  # 画像を削除
  def self.image_delete(image)
    image.destroy
  end
end
