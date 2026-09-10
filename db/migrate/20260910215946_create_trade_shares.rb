class CreateTradeShares < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_shares do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trade, null: false, foreign_key: true
      t.string :privacy
      t.text :title
      t.text :note

      t.timestamps
    end
  end
end
