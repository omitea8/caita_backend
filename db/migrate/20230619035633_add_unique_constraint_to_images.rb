class AddUniqueConstraintToImages < ActiveRecord::Migration[7.0]
  def change
    add_index :images, :storage_name, unique: true
  end
end
