class CreateResources < ActiveRecord::Migration[8.1]
  def change
    create_table :resources do |t|
      t.string :title
      t.string :url
      t.string :category
      t.references :author, null: false, foreign_key: true
      t.text :description

      t.timestamps
    end
  end
end
