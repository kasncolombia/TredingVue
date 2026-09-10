module Community
  class WidgetsController < ApplicationController
    def embed
      @stats = {
        total_trades: Trade.count,
        active_traders: User.count,
        win_rate: Trade.where(result: "WIN").count.to_f / [Trade.count, 1].max * 100
      }
      render layout: false
    end
  end
end