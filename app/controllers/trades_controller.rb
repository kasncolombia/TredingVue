class TradesController < ApplicationController
  before_action :set_trade, only: [:show, :edit, :update, :destroy]

  def index
    @trades = current_user.trades.recent
    @trades = @trades.by_symbol(params[:symbol])               if params[:symbol].present?
    @trades = @trades.where(direction: params[:direction])     if params[:direction].present?
    @trades = @trades.where(result: params[:result])           if params[:result].present?
    @trades = @trades.where(strategy_id: params[:strategy_id]) if params[:strategy_id].present?
    @strategies = current_user.strategies
    @stats      = Trading::CalculateStatistics.new(@trades).call
  end

  def show
  end

  def new
    @trade      = current_user.trades.build
    @strategies = current_user.strategies
  end

  def create
    @trade = current_user.trades.build(trade_params)
    @trade.entry_at ||= Time.current
    @trade.portfolio_mode ||= "real_account"

    if @trade.save
      Trading::AlertManager.new(current_user).evaluate_trade(@trade)
      redirect_to trades_path, notice: "Operación registrada exitosamente."
    else
      @strategies = current_user.strategies
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @strategies = current_user.strategies
  end

  def update
    if @trade.update(trade_params)
      redirect_to @trade, notice: "Operación actualizada."
    else
      @strategies = current_user.strategies
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trade.destroy
    redirect_to trades_path, notice: "Operación eliminada."
  end

  def import
    # Vista de importación CSV
  end

  def import_csv
    file = params[:csv_file]
    if file.present?
      begin
        csv_text = file.read.force_encoding("UTF-8")
        
        count = Trading::CsvImporter.new(current_user, csv_text).call
        
        # Disparar alertas globales de overtrading o drawdowns masivos después del import.
        Trading::AlertManager.new(current_user).evaluate_all if count > 0
        
        redirect_to trades_path, notice: "#{count} operaciones importadas exitosamente desde CSV."
      rescue => e
        redirect_to import_trades_path, alert: "Error procesando el CSV multi-broker: #{e.message}"
      end
    else
      redirect_to import_trades_path, alert: "Selecciona un archivo CSV válido."
    end
  end

  private

  def set_trade
    @trade = current_user.trades.find(params[:id])
  end

  def trade_params
    params.require(:trade).permit(
      :symbol, :market, :direction, :timeframe, :setup, :portfolio_mode, :prop_firm_account_id,
      :entry_at, :exit_at, :entry_price, :exit_price,
      :stop_loss, :take_profit, :position_size, :capital_used,
      :risk_amount, :commission, :pnl, :pnl_percent, :r_multiple,
      :result, :emotion, :entry_reason, :exit_reason, :notes,
      :screenshot_url, :tags, :strategy_id
    )
  end
end
