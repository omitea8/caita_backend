class AddUniqueIndexToUsersTwitterSystemId < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :twitter_system_id, unique: true
  end
end
