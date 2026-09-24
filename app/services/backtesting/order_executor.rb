module Backtesting
  class OrderExecutor
    def initialize(session)
      @session = session
      @portfolio = PortfolioEngine.new(session)
    end

    def process_tick!(current_bar)
      # Se invoca en cada tick (vela de 1 minuto cruzada en el replay).
      
      # 1. Ejecutar Stop Loss / Take Profit para posiciones abiertas
      evaluate_positions!(current_bar)

      # 2. Evaluar Órdenes Limit / Stop pendientes
      evaluate_pending_orders!(current_bar)
    end
    
    def place_market_order!(direction, quantity, stop_loss: nil, take_profit: nil)
      bar = MarketDataAdapter.new(@session).get_latest_bar
      return false unless bar
      
      # Market order entra al precio "close" de la vela actual
      execute_order!(
        order_type: "Market",
        direction: direction,
        price: bar.close,
        quantity: quantity,
        stop_loss: stop_loss,
        take_profit: take_profit
      )
    end

    private

    def evaluate_positions!(bar)
      positions = @session.backtest_positions
      return if positions.empty?

      # Para MVP asumimos 1 posición a la vez
      pos = positions.first
      
      # Obtener órdenes relacionadas (TP y SL vinculados a la sesión)
      # Buscamos órdenes tipo 'Bracket' que funjan como SL o TP
      sl_order = @session.backtest_orders.find_by(status: "pending", order_type: "StopLoss")
      tp_order = @session.backtest_orders.find_by(status: "pending", order_type: "TakeProfit")

      hit_sl = sl_order && crossed?(sl_order.stop_price, bar, pos.direction, "SL")
      hit_tp = tp_order && crossed?(tp_order.price, bar, pos.direction, "TP")

      if hit_sl && hit_tp
        # POLÍTICA CONSERVATIVA (Blueprint estricto):
        # Si la vela M1 engulló tanto el SL como el TP, estadísticamente es imposible
        # saber cuál se tocó primero. Para no inflar la curva de Equity, 
        # asumimos SIEMPRE que se tocó el SL primero.
        close_position!(pos, sl_order.stop_price, "Stop Loss (Conservative)")
        sl_order.update!(status: "filled")
        tp_order.update!(status: "canceled")
      elsif hit_sl
        close_position!(pos, sl_order.stop_price, "Stop Loss")
        sl_order.update!(status: "filled")
        tp_order&.update!(status: "canceled")
      elsif hit_tp
        close_position!(pos, tp_order.price, "Take Profit")
        tp_order.update!(status: "filled")
        sl_order&.update!(status: "canceled")
      end
    end

    def evaluate_pending_orders!(bar)
      # Evalua puramente las Limit o Stop de entrada
      pending = @session.backtest_orders.where(status: "pending").where.not(order_type: ["StopLoss", "TakeProfit"])
      
      pending.each do |order|
        if order.order_type == "Limit"
          if (order.direction == "Long" && bar.low <= order.price) || (order.direction == "Short" && bar.high >= order.price)
            execute_order!(
              order_type: "Limit",
              direction: order.direction,
              price: order.price,
              quantity: order.quantity
            )
            order.update!(status: "filled")
          end
        elsif order.order_type == "Stop"
          if (order.direction == "Long" && bar.high >= order.stop_price) || (order.direction == "Short" && bar.low <= order.stop_price)
            execute_order!(
              order_type: "Stop",
              direction: order.direction,
              price: order.stop_price,
              quantity: order.quantity
            )
            order.update!(status: "filled")
          end
        end
      end
    end

    def execute_order!(order_type:, direction:, price:, quantity:, stop_loss: nil, take_profit: nil)
      pos = @session.backtest_positions.first_or_initialize(symbol: @session.symbol)
      
      if pos.new_record?
        pos.direction = direction
        pos.quantity = quantity
        pos.average_price = price
        pos.save!
      else
        # Lógica de escala / promediado (omitida en MVP simplificado)
        # Se asume cierre si es inverso
        if pos.direction != direction
          close_position!(pos, price, "Market Reverse")
          return
        end
      end

      # Crear rackets side orders
      @session.backtest_orders.create!(status: "pending", order_type: "StopLoss", stop_price: stop_loss, direction: (direction=="Long" ? "Short" : "Long"), quantity: quantity) if stop_loss
      @session.backtest_orders.create!(status: "pending", order_type: "TakeProfit", price: take_profit, direction: (direction=="Long" ? "Short" : "Long"), quantity: quantity) if take_profit
    end

    def close_position!(position, current_price, reason)
      # Llamar al Portfolio Engine para registrar el Trade y updatear Balance
      @portfolio.register_trade!(position, current_price, (position.direction == "Long" ? "Short" : "Long"), position.quantity)
      
      # Destroy position
      position.destroy!
    end

    def crossed?(target_price, bar, pos_direction, type)
      if pos_direction == "Long"
        type == "SL" ? bar.low <= target_price : bar.high >= target_price
      else
        type == "SL" ? bar.high >= target_price : bar.low <= target_price
      end
    end
  end
end
