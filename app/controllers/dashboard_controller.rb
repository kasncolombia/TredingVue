class DashboardController < ApplicationController
  def index
    @trades       = current_user.trades.recent
    @recent_trades = @trades.limit(5)
    @stats        = Trading::CalculateStatistics.new(@trades).call
    @equity_data  = Trading::CalculateDrawdown.new(@trades).equity_curve
  end
end
