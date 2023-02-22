
30.times do
    DemoDatum.create!(
        title: Faker::Lorem.sentence(word_count: 10),
        caption: Faker::Lorem.sentence(word_count: 50),
        image_url: "https://picsum.photos/300",
        creator_id: 1,
        created_at: Faker::Date.between(from: 1.year.ago, to: Date.today)
    )
end