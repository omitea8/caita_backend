class Image < ApplicationRecord
  belongs_to :creator
  has_one_attached :images
end
