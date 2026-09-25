class Users::ProfileController < ApplicationController
  def show
    @user = current_user
    @stats = Trading::CalculateStatistics.new(current_user.trades).call
    @recent_trades = current_user.trades.recent.limit(5)
    @total_trades = current_user.trades.count
    @win_trades = current_user.trades.where(result: "WIN").count
    @loss_trades = current_user.trades.where(result: "LOSS").count
  end

  def update
    was_completed = current_user.onboarding_completed
    if current_user.update(profile_params)
      if !was_completed && current_user.onboarding_completed
        current_user.notifications.create!(
          title: "Perfil de Trading Adaptado 🎉",
          message: "Configuración guardada para mercado '#{current_user.main_market.to_s.upcase}' y nivel '#{current_user.trader_type.to_s.titleize}'. ¡Todo listo para operar con disciplina!",
          category: "system"
        )
      end
      redirect_to request.referer || dashboard_path, notice: "Perfil actualizado correctamente."
    else
      redirect_to request.referer || profile_path, alert: "No se pudo actualizar la configuración."
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :name, :email, :preferred_currency, :initial_capital,
      :onboarding_completed, :trader_type, :main_market, :trading_goal, :timezone
    )
  end
end