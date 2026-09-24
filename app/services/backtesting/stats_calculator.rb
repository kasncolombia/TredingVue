module Backtesting
  class StatsCalculator
    def initialize(session)
      @session = session
      @trades = session.backtest_trades.order(created_at: :asc)
    end

    def calculate
      return empty_stats if @trades.empty?

      winners = @trades.select { |t| t.pnl > 0 }
      losers  = @trades.select { |t| t.pnl <= 0 }

      gross_profit = winners.sum(&:pnl)
      gross_loss   = losers.sum(&:pnl).abs
      
      {
        total_trades: @trades.size,
        win_rate: (winners.size.to_f / @trades.size) * 100,
        profit_factor: gross_loss.zero? ? gross_profit : (gross_profit / gross_loss),
        net_pnl: @trades.sum(&:pnl),
        avg_winner: winners.any? ? (gross_profit / winners.size) : 0,
        avg_loser: losers.any? ? (gross_loss / losers.size) : 0,
        max_drawdown: calculate_max_drawdown,
        long_metrics: calculate_direction_metrics("Long"),
        short_metrics: calculate_direction_metrics("Short")
      }
    end

    private

    def calculate_max_drawdown
      peak = @session.balance_inicial || 100_000.0
      current_balance = peak
      max_dd = 0.0

      @trades.each do |trade|
        current_balance += trade.pnl
        peak = current_balance if current_balance > peak
        drawdown = peak - current_balance
        max_dd = drawdown if drawdown > max_dd
      end

      max_dd
    end

    def calculate_direction_metrics(direction)
      dir_trades = @trades.select { |t| t.direction == direction }
      return empty_dir_stats if dir_trades.empty?

      dir_winners = dir_trades.select { |t| t.pnl > 0 }
      gross_profit = dir_winners.sum(&:pnl)
      gross_loss = dir_trades.select { |t| t.pnl <= 0 }.sum(&:pnl).abs

      {
        count: dir_trades.size,
        win_rate: (dir_winners.size.to_f / dir_trades.size) * 100,
        profit_factor: gross_loss.zero? ? gross_profit : (gross_profit / gross_loss)
      }
    end

    def empty_stats
      {
        total_trades: 0, win_rate: 0, profit_factor: 0, net_pnl: 0,
        avg_winner: 0, avg_loser: 0, max_drawdown: 0,
        long_metrics: empty_dir_stats, short_metrics: empty_dir_stats
      }
    end

    def empty_dir_stats
      { count: 0, win_rate: 0, profit_factor: 0 }
    end
  end
end
