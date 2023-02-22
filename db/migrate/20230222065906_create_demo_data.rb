class CreateDemoData < ActiveRecord::Migration[7.0]
  def change
    create_table :demo_data do |t|
      t.string :title
      t.text :caption
      t.string :image_url
      t.references :creator, null: false, foreign_key: true

      t.timestamps
    end
    add_index :demo_data, [:creator_id, :created_at]
  end
end
