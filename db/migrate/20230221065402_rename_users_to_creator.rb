class RenameUsersToCreator < ActiveRecord::Migration[7.0]
  def change
    rename_table :users, :creator
  end
end
