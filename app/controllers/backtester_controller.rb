class BacktesterController < ApplicationController
  before_action :authenticate_user!

  def show
    # En el futuro, aquí inicializaremos variables para el gráfico OHLC histórico y replay.
    # Por ahora, extraemos los trades registrados como "backtest" en la base de datos
    # para que el usuario pueda ver sus resultados simulados si quiso guardarlos manually.
    
    @backtest_trades = current_user.trades.where(portfolio_mode: :backtest).recent
    
    if @backtest_trades.any?
      @stats = Trading::CalculateStatistics.new(@backtest_trades).call
    else
      @stats = nil
    end
  end
end
