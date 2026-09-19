module Community
  class LeaderboardsController < ApplicationController
    def index
      # Carga solo los usuarios que tengan al menos 1 operación y procesa las estadísticas vía Ruby
      @users = User.includes(:trades).where.not(trades: { id: nil }).to_a
      
      @users.each do |user|
        stats = Trading::CalculateStatistics.new(user.trades).call
        user.define_singleton_method(:total_pnl) { stats[:total_pnl] }
        user.define_singleton_method(:win_rate) { stats[:win_rate] }
      end

      # Orden global por P&L
      @users.sort_by! { |u| -u.total_pnl }
      
      @top_traders = @users.take(10)
      @top_winners = @users.sort_by { |u| -(u.win_rate || 0) }.take(10)
    end
  end
end