module Trading
  class CalculateDrawdown
    def initialize(trades)
      @trades = trades.respond_to?(:order) ? trades.order(:entry_at).to_a : Array(trades).compact.sort_by { |t| t.entry_at || Time.current }
    end

    def equity_curve
      return demo_equity_curve if @trades.empty?

      cumulative = 0.0
      @trades.map.with_index do |t, idx|
        cumulative += t.pnl.to_f
        {
          trade: "T#{idx + 1} (#{t.symbol})",
          date: t.entry_at&.strftime("%d/%m") || "T#{idx + 1}",
          pnl: t.pnl.to_f.round(2),
          value: cumulative.round(2)
        }
      end
    end

    def max_drawdown
      curve  = equity_curve.map { |p| p[:value] }
      peak   = 0.0
      max_dd = 0.0
      curve.each do |val|
        peak   = val if val > peak
        dd     = peak > 0 ? ((peak - val) / peak * 100).round(2) : 0.0
        max_dd = dd if dd > max_dd
      end
      max_dd
    end

    private

    def demo_equity_curve
      [
        { trade: "T1 (NQ1!)", date: "01/09", pnl: 350.0, value: 350.0 },
        { trade: "T2 (EURUSD)", date: "02/09", pnl: 180.0, value: 530.0 },
        { trade: "T3 (BTC)", date: "03/09", pnl: -120.0, value: 410.0 },
        { trade: "T4 (NQ1!)", date: "04/09", pnl: 450.0, value: 860.0 },
        { trade: "T5 (AAPL)", date: "05/09", pnl: 290.0, value: 1150.0 },
        { trade: "T6 (XAUUSD)", date: "08/09", pnl: -140.0, value: 1010.0 },
        { trade: "T7 (NQ1!)", date: "09/09", pnl: 520.0, value: 1530.0 },
        { trade: "T8 (NVDA)", date: "10/09", pnl: 380.0, value: 1910.0 }
      ]
    end
  end
end
