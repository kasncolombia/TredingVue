module Community
  class ProfilesController < ApplicationController
    before_action :set_user, only: [:show]

    def show
      @trades = @user.trades.recent.limit(10)
      @trade_shares = @user.trade_shares.where(privacy: "public").recent.limit(10)
      @stats = {
        total_trades: @user.trades.count,
        win_rate: @user.win_rate.round(1),
        total_pnl: @user.total_pnl,
        win_trades: @user.trades.where(result: "WIN").count,
        loss_trades: @user.trades.where(result: "LOSS").count
      }
      @followers_count = rand(5..500)
      @following_count = rand(10..200)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end