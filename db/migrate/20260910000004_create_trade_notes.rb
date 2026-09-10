class CreateTradeNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :trade_notes do |t|
      t.references :trade, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end
  end
end
