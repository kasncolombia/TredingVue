module Trading
  class ChartDataGenerator
    attr_reader :trade

    def initialize(trade)
      @trade = trade
    end

    def call
      entry_p = trade.entry_price.to_f
      entry_p = 100.0 if entry_p <= 0

      exit_p = trade.exit_price.to_f
      exit_p = entry_p if exit_p <= 0

      sl_p = trade.stop_loss.presence&.to_f
      tp_p = trade.take_profit.presence&.to_f

      entry_time = trade.entry_at || Time.current
      exit_time = trade.exit_at || (entry_time + 30.minutes)
      duration_sec = (exit_time - entry_time).to_i
      duration_sec = 1800 if duration_sec <= 0

      # Generate 35 candles: 10 before entry, 20 during trade, 5 after exit
      total_bars = 35
      bar_interval = [ (duration_sec / 20.0).round, 60 ].max

      start_time = (entry_time - (10 * bar_interval)).to_i

      candles = []
      volume_data = []

      current_p = entry_p * (trade.direction == "LONG" ? 0.992 : 1.008)
      seed = (trade.id || 12345) + (trade.symbol.to_s.sum)

      total_bars.times do |i|
        timestamp = start_time + (i * bar_interval)
        open_p = current_p

        # Target price interpolation
        if i < 10
          target = entry_p
        elsif i <= 30
          progress = (i - 10) / 20.0
          target = entry_p + (exit_p - entry_p) * progress
        else
          target = exit_p
        end

        delta = (target - open_p) * 0.4
        noise = (Math.sin(seed + i) * 0.003 + Math.cos(seed * 0.5 + i) * 0.002) * entry_p
        close_p = open_p + delta + noise

        # Exact entry & exit values at key bars
        close_p = entry_p if i == 10
        close_p = exit_p if i == 30

        high_p = [open_p, close_p].max + (open_p * 0.002) + (Math.sin(i * 1.5).abs * open_p * 0.0015)
        low_p  = [open_p, close_p].min - (open_p * 0.002) - (Math.cos(i * 1.5).abs * open_p * 0.0015)

        current_p = close_p

        candles << {
          time: timestamp,
          open: open_p.round(2),
          high: high_p.round(2),
          low: low_p.round(2),
          close: close_p.round(2)
        }

        vol_amount = (500 + Math.sin(i * 2).abs * 2500 + (i == 10 || i == 30 ? 1500 : 0)).round
        vol_color = close_p >= open_p ? "rgba(16, 185, 129, 0.45)" : "rgba(244, 63, 94, 0.45)"

        volume_data << {
          time: timestamp,
          value: vol_amount,
          color: vol_color
        }
      end

      entry_candle = candles[10]
      exit_candle  = candles[30]

      markers = []

      is_long = trade.direction == "LONG"
      entry_label = "#{is_long ? 'BUY' : 'SELL'} $#{sprintf('%.2f', entry_p)}"
      markers << {
        time: entry_candle[:time],
        position: is_long ? "belowBar" : "aboveBar",
        color: is_long ? "#10B981" : "#F43F5E",
        shape: is_long ? "arrowUp" : "arrowDown",
        text: entry_label
      }

      pnl_text = trade.pnl.to_f >= 0 ? "+$#{sprintf('%.2f', trade.pnl)}" : "-$#{sprintf('%.2f', trade.pnl.abs)}"
      exit_label = "EXIT $#{sprintf('%.2f', exit_p)} (#{pnl_text})"
      markers << {
        time: exit_candle[:time],
        position: trade.pnl.to_f >= 0 ? "aboveBar" : "belowBar",
        color: trade.pnl.to_f >= 0 ? "#10B981" : "#F43F5E",
        shape: "square",
        text: exit_label
      }

      price_lines = [
        {
          price: entry_p,
          color: "#3B82F6",
          title: "ENTRY ($#{sprintf('%.2f', entry_p)})",
          lineStyle: 0
        }
      ]

      if sl_p && sl_p > 0
        price_lines << {
          price: sl_p,
          color: "#F43F5E",
          title: "SL ($#{sprintf('%.2f', sl_p)})",
          lineStyle: 2
        }
      end

      if tp_p && tp_p > 0
        price_lines << {
          price: tp_p,
          color: "#10B981",
          title: "TP ($#{sprintf('%.2f', tp_p)})",
          lineStyle: 2
        }
      end

      {
        symbol: trade.symbol,
        direction: trade.direction,
        pnl: trade.pnl.to_f,
        result: trade.result || (trade.pnl.to_f >= 0 ? "WIN" : "LOSS"),
        candles: candles,
        volume: volume_data,
        markers: markers,
        price_lines: price_lines
      }
    end
  end
end
