class AnalyticsController < ApplicationController
  def show
    @trades      = current_user.trades.recent
    @stats       = Trading::CalculateStatistics.new(@trades).call
    @equity_data = Trading::CalculateDrawdown.new(@trades).equity_curve

    # P&L por símbolo → array [{symbol:, pnl:}]
    @by_symbol = @trades.group_by(&:symbol).map do |sym, ts|
      { symbol: sym, pnl: ts.sum(&:pnl).round(2), count: ts.count }
    end.sort_by { |d| -d[:pnl].abs }.first(10)

    # Distribución por estrategia → array [{name:, count:}]
    @by_strategy = @trades.group_by(&:strategy_id).map do |sid, ts|
      strategy = ts.first.strategy
      { name: strategy&.name || "Sin estrategia", count: ts.count, pnl: ts.sum(&:pnl).round(2) }
    end

    # P&L por dirección
    @by_direction = {
      "LONG"  => win_rate_for(@trades.select { |t| t.direction == "LONG" }),
      "SHORT" => win_rate_for(@trades.select { |t| t.direction == "SHORT" })
    }

    # P&L por hora
    @by_hour = @trades.group_by { |t| t.entry_at&.hour }.transform_values { |ts| ts.sum(&:pnl).round(2) }
  end

  private

  def win_rate_for(ts)
    return 0 if ts.empty?
    ((ts.count { |t| t.result == "WIN" }.to_f / ts.count) * 100).round(1)
  end
end
