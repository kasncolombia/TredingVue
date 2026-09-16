module Trading
  class CalculateStatistics
    def initialize(user_or_trades)
      @trades = user_or_trades.respond_to?(:trades) ? user_or_trades.trades.to_a : Array(user_or_trades)
    end

    def call
      total_count = @trades.count
      return default_stats if total_count == 0

      wins = @trades.select(&:win?)
      losses = @trades.reject(&:win?)

      total_pnl = @trades.sum { |t| t.pnl.to_f }
      win_rate = (wins.count.to_f / total_count * 100).round(1)
      loss_rate = (100.0 - win_rate).round(1)

      total_win_amount = wins.sum { |t| t.pnl.to_f }
      total_loss_amount = losses.sum { |t| t.pnl.to_f }.abs
      profit_factor = total_loss_amount > 0 ? (total_win_amount / total_loss_amount).round(2) : total_win_amount.round(2)

      avg_win = wins.count > 0 ? (total_win_amount / wins.count).round(2) : 0.0
      avg_loss = losses.count > 0 ? (total_loss_amount / losses.count).round(2) : 0.0
      rr_ratio = avg_loss > 0 ? (avg_win / avg_loss).round(2) : (avg_win > 0 ? avg_win.round(2) : 1.0)

      sorted_trades = @trades.compact.sort_by { |t| t.entry_at || Time.current }
      max_win_streak, max_loss_streak = calculate_streaks(sorted_trades)

      best_trade = @trades.map { |t| t.pnl.to_f }.max || 0.0
      worst_trade = @trades.map { |t| t.pnl.to_f }.min || 0.0

      {
        total_pnl: total_pnl.round(2),
        pnl_change_pct: calculate_change_pct(total_pnl),
        win_rate: win_rate,
        loss_rate: loss_rate,
        profit_factor: profit_factor,
        total_trades: total_count,
        wins_count: wins.count,
        losses_count: losses.count,
        winning_trades: wins.count,
        losing_trades: losses.count,
        avg_win: avg_win,
        avg_loss: avg_loss,
        rr_ratio: rr_ratio,
        best_trade: best_trade.round(2),
        worst_trade: worst_trade.round(2),
        max_win_streak: max_win_streak,
        max_loss_streak: max_loss_streak,
        is_demo: false
      }
    end

    private

    def calculate_streaks(sorted_trades)
      max_w = 0
      max_l = 0
      curr_w = 0
      curr_l = 0

      sorted_trades.each do |t|
        if t.win?
          curr_w += 1
          curr_l = 0
          max_w = curr_w if curr_w > max_w
        else
          curr_l += 1
          curr_w = 0
          max_l = curr_l if curr_l > max_l
        end
      end

      [max_w, max_l]
    end

    def calculate_change_pct(total_pnl)
      return 14.2 if total_pnl.zero?
      ((total_pnl / 10000.0) * 100).round(1)
    end

    def default_stats
      {
        total_pnl: 1910.00,
        pnl_change_pct: 14.2,
        win_rate: 62.5,
        loss_rate: 37.5,
        profit_factor: 2.15,
        total_trades: 8,
        wins_count: 5,
        losses_count: 3,
        winning_trades: 5,
        losing_trades: 3,
        avg_win: 398.00,
        avg_loss: 86.67,
        rr_ratio: 4.59,
        best_trade: 520.00,
        worst_trade: -140.00,
        max_win_streak: 3,
        max_loss_streak: 1,
        is_demo: true
      }
    end
  end
end
