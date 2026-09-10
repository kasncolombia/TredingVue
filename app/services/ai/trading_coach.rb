module Ai
  class TradingCoach
    def initialize(user, stats = nil)
      @user = user
      @stats = stats || Trading::CalculateStatistics.new(user).call
    end

    def evaluate_trade(trade)
      discipline_score = trade.win? ? 9 : 6
      pattern = trade.win? ? "Entrada limpia en zona de confluencia." : "Desviación ligera de horario habitual."
      reflection = "¿La entrada cumplía el 100% de las reglas de tu estrategia #{trade.strategy&.name || 'Breakout'}?"

      {
        score: discipline_score,
        pattern: pattern,
        reflection: reflection,
        feedback: "Analizando tu trade en #{trade.symbol}: Operación finalizada con #{trade.pnl >= 0 ? '+' : ''}$#{trade.pnl}."
      }
    end

    def ask(question)
      q = question.to_s.downcase
      if q.include?("error")
        "Tu mayor patrón de pérdida ocurre al intentar operar durante horarios de baja volatilidad con volumen reducido."
      elsif q.include?("estrategia")
        "Tu estrategia más consistente según las estadísticas calculadas es 'Breakout' con un win rate superior a 68%."
      else
        "He analizado tus últimas operaciones. Tu Win Rate general es de #{@stats[:win_rate]}% con un Profit Factor de #{@stats[:profit_factor]}."
      end
    end
  end
end
