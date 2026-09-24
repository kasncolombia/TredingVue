module Backtesting
  class CandleAggregator
    # Soporta agregación desde M1 hacia M5, M15, M30, H1, H4, D1
    TIMEFRAME_MINUTES = {
      "M1"  => 1,
      "M5"  => 5,
      "M15" => 15,
      "M30" => 30,
      "H1"  => 60,
      "H4"  => 240,
      "D1"  => 1440
    }.freeze

    def self.aggregate(bars_m1, target_timeframe)
      minutes = TIMEFRAME_MINUTES[target_timeframe] || 1
      return bars_m1.map { |b| format_bar(b) } if minutes == 1

      aggregated = []
      current_candle = nil
      current_interval_start = nil

      bars_m1.each do |bar|
        # Calcular a qué intervalo pertenece el bar basándose en el epoch
        interval_start = align_time(bar.timestamp_utc, minutes)

        if current_interval_start.nil? || current_interval_start != interval_start
          # Se cierra la vela anterior y se empuja al array
          aggregated << current_candle if current_candle

          # Abrir nueva vela
          current_interval_start = interval_start
          current_candle = {
            time: interval_start.to_i,
            open: bar.open.to_f,
            high: bar.high.to_f,
            low: bar.low.to_f,
            close: bar.close.to_f,
            volume: bar.volume.to_f
          }
        else
          # Actualizando la vela actual (incluyendo velas parciales)
          current_candle[:high] = [current_candle[:high], bar.high.to_f].max
          current_candle[:low] = [current_candle[:low], bar.low.to_f].min
          current_candle[:close] = bar.close.to_f # El close de la vela parcial es el último bar visto
          current_candle[:volume] += bar.volume.to_f
        end
      end

      # Añadir la última vela (que naturalmente será parcial si el cursor no ha cerrado el rango)
      aggregated << current_candle if current_candle

      aggregated
    end

    private

    def self.align_time(time, minutes)
      # Retorna el inicio del intervalo en el que cae "time".
      # Eg. si time es 10:37 y minutes es 60, retorna 10:00
      seconds = minutes * 60
      Time.at((time.to_f / seconds).floor * seconds).utc
    end
    
    def self.format_bar(bar)
      {
        time: bar.timestamp_utc.to_i,
        open: bar.open.to_f,
        high: bar.high.to_f,
        low: bar.low.to_f,
        close: bar.close.to_f,
        volume: bar.volume.to_f
      }
    end
  end
end
