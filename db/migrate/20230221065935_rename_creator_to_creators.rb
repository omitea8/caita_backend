class RenameCreatorToCreators < ActiveRecord::Migration[7.0]
  def change
    rename_table :creator, :creators
  end
end
