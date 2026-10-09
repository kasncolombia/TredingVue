module Backtesting
  class MassiveImporter
    # Mapeo de Nomenclatura local vs Massive
    # Ej: En TradeTres podemos usar "NQ1!", pero Massive requiere "MNQ" o lo que sea.
    SYMBOL_MAP = {
      "AAPL" => "AAPL",
      "MSFT" => "MSFT",
      "NVDA" => "NVDA",
      "TSLA" => "TSLA",
      "AMZN" => "AMZN",
      "GOOGL" => "GOOGL",
      "META" => "META",
      "SPY" => "SPY",
      "QQQ" => "QQQ",
      "IWM" => "IWM"
    }

    class << self
      # Descarga y guarda velas M1 (1 minuto) para un símbolo y rango
      def import_historical_range(local_symbol, from_date, to_date)
        massive_ticker = SYMBOL_MAP[local_symbol.upcase] || local_symbol.upcase
        client = MassiveApiClient.new
        
        Rails.logger.info "[MassiveImporter] Importando #{massive_ticker} de #{from_date} a #{to_date}"
        
        results = client.aggs(
          ticker: massive_ticker,
          multiplier: 1,
          timespan: "minute",
          from: from_date,
          to: to_date
        )

        return 0 if results.empty?

        bars_to_insert = []
        
        results.each do |bar|
          # La API de Massive/Polygon usualmente devuelve 't' en timestamps milisegundos
          timestamp = Time.at(bar['t'] / 1000.0).utc

          bars_to_insert << {
            symbol: local_symbol.upcase,
            timestamp_utc: timestamp,
            open: bar['o'],
            high: bar['h'],
            low: bar['l'],
            close: bar['c'],
            volume: bar['v'],
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # Upsert para no duplicar datos si ejecutas el script más de una vez
        bars_to_insert.each_slice(5000) do |batch|
          HistoricalBar1m.upsert_all(
            batch, 
            unique_by: [:symbol, :timestamp_utc]
          )
        end

        Rails.logger.info "[MassiveImporter] ¡Se cargaron #{bars_to_insert.size} velas exitosamente en M1!"
        bars_to_insert.size
      end
    end
  end
end
