class CreateBacktestSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :backtest_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,          null: false
      t.string  :session_type,  null: false, default: "backtest"  # backtest | prop_firm
      t.decimal :account_size,  precision: 12, scale: 2, default: 100000
      t.string  :asset
      t.integer :strategy_id
      t.date    :start_date
      t.date    :end_date
      t.text    :notes
      # Prop Firm specific
      t.decimal :max_daily_loss_pct,  precision: 5, scale: 2, default: 2.0
      t.decimal :max_drawdown_pct,    precision: 5, scale: 2, default: 8.0
      t.decimal :profit_target_pct,   precision: 5, scale: 2, default: 8.0
      t.string  :prop_company         # Apex, Topstep, etc.
      t.string  :status,              default: "active"  # active | completed | failed

      t.timestamps
    end
  end
end
