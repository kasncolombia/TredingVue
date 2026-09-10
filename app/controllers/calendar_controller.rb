class CalendarController < ApplicationController
  def show
    @current_month = begin
      params[:month] ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    start_date = @current_month.beginning_of_month.beginning_of_week(:monday)
    end_date   = @current_month.end_of_month.end_of_week(:monday)

    # Buscar operaciones del periodo visible en el calendario
    trades = current_user.trades.where(entry_at: start_date.beginning_of_day..end_date.end_of_day)
    @trades_by_date = trades.group_by { |t| t.entry_at.to_date }

    # Calcular estadísticas del mes seleccionado
    month_trades = current_user.trades.where(entry_at: @current_month.beginning_of_month.beginning_of_day..@current_month.end_of_month.end_of_day)
    @month_stats = {
      total_pnl:    month_trades.sum(:pnl),
      total_trades: month_trades.count,
      wins_count:   month_trades.select(&:win?).count,
      losses_count: month_trades.select(&:loss?).count
    }

    # Días activos y métricas de diario
    daily_pnls = month_trades.group_by { |t| t.entry_at.to_date }.transform_values { |ts| ts.sum(&:pnl) }
    @best_day  = daily_pnls.values.max || 0
    @worst_day = daily_pnls.values.min || 0
    @green_days = daily_pnls.values.count { |v| v > 0 }
    @red_days   = daily_pnls.values.count { |v| v < 0 }

    @calendar_days = (start_date..end_date).to_a
  end
end
