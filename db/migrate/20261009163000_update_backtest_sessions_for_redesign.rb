class UpdateBacktestSessionsForRedesign < ActiveRecord::Migration[8.1]
  def change
    add_column :backtest_sessions, :data_status, :string, default: "pendiente"
    add_column :backtest_sessions, :last_opened_at, :datetime
    add_column :backtest_sessions, :archived_at, :datetime
    
    # Alias / rename of replay_cursor to replay_cursor_at to match conventions 
    # (Checking if column exists first is good practice)
    rename_column :backtest_sessions, :replay_cursor, :replay_cursor_at if column_exists?(:backtest_sessions, :replay_cursor)
  end
end
