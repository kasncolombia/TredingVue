module Backtesting
  class ReplayEngine
    attr_reader :session, :errors

    def initialize(session)
      @session = session
      @errors = []
    end

    def start!
      update_state("playing")
    end

    def pause!
      update_state("paused")
    end

    def next_tick!
      # El "tick" base del Replay Engine ES 1 MINUTO (M1).
      # Esto asegura comportamiento conservador al simular cruces de precio.
      advance_cursor(1.minute)
    end

    def step_back!
      reverse_cursor(1.minute)
    end
    
    def change_speed!(new_speed)
      @session.update!(speed: new_speed.to_i)
    end

    def change_timeframe!(new_timeframe)
      # Simplemente se actualiza el metadata visual, 
      # EL CURSOR REAL NO CAMBIA (es agnóstico del timeframe)
      @session.update!(timeframe: new_timeframe)
    end
    
    def restart!
      # Regresa el cursor al inicio del rango de fechas si estuviera configurado,
      # O retrocede 500 velas M1 (solo para fallback asumiendo lógica por defecto)
      reverse_cursor(500.minutes)
      update_state("paused")
    end
    
    def fetch_window(limit: 500)
      # Obtiene la ventana actual desde el adapter M1 y la pasa por el aggregator
      adapter = MarketDataAdapter.new(@session)
      bars_m1 = adapter.fetch_bars(limit: limit)
      
      # Si timeframe es M1 esto será rápido, de lo contrario agrupa
      CandleAggregator.aggregate(bars_m1, @session.timeframe || "M1")
    end

    private

    def advance_cursor(duration)
      return false unless @session.replay_cursor
      
      # Busca la siguiente vela disponible en la BD para saltar a ella
      # Esto maneja los fines de semana cerrados y gaps limpiamente
      next_bar = HistoricalBar1m.where(symbol: @session.symbol)
                                .where("timestamp_utc > ?", @session.replay_cursor)
                                .order(timestamp_utc: :asc)
                                .first

      if next_bar
        @session.update!(replay_cursor: next_bar.timestamp_utc)
        
        # POLÍTICA DE EJECUCIÓN (Fase 4): Evaluar órdenes en CADA TICK M1
        OrderExecutor.new(@session).process_tick!(next_bar)
      else
        # Llegamos al final del Market Data
        pause!
        @errors << "Market Data end reached."
        false
      end
    end

    def reverse_cursor(duration)
      return false unless @session.replay_cursor
      
      prev_bar = HistoricalBar1m.where(symbol: @session.symbol)
                                .where("timestamp_utc < ?", @session.replay_cursor)
                                .order(timestamp_utc: :desc)
                                .first
      if prev_bar
        @session.update!(replay_cursor: prev_bar.timestamp_utc)
      else
        @errors << "Market Data start reached."
        false
      end
    end

    def update_state(new_state)
      @session.update!(state: new_state)
    end
  end
end
