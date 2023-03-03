# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 20_230_224_061_801) do
  create_table 'creators', force: :cascade do |t|
    t.string 'twitter_system_id'
    t.string 'twitter_id'
    t.string 'twitter_name'
    t.string 'twitter_profile_image'
    t.string 'twitter_description'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['twitter_system_id'], name: 'index_creators_on_twitter_system_id', unique: true
  end

  create_table 'images', force: :cascade do |t|
    t.string 'title'
    t.text 'caption'
    t.string 'image_url'
    t.integer 'creator_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[creator_id created_at], name: 'index_images_on_creator_id_and_created_at'
    t.index ['creator_id'], name: 'index_images_on_creator_id'
  end

  add_foreign_key 'images', 'creators'
end
