class AddBacktestSessionIdToTrades < ActiveRecord::Migration[8.1]
  def change
    add_column :trades, :backtest_session_id, :integer
    add_index :trades, :backtest_session_id
  end
end
