module Community
  class TradeSharesController < ApplicationController
    before_action :authenticate_user!

    def index
      @trade_shares = TradeShare.where(privacy: "public").includes(:trade, :user).recent.limit(20)
    end

    def new
      @trade_share = current_user.trade_shares.build
      @trades = current_user.trades
    end

    def create
      @trade_share = current_user.trade_shares.build(trade_share_params)
      if @trade_share.save
        redirect_to community_trade_shares_path, notice: "Trade compartido"
      else
        @trade_shares = TradeShare.where(privacy: "public").recent
        render :index
      end
    end

    def update_privacy
      @trade_share = current_user.trade_shares.find(params[:id])
      @trade_share.update!(privacy: params[:privacy])
      redirect_to community_trade_shares_path, notice: "Privacidad actualizada"
    end

    private

    def trade_share_params
      params.require(:trade_share).permit(:trade_id, :title, :note, :privacy)
    end
  end
end