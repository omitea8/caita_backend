class RemoveStorageUrlFromImages < ActiveRecord::Migration[7.0]
  def change
    remove_column :images, :storage_url, :string
  end
end
