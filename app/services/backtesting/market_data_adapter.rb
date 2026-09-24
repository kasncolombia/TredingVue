module Backtesting
  class MarketDataAdapter
    # Regla estricta del blueprint: El cursor es la verdad absoluta.
    # NUNCA debemos retornar datos que estén más en el futuro que replay_cursor.
    
    def initialize(session)
      @session = session
    end

    def fetch_bars(limit: 1000)
      return [] unless @session.replay_cursor.present?
      
      # Anti-lookahead fundamental: Se filtra todo lo que sea > replay_cursor
      # Se asume que HistoricalBar1m tiene index en symbol y timestamp_utc
      HistoricalBar1m.where(symbol: @session.symbol)
                     .where("timestamp_utc <= ?", @session.replay_cursor)
                     .order(timestamp_utc: :desc)
                     .limit(limit)
                     .reverse # Revertir para que el orden final sea cronológico
    end
    
    def get_latest_bar
      # Devuelve exactamente la vela M1 actual donde está el cursor
      HistoricalBar1m.where(symbol: @session.symbol)
                     .where("timestamp_utc <= ?", @session.replay_cursor)
                     .order(timestamp_utc: :desc)
                     .first
    end
  end
end
