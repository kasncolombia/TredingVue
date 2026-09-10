module Community
  class LeaderboardsController < ApplicationController
    def index
      @users = User.includes(:trades).select("users.*, COUNT(trades.id) as trades_count, COALESCE(SUM(trades.pnl), 0) as total_pnl, COALESCE(AVG(CASE WHEN trades.result = 'WIN' THEN 1.0 ELSE 0.0 END), 0) as win_rate")
        .joins("LEFT JOIN trades ON trades.user_id = users.id")
        .group("users.id")
        .order("total_pnl DESC, trades_count DESC")
        .limit(50)

      @top_traders = @users.limit(10)
      @top_winners = User.left_joins(:trades)
        .select("users.*, COUNT(trades.id) as total_trades, SUM(CASE WHEN trades.result = 'WIN' THEN 1 ELSE 0 END) as wins")
        .group("users.id")
        .order("win_rate DESC")
        .limit(10)
    end
  end
end