require "test_helper"

class MarketDataAdapterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(name: "Test", email: "test#{rand(1000)}@test.com", password: "password")
    # Base setup for DB
    @symbol = "NQ1!"
    @cursor_time = Time.utc(2026, 9, 24, 10, 30, 0)
    
    # 1. Create a backtest session with a fixed cursor
    @session = BacktestSession.create!(
      name: "Anti-Lookahead Test",
      symbol: @symbol,
      replay_cursor: @cursor_time,
      user: @user
    )

    # 2. Insert market data: Past, Present, and FUTURE
    HistoricalBar1m.create!(symbol: @symbol, timestamp_utc: @cursor_time - 2.minutes, open: 100, high: 105, low: 95, close: 102, volume: 10)
    HistoricalBar1m.create!(symbol: @symbol, timestamp_utc: @cursor_time - 1.minute,  open: 102, high: 110, low: 100, close: 105, volume: 15)
    HistoricalBar1m.create!(symbol: @symbol, timestamp_utc: @cursor_time,             open: 105, high: 115, low: 102, close: 112, volume: 20)
    
    # FUTURE DATA (Should NEVER be returned!)
    HistoricalBar1m.create!(symbol: @symbol, timestamp_utc: @cursor_time + 1.minute,  open: 112, high: 120, low: 110, close: 118, volume: 30)
    HistoricalBar1m.create!(symbol: @symbol, timestamp_utc: @cursor_time + 2.minutes, open: 118, high: 130, low: 115, close: 125, volume: 40)
  end

  test "fetch_bars strictly enforces anti-lookahead by filtering future data" do
    adapter = Backtesting::MarketDataAdapter.new(@session)
    bars = adapter.fetch_bars(limit: 50)
    
    # We should only get the 3 bars that are <= cursor_time
    assert_equal 3, bars.length
    
    # Verify the most recent bar returned is EXACTLY the cursor time
    # (after reversal inside fetch_bars, the last one is the latest)
    latest_bar = bars.last
    assert_equal @cursor_time, latest_bar.timestamp_utc
    
    # Verify absolutely no bar belongs to the future
    bars.each do |bar|
      assert bar.timestamp_utc <= @cursor_time, "SECURITY BREACH: Server leaked future bar at #{bar.timestamp_utc}"
    end
  end
end
