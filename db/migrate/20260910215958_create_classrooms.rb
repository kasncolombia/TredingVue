class CreateClassrooms < ActiveRecord::Migration[8.1]
  def change
    create_table :classrooms do |t|
      t.string :title
      t.text :description
      t.string :category
      t.references :author, null: false, foreign_key: true

      t.timestamps
    end
  end
end
