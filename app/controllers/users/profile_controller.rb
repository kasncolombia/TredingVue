class Users::ProfileController < ApplicationController
  def show
    @user = current_user
    @stats = Trading::CalculateStatistics.new(current_user.trades).call
    @recent_trades = current_user.trades.recent.limit(5)
    @total_trades = current_user.trades.count
    @win_trades = current_user.trades.where(result: "WIN").count
    @loss_trades = current_user.trades.where(result: "LOSS").count
  end
end