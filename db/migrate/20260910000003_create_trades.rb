class CreateTrades < ActiveRecord::Migration[8.0]
  def change
    create_table :trades do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :strategy, foreign_key: true
      t.string  :symbol,    null: false
      t.string  :market
      t.string  :direction, null: false   # LONG / SHORT
      t.string  :timeframe
      t.string  :setup
      t.datetime :entry_at
      t.datetime :exit_at
      t.decimal :entry_price,    precision: 20, scale: 8
      t.decimal :exit_price,     precision: 20, scale: 8
      t.decimal :stop_loss,      precision: 20, scale: 8
      t.decimal :take_profit,    precision: 20, scale: 8
      t.decimal :position_size,  precision: 20, scale: 8
      t.decimal :capital_used,   precision: 15, scale: 2
      t.decimal :risk_amount,    precision: 15, scale: 2
      t.decimal :commission,     precision: 10, scale: 4, default: 0
      t.decimal :pnl,            precision: 15, scale: 2, null: false
      t.decimal :pnl_percent,    precision: 8,  scale: 4
      t.decimal :r_multiple,     precision: 8,  scale: 2
      t.string  :result          # WIN / LOSS / BREAKEVEN
      t.string  :emotion
      t.text    :entry_reason
      t.text    :exit_reason
      t.text    :notes
      t.string  :screenshot_url
      t.string  :tags
      t.timestamps
    end
    add_index :trades, [:user_id, :entry_at]
    add_index :trades, [:user_id, :symbol]
    add_index :trades, [:user_id, :result]
  end
end
