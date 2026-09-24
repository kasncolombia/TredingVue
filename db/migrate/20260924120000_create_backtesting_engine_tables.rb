class CreateBacktestingEngineTables < ActiveRecord::Migration[8.1]
  def change
    # 1. Add missing fields to backtest_sessions
    change_table :backtest_sessions do |t|
      t.string :symbol
      t.datetime :replay_cursor
      t.string :timeframe, default: "M1"
      t.integer :speed, default: 1
      t.string :state, default: "paused"
      t.decimal :balance_inicial, precision: 12, scale: 2, default: 100000.0
      t.decimal :balance_actual, precision: 12, scale: 2, default: 100000.0
      t.json :config, default: {}
    end

    # 2. HistoricalBar1m
    create_table :historical_bar1ms do |t|
      t.string :symbol, null: false
      t.datetime :timestamp_utc, null: false
      t.decimal :open, precision: 10, scale: 5, null: false
      t.decimal :high, precision: 10, scale: 5, null: false
      t.decimal :low, precision: 10, scale: 5, null: false
      t.decimal :close, precision: 10, scale: 5, null: false
      t.integer :volume, default: 0
      t.timestamps
    end
    add_index :historical_bar1ms, [:symbol, :timestamp_utc], unique: true

    # 3. InstrumentSpec
    create_table :instrument_specs do |t|
      t.string :symbol, null: false
      t.decimal :tick_size, precision: 10, scale: 5, default: 0.25
      t.decimal :tick_value, precision: 10, scale: 5, default: 5.0
      t.decimal :commission, precision: 10, scale: 5, default: 2.05
      t.timestamps
    end
    add_index :instrument_specs, :symbol, unique: true

    # 4. BacktestOrder
    create_table :backtest_orders do |t|
      t.references :backtest_session, null: false, foreign_key: true
      t.string :symbol
      t.string :order_type
      t.string :direction
      t.decimal :quantity, precision: 10, scale: 5
      t.decimal :price, precision: 12, scale: 5
      t.decimal :stop_price, precision: 12, scale: 5
      t.string :status, default: "pending"
      t.string :idempotency_key
      t.timestamps
    end
    add_index :backtest_orders, :idempotency_key, unique: true

    # 5. BacktestPosition
    create_table :backtest_positions do |t|
      t.references :backtest_session, null: false, foreign_key: true
      t.string :symbol
      t.string :direction
      t.decimal :quantity, precision: 10, scale: 5
      t.decimal :average_price, precision: 12, scale: 5
      t.decimal :unrealized_pnl, precision: 12, scale: 2, default: 0.0
      t.timestamps
    end

    # 6. BacktestTrade
    create_table :backtest_trades do |t|
      t.references :backtest_session, null: false, foreign_key: true
      t.string :symbol
      t.string :direction
      t.decimal :quantity, precision: 10, scale: 5
      t.decimal :entry_price, precision: 12, scale: 5
      t.decimal :exit_price, precision: 12, scale: 5
      t.decimal :pnl, precision: 12, scale: 2, default: 0.0
      t.string :idempotency_key
      t.timestamps
    end
    add_index :backtest_trades, :idempotency_key, unique: true
  end
end
