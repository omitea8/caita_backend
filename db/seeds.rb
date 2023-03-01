30.times do
  Image.create!(
    title: Faker::Lorem.sentence(word_count: 3),
    caption: Faker::Lorem.sentence(word_count: 10),
    image_url: 'https://picsum.photos/300',
    creator_id: 2,
    created_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
  )
end
