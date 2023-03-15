class RemoveTitleFromImages < ActiveRecord::Migration[7.0]
  def change
    remove_column :images, :title, :string
  end
end
