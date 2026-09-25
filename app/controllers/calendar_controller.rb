class CalendarController < ApplicationController
  def show
    @current_month = begin
      params[:month] ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    rescue ArgumentError
      Date.current.beginning_of_month
    end

    start_date = @current_month.beginning_of_month.beginning_of_week(:sunday)
    end_date   = @current_month.end_of_month.end_of_week(:saturday)

    # Solo generar datos de muestra si el usuario NO tiene ninguna operación creada en la base de datos
    ensure_sample_trades_for_month(@current_month) if current_user.trades.none?

    # Buscar operaciones del periodo visible en el calendario
    trades = current_user.trades.where(entry_at: start_date.beginning_of_day..end_date.end_of_day)
    @trades_by_date = trades.group_by { |t| t.entry_at.to_date }

    # Calcular estadísticas del mes seleccionado
    month_trades = current_user.trades.where(entry_at: @current_month.beginning_of_month.beginning_of_day..@current_month.end_of_month.end_of_day)
    
    total_pnl = month_trades.sum(:pnl)
    wins      = month_trades.select { |t| t.pnl.to_f > 0 }
    losses    = month_trades.select { |t| t.pnl.to_f < 0 }

    @month_stats = {
      total_pnl:    total_pnl,
      total_trades: month_trades.count,
      wins_count:   wins.count,
      losses_count: losses.count,
      win_rate:     month_trades.count > 0 ? (wins.count.to_f / month_trades.count * 100).round(1) : 0
    }

    # Días activos y métricas de diario
    daily_pnls = month_trades.group_by { |t| t.entry_at.to_date }.transform_values { |ts| ts.sum(&:pnl) }
    @best_day   = daily_pnls.values.max || 0
    @worst_day  = daily_pnls.values.min || 0
    @green_days = daily_pnls.values.count { |v| v > 0 }
    @red_days   = daily_pnls.values.count { |v| v < 0 }

    @calendar_days = (start_date..end_date).to_a
    @weeks = @calendar_days.each_slice(7).to_a
    
    # Calcular totales por semana (8va columna Bento Grid)
    @weekly_pnls = @weeks.map do |week_days|
      week_trades = trades.select { |t| week_days.include?(t.entry_at.to_date) }
      {
        pnl: week_trades.sum(&:pnl),
        count: week_trades.size,
        wins: week_trades.count { |t| t.pnl.to_f > 0 },
        losses: week_trades.count { |t| t.pnl.to_f < 0 }
      }
    end
  end

  private

  def ensure_sample_trades_for_month(month_date)
    return unless current_user

    # Lista de activos y setups habituales
    symbols    = ["NQ_F", "ES_F", "EURUSD", "BTCUSD", "AAPL", "NVDA", "GBPUSD"]
    directions = ["LONG", "SHORT"]

    # Generar operaciones realistas en días laborables del mes
    (month_date.beginning_of_month..[month_date.end_of_month, Date.current].min).each do |date|
      next if date.saturday? || date.sunday?
      # 75% probabilidad de operar este día
      next if rand > 0.75

      trades_today_count = rand(1..3)
      trades_today_count.times do |i|
        symbol    = symbols.sample
        direction = directions.sample
        is_win    = rand > 0.35 # 65% win rate
        pnl       = is_win ? rand(120.0..650.0).round(2) : -rand(80.0..320.0).round(2)
        entry_p   = rand(150.0..18000.0).round(2)
        exit_p    = is_win ? (entry_p + rand(5.0..50.0)).round(2) : (entry_p - rand(5.0..30.0)).round(2)

        current_user.trades.create!(
          symbol:       symbol,
          direction:    direction,
          entry_price:  entry_p,
          exit_price:   exit_p,
          pnl:          pnl,
          entry_at:     date.to_time + (9 + i * 2).hours + rand(0..45).minutes,
          exit_at:      date.to_time + (10 + i * 2).hours + rand(0..45).minutes,
          result:       is_win ? "WIN" : "LOSS",
          r_multiple:   is_win ? rand(1.5..3.8).round(2) : -1.0,
          emotion:      ["Calmo", "Focado", "Ansioso", "Disciplinado"].sample
        )
      end
    end
  end
end
