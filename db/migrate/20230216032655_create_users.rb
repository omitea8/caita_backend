class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :twitter_system_id
      t.string :twitter_id
      t.string :twitter_name
      t.string :twitter_profile_imge
      t.string :twitter_description
      t.string :token

      t.timestamps
    end
  end
end
