class AddStorageNameToImages < ActiveRecord::Migration[7.0]
  def change
    add_column :images, :storage_name, :string
  end
end
