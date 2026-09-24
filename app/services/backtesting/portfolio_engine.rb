module Backtesting
  class PortfolioEngine
    def initialize(session)
      @session = session
      @spec = InstrumentSpec.find_by(symbol: session.symbol)
    end

    def calculate_pnl(entry_price, exit_price, direction, quantity)
      return 0.0 unless @spec
      
      # Formula: (Exit - Entry) / tick_size * tick_value * qty - comisiones
      price_diff = if direction == "Long"
                     exit_price - entry_price
                   else
                     entry_price - exit_price
                   end
                   
      ticks = price_diff / @spec.tick_size
      gross_pnl = ticks * @spec.tick_value * quantity
      net_pnl = gross_pnl - (@spec.commission * quantity * 2) # * 2 for round trip (entry + exit)
      
      net_pnl
    end

    def register_trade!(position, exit_price, direction_close, quantity)
      pnl = calculate_pnl(position.average_price, exit_price, position.direction, quantity)
      
      # Generar trade guardando idempotency key
      trade = @session.backtest_trades.create!(
        symbol: position.symbol,
        direction: position.direction,
        quantity: quantity,
        entry_price: position.average_price,
        exit_price: exit_price,
        pnl: pnl,
        idempotency_key: "TRD-#{@session.id}-#{Time.now.to_f}"
      )
      
      # Actualizar Portfolio Total
      new_balance = @session.balance_actual + pnl
      @session.update!(balance_actual: new_balance)

      trade
    end
  end
end
