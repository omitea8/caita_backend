Creator.create!(
  twitter_system_id: '1550801734288949250',
  twitter_id: 'omitea8',
  twitter_name: 'omi.t',
  twitter_profile_image: 'https://pbs.twimg.com/profile_images/1553015245853310976/VAR7Y-KA_normal.jpg',
  twitter_description: 'エンジニアになるためにプログラミング勉強中'
)

Creator.create!(
  twitter_system_id: '1077740235125972993',
  twitter_id: 'zomysan',
  twitter_name: 'zomy / Scrum Master, Software Engineer',
  twitter_profile_image: 'https://pbs.twimg.com/profile_images/1541082931195957248/XAQiJxYE_normal.jpg',
  twitter_description: '犬と暮らすことが夢で寿司が好きなソフトウェアエンジニア / 現ロールはスクラムマスター / チーム開発、生活、ゲーム、個人開発について話します / Discord日本語読み上げBot shovel 運営中'
)

30.times do
  Image.create!(
    title: Faker::Lorem.sentence(word_count: 3),
    caption: Faker::Lorem.sentence(word_count: 10),
    image_url: 'https://picsum.photos/300',
    creator_id: 1,
    created_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
  )
end

30.times do
  Image.create!(
    caption: Faker::Lorem.sentence(word_count: 10),
    image_url: 'https://picsum.photos/300',
    creator_id: 2,
    created_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
  )
end
