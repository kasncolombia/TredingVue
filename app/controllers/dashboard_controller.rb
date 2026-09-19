class DashboardController < ApplicationController
  def index
    @current_mode = params[:mode].presence || 'real_account'
    
    unless Trade.portfolio_modes.keys.include?(@current_mode)
      @current_mode = 'real_account'
    end

    all_trades     = current_user.trades.where(portfolio_mode: @current_mode).recent
    @recent_trades = all_trades.limit(5)
    @stats         = Trading::CalculateStatistics.new(all_trades).call
    @equity_data   = Trading::CalculateDrawdown.new(all_trades).equity_curve
    @pnl_by_day    = Trading::CalculateDailyPnl.new(all_trades).call

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
