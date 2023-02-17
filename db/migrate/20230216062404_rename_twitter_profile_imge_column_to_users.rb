class RenameTwitterProfileImgeColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :twitter_profile_imge, :twitter_profile_image
  end
end
