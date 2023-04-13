class Image < ApplicationRecord
  belongs_to :creator

  validates :creator_id, presence: { message: 'ログインが必要です' }
  validates :caption, length: { maximum: 1000, message: 'キャプションは1000文字以下である必要があります' }
end
