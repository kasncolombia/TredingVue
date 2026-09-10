module Trading
  class CalculateStatistics
    def initialize(user_or_trades)
      @trades = user_or_trades.respond_to?(:trades) ? user_or_trades.trades : user_or_trades
    end

    def call
      total_count = @trades.count
      return default_stats if total_count == 0

      wins = @trades.select(&:win?)
      losses = @trades.reject(&:win?)

      total_pnl = @trades.sum(&:pnl)
      win_rate = (wins.count.to_f / total_count * 100).round(1)
      loss_rate = (100.0 - win_rate).round(1)

      total_win_amount = wins.sum(&:pnl)
      total_loss_amount = losses.sum(&:pnl).abs
      profit_factor = total_loss_amount > 0 ? (total_win_amount / total_loss_amount).round(2) : total_win_amount.round(2)

      avg_win = wins.count > 0 ? (total_win_amount / wins.count).round(2) : 0
      avg_loss = losses.count > 0 ? (total_loss_amount / losses.count).round(2) : 0

      {
        total_pnl: total_pnl.round(2),
        win_rate: win_rate,
        loss_rate: loss_rate,
        profit_factor: profit_factor,
        total_trades: total_count,
        wins_count: wins.count,
        losses_count: losses.count,
        avg_win: avg_win,
        avg_loss: avg_loss
      }
    end

    private

    def default_stats
      { total_pnl: 0, win_rate: 0, loss_rate: 0, profit_factor: 0, total_trades: 0, wins_count: 0, losses_count: 0, avg_win: 0, avg_loss: 0 }
    end
  end
end
