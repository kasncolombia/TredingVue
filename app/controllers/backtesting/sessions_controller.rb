module Backtesting
  class SessionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_session, except: [:new, :create]

    def new
      @session = BacktestSession.new
    end

    def create
      @session = BacktestSession.new(session_params)
      @session.user = current_user
      @session.state = "created" # pending setup
      
      # We don't set replay_cursor_at yet until data is loaded
      @session.replay_cursor_at = @session.start_date.try(:beginning_of_day)

      # IMPORTANTE: Para evitar Rate Limits en la Demostración, bloqueamos la desarga en vivo a Massive API
      # y forzamos el uso de la caché local existente en Postgres. En producción este paso
      # dependería de los Data Lakes nocturnos de S3.
      if @session.save
        @session.update!(data_status: "lista")
        redirect_to backtesting_root_path, notice: "Sesión creada. Iniciando desde Base de Datos Local..."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      # Vista de resultados (al finalizar la sesión)
    end

    def replay
      # Renderiza la UI base con lightweight-charts y controles
    end

    def play
      engine.start!
      render json: { state: @session.state }
    end

    def pause
      engine.pause!
      render json: { state: @session.state }
    end

    def next
      # Avanza 1 velita base
      if engine.next_tick!
        render json: { success: true, cursor: @session.replay_cursor_at }
      else
        render json: { success: false, error: engine.errors.last }
      end
    end

    def step_back
      engine.step_back!
      render json: { success: true, cursor: @session.replay_cursor_at }
    end

    def change_timeframe
      engine.change_timeframe!(params[:timeframe])
      render json: { success: true, timeframe: @session.timeframe }
    end

    def record_trade
      trade_params = params.require(:trade).permit(:direction, :entry_price, :exit_price, :pnl, :entry_at, :exit_at, :quantity, :notes)
      trade = current_user.trades.new(
        backtest_session_id: @session.id,
        symbol: @session.symbol,
        market: @session.symbol, # fallback
        direction: trade_params[:direction].upcase,
        entry_price: trade_params[:entry_price],
        exit_price: trade_params[:exit_price],
        pnl: trade_params[:pnl],
        entry_at: Time.at(trade_params[:entry_at].to_i).utc,
        exit_at: Time.at(trade_params[:exit_at].to_i).utc,
        result: trade_params[:pnl].to_f >= 0 ? "WIN" : "LOSS",
        notes: "Backtest. #{trade_params[:notes]}"
      )
      
      if trade.save
        @session.update(balance_actual: (@session.balance_actual || @session.balance_inicial) + trade_params[:pnl].to_f)
        render json: { success: true, trade_id: trade.id, balance: @session.balance_actual }
      else
        render json: { success: false, errors: trade.errors.full_messages }
      end
    end

    def historical_data
      bars_m1 = HistoricalBar1m.where(symbol: @session.symbol)
                               .order(timestamp_utc: :asc)
                               .limit(3000) # Fetch all available bars up to limit
      
      aggregated = CandleAggregator.aggregate(bars_m1, @session.timeframe || "M1")
      
      # Determine active cursor index
      cursor_index = 0
      if @session.replay_cursor_at
        idx = aggregated.index { |b| b[:time] >= @session.replay_cursor_at.to_i }
        cursor_index = idx || 0
      end

      render json: { 
        bars: aggregated, 
        cursor_index: cursor_index 
      }
    end

    def rename
      if @session.update(name: params[:name])
        redirect_to backtesting_root_path, notice: "Sesión renombrada correctamente."
      else
        redirect_to backtesting_root_path, alert: "No se pudo renombrar."
      end
    end

    def duplicate
      new_session = @session.dup
      new_session.name = "#{new_session.name} (Copia)"
      new_session.balance_actual = new_session.balance_inicial
      new_session.state = "created"
      new_session.status = "en_curso"
      new_session.data_status = "pendiente"
      new_session.archived_at = nil
      new_session.last_opened_at = nil
      new_session.symbol = params[:symbol] if params[:symbol].present?

      if new_session.save
        Backtesting::ImportBarsJob.perform_later(new_session.id)
        redirect_to backtesting_root_path, notice: "Sesión duplicada. Descargando datos..."
      else
        redirect_to backtesting_root_path, alert: "Error al duplicar la sesión."
      end
    end

    def archive
      @session.update(archived_at: Time.current)
      redirect_to backtesting_root_path, notice: "Sesión archivada."
    end

    def destroy
      @session.destroy
      redirect_to backtesting_root_path, notice: "Sesión eliminada."
    end

    def retry_import
      @session.update(data_status: "importando")
      require_dependency Rails.root.join("app/jobs/backtesting/import_bars_job.rb").to_s
      Backtesting::ImportBarsJob.perform_later(@session.id)
      redirect_to backtesting_root_path, notice: "Reintentando descarga de datos..."
    end

    private

    def set_session
      @session = current_user.try(:backtest_sessions)&.find(params[:id]) || BacktestSession.find(params[:id])
    end

    def engine
      @engine ||= ReplayEngine.new(@session)
    end

    def session_params
      params.require(:backtest_session).permit(:name, :symbol, :balance_inicial, :timeframe, :speed, :start_date, :end_date)
    end
  end
end
