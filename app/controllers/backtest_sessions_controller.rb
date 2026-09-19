class BacktestSessionsController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.backtest_sessions.build(session_params)
    if @session.save
      # Redirigir al diario pre-filtrando por el modo correcto de esta sesión
      redirect_to new_trade_path(
        session_id: @session.id,
        "trade[portfolio_mode]": @session.portfolio_mode_value
      ), notice: "✅ Sesión '#{@session.name}' creada. ¡Ahora registra tus operaciones!"
    else
      redirect_to pro_tools_path, alert: "Error: #{@session.errors.full_messages.to_sentence}"
    end
  end

  def show
    @session = current_user.backtest_sessions.find(params[:id])
    # Buscamos los trades etiquetados con este modo
    @trades = current_user.trades.where(portfolio_mode: @session.portfolio_mode_value).recent
    @stats  = @trades.any? ? Trading::CalculateStatistics.new(@trades).call : nil
  end

  def destroy
    session_rec = current_user.backtest_sessions.find(params[:id])
    session_rec.destroy
    redirect_to pro_tools_path, notice: "Sesión eliminada."
  end

  private

  def session_params
    params.require(:backtest_session).permit(
      :name, :session_type, :account_size, :asset, :strategy_id,
      :start_date, :end_date, :notes,
      :max_daily_loss_pct, :max_drawdown_pct, :profit_target_pct, :prop_company
    )
  end
end
