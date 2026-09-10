class CreateStrategies < ActiveRecord::Migration[8.0]
  def change
    create_table :strategies do |t|
      t.references :user,    null: false, foreign_key: true
      t.string :name,        null: false
      t.text   :description
      t.string :market
      t.timestamps
    end
    add_index :strategies, [:user_id, :name], unique: true
  end
end
