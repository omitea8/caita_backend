class AddColumnsToImages < ActiveRecord::Migration[7.0]
  def change
    add_column :images, :storage_url, :string
    add_column :images, :image_name, :string
    add_index :images, :image_name, unique: true
  end
end
