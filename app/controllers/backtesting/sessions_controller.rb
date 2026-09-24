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
      @session.state = "paused"
      
      # For MVP, logic to start cursor on the earliest bar available for symbol
      earliest_bar = HistoricalBar1m.where(symbol: @session.symbol).order(timestamp_utc: :asc).first
      @session.replay_cursor = earliest_bar&.timestamp_utc || Time.current.utc

      if @session.save
        redirect_to replay_backtesting_session_path(@session), notice: "Sesión creada. ¡Listo para backtesting!"
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
        render json: { success: true, cursor: @session.replay_cursor }
      else
        render json: { success: false, error: engine.errors.last }
      end
    end

    def step_back
      engine.step_back!
      render json: { success: true, cursor: @session.replay_cursor }
    end

    def change_timeframe
      engine.change_timeframe!(params[:timeframe])
      render json: { success: true, timeframe: @session.timeframe }
    end

    def historical_data
      bars_m1 = HistoricalBar1m.where(symbol: @session.symbol)
                               .order(timestamp_utc: :asc)
                               .limit(3000) # Fetch all available bars up to limit
      
      aggregated = CandleAggregator.aggregate(bars_m1, @session.timeframe || "M1")
      
      # Determine active cursor index
      cursor_index = 0
      if @session.replay_cursor
        idx = aggregated.index { |b| b[:time] >= @session.replay_cursor.to_i }
        cursor_index = idx || 0
      end

      render json: { 
        bars: aggregated, 
        cursor_index: cursor_index 
      }
    end

    private

    def set_session
      @session = current_user.try(:backtest_sessions)&.find(params[:id]) || BacktestSession.find(params[:id])
    end

    def engine
      @engine ||= ReplayEngine.new(@session)
    end

    def session_params
      params.require(:backtest_session).permit(:name, :symbol, :balance_inicial, :timeframe, :speed)
    end
  end
end
