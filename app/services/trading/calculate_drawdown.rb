module Trading
  class CalculateDrawdown
    def initialize(trades)
      @trades = trades.respond_to?(:order) ? trades.order(:entry_at) : trades.sort_by(&:entry_at)
    end

    def equity_curve
      cumulative = 0
      @trades.map do |t|
        cumulative += t.pnl.to_f
        { date: t.entry_at&.strftime("%Y-%m-%d") || "N/A", value: cumulative.round(2) }
      end
    end

    def max_drawdown
      curve  = equity_curve.map { |p| p[:value] }
      peak   = 0
      max_dd = 0
      curve.each do |val|
        peak   = val if val > peak
        dd     = peak > 0 ? ((peak - val) / peak * 100).round(2) : 0
        max_dd = dd if dd > max_dd
      end
      max_dd
    end
  end
end
