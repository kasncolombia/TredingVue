class DashboardController < ApplicationController
  def index
    @current_mode = params[:mode].presence || 'real_account'
    
    unless Trade.portfolio_modes.keys.include?(@current_mode)
      @current_mode = 'real_account'
    end

    all_trades     = current_user.trades.where(portfolio_mode: @current_mode).recent
    @recent_trades = all_trades.limit(6)
    
    @stats         = Trading::CalculateStatistics.new(all_trades).call
    
    # Agregar Expectancy
    win_pct = @stats[:win_rate].to_f / 100.0
    loss_pct = @stats[:loss_rate].to_f / 100.0
    @stats[:expectancy] = (win_pct * @stats[:avg_win].to_f) - (loss_pct * @stats[:avg_loss].to_f.abs)

    @equity_data   = Trading::CalculateDrawdown.new(all_trades).equity_curve
    @pnl_by_day    = Trading::CalculateDailyPnl.new(all_trades).call
    
    # Mapa exacto de P&L por fecha para el calendario del dashboard
    @daily_pnl_map = all_trades.select { |t| t.entry_at.present? }
                               .group_by { |t| t.entry_at.to_date }
                               .transform_values { |ts| ts.sum(&:pnl).to_f }

    @roi_data = calculate_roi_progression(all_trades)

    # Datos adicionales para el Nuevo Dashboard V2
    calculate_advanced_metrics(all_trades)

    @ai_diagnosis  = generate_ai_diagnosis(@stats)

    if current_user.notifications.empty?
      current_user.notifications.create!(
        title: "¡Bienvenido a CoachTrading PRO! 🚀",
        message: "Tu diario de trading inteligente está activo. Registra tu primera operación o prueba el AI Coach.",
        category: "system"
      )
    end
  end

  private

  def calculate_roi_progression(trades)
    grouped = trades.reject { |t| t.entry_at.nil? }.group_by { |t| t.entry_at.to_date }.sort
    return fallback_roi_data if grouped.empty?

    labels, ingresos, gastos, roi = [], [], [], []
    cum_ingresos = 0.0
    cum_gastos = 0.0
    
    month_names = %w[nil ene feb mar abr may jun jul ago sep oct nov dic]

    grouped.each do |date, day_trades|
      label = "#{date.day.to_s.rjust(2, '0')} #{month_names[date.month]}"
      
      day_ingreso = day_trades.select { |t| t.pnl.to_f > 0 }.sum(&:pnl).to_f
      day_gasto = day_trades.select { |t| t.pnl.to_f < 0 }.sum(&:pnl).to_f.abs
      
      cum_ingresos += day_ingreso
      cum_gastos += day_gasto
      
      labels << label
      ingresos << cum_ingresos.round
      gastos << cum_gastos.round
      roi << (cum_ingresos - cum_gastos).round
    end

    { labels: labels, ingresos: ingresos, gastos: gastos, roi: roi }
  end

  def fallback_roi_data
    {
      labels: ["23 feb", "02 mar", "12 mar", "25 mar", "14 abr", "08 may", "12 jun", "26 jun", "29 jun", "01 jul", "06 jul", "10 jul"],
      ingresos: [200, 250, 250, 250, 280, 2300, 3900, 4100, 4050, 4200, 4150, 5400],
      gastos:   [200, 380, 420, 650, 1050, 900, 820, 1100, 1450, 1550, 1600, 1600],
      roi:  [200, 130, 100, -50, -500, 1400, 3100, 3500, 3300, 3400, 3280, 4300]
    }
  end

  def calculate_advanced_metrics(trades)
    # Trade Durations Scatter
    @trade_durations = trades.select { |t| t.entry_at && t.exit_at }.map do |t|
      duration_mins = ((t.exit_at - t.entry_at) / 60.0).round(1)
      { duration: duration_mins, pnl: t.pnl.to_f, result: t.win? ? 'win' : 'loss' }
    end

    # P&L by Hour
    @pnl_by_hour = trades.group_by { |t| t.entry_at&.strftime("%H:00") || "00:00" }
                         .transform_values { |ts| { trades: ts.count, pnl: ts.sum(&:pnl).to_f } }
                         .sort.to_h

    # P&L by Ticker
    @pnl_by_ticker = trades.group_by(&:symbol)
                           .transform_values { |ts| { trades: ts.count, pnl: ts.sum(&:pnl).to_f } }
                           .sort_by { |_, v| -v[:trades] }.to_h

    # Current Streak
    sorted = trades.sort_by { |t| t.entry_at || Time.current }
    @current_streak = 0
    @current_streak_type = nil
    
    sorted.reverse_each do |t|
      type = t.win? ? :win : :loss
      @current_streak_type ||= type
      break if type != @current_streak_type
      @current_streak += 1
    end

    # Annual Calendar (Months of current year)
    curr_year = Time.current.year
    @annual_stats = Array.new(12, 0)
    year_trades = trades.select { |t| t.entry_at&.year == curr_year }
    year_trades.each do |t|
      @annual_stats[t.entry_at.month - 1] += t.pnl.to_f
    end
    @annual_total = year_trades.sum(&:pnl).to_f
    @annual_trades_count = year_trades.count
    
    # Drawdown (simulación simple del máximo drawdown temporal)
    @max_drawdown_value = 0
    peak = 0
    current_eq = 0
    sorted.each do |t|
      current_eq += t.pnl.to_f
      peak = current_eq if current_eq > peak
      dd = current_eq - peak
      @max_drawdown_value = dd if dd < @max_drawdown_value
    end
  end

  def generate_ai_diagnosis(stats)
    if stats[:is_demo]
      "Estás manteniendo un ratio de recompensa superior a 1.8. Tu mayor ventaja ocurre en trades con la estrategia Breakout."
    elsif stats[:win_rate] >= 60.0
      "¡Excelente consistencia! Tu Win Rate del #{stats[:win_rate]}% y Profit Factor de #{stats[:profit_factor]} muestran una ejecución muy sólida."
    elsif stats[:win_rate] >= 40.0
      "Rendimiento moderado (Win Rate: #{stats[:win_rate]}%). Asegúrate de recortar las pérdidas rápido para mantener el Profit Factor por encima de 1.5."
    else
      "Atención: Tu Win Rate actual es del #{stats[:win_rate]}%. Te recomendamos revisar tu gestión de riesgo y limitar el apalancamiento."
    end
  end
end
