module Trading
  class AlertManager
    def initialize(user)
      @user = user
    end

    def evaluate_trade(trade)
      check_overtrading
      check_drawdown
    end

    def evaluate_all
      check_overtrading
      check_drawdown
    end

    private

    def check_overtrading
      # Si el usuario ha hecho 5 o más trades hoy, disparamos alerta de overtrading
      trades_today = @user.trades.where("entry_at >= ?", Time.current.beginning_of_day).count
      if trades_today >= 5
        create_alert(
          "Riesgo de Overtrading ⚠️",
          "Has registrado #{trades_today} operaciones hoy. Operar en exceso es la causa número 1 de pérdidas en pruebas de fondeo. El AI Coach sugiere tomar una pausa.",
          "warning"
        )
      end
    end

    def check_drawdown
      # Verificamos si en conjunto el perfil de este usuario hoy o su acumulado global tiene alertas fuertes
      stats = Trading::CalculateStatistics.new(@user.trades).call
      pnl = stats[:total_pnl]
      
      # Regla 1: Drawdown acumulado supera el límite de impacto -$500
      if pnl.to_f < -500.0
        create_alert(
          "Drawdown Crítico Detectado 🚨",
          "Tu capital registra un bache superior a -$500. Recuerda proteger tu mente, revisar tu bitácora y no perseguir el mercado por venganza.",
          "danger"
        )
      end
    end

    def create_alert(title, message, category)
      # Para evitar SPAM masivo (ej: si importa un CSV con 100 trades hoy), 
      # solo enviamos la notificación si no hemos enviado una similar en las últimas 4 horas sin leer
      recent_duplicate = @user.notifications.where(title: title, read: false)
                                            .where("created_at > ?", 4.hours.ago)
                                            .exists?
                                            
      unless recent_duplicate
        @user.notifications.create!(
          title: title,
          message: message,
          category: category
        )
      end
    end
  end
end
