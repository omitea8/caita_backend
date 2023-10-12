class Creator < ApplicationRecord
  has_many :image

  # twitterIDからクリエイターを検索
  def self.search_creator_from_twitter_id(twitter_id)
    Creator.find_by(twitter_id: twitter_id)
  end

  # idを使ってクリエイターを検索
  def self.search_creator_from_id(id)
    Creator.find_by(id: id)
  end

  # クリエイター情報をすべて更新
  def self.allupdate_creator(creator)
    Creator.upsert_all(creator, unique_by: :twitter_system_id)
  end
end
