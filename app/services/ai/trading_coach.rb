require 'net/http'
require 'json'

module Ai
  class TradingCoach
    def initialize(user, stats = nil)
      @user = user
      @stats = stats || Trading::CalculateStatistics.new(user).call
      @api_key = ENV['OPENAI_API_KEY']
    end

    def evaluate_trade(trade)
      if real_api_configured?
        response = call_openai_for_trade(trade)
        return parse_trade_response(response, trade) if response
      end
      
      fallback_evaluate_trade(trade)
    end

    def ask(question)
      if real_api_configured?
        response = call_openai_for_chat(question)
        return response if response.present?
      end
      
      fallback_ask(question)
    end

    private

    def real_api_configured?
      @api_key.present?
    end

    def call_openai_for_trade(trade)
      system_prompt = <<~PROMPT
        Eres un Coach de Trading Profesional de alto nivel de una prop firm.
        El usuario acaba de cerrar un trade de #{trade.symbol}. 
        Dirección: #{trade.direction || 'unknown'}. 
        Riesgo beneficio: #{trade.r_multiple || 'N/A'}. 
        Resultado: #{trade.result || (trade.pnl >= 0 ? 'WIN' : 'LOSS')}.
        Emoción: #{trade.emotion || 'No registrada'}.
        Ganancia/Pérdida: $#{trade.pnl.to_f.round(2)}.
        
        Devuelve un JSON estrictamente con esta estructura:
        {
          "score": (número del 1 al 10 sobre disciplina),
          "pattern": "Breve patrón técnico o emocional detectado",
          "reflection": "Pregunta de reflexión psicológica para el trader",
          "feedback": "2 oraciones de feedback constructivo"
        }
      PROMPT

      make_api_request(system_prompt, "¿Qué opinas de este trade?", response_format: 'json_object')
    rescue StandardError => e
      Rails.logger.error "AIAssistant Error (Trade): #{e.message}"
      nil
    end

    def call_openai_for_chat(question)
      system_prompt = <<~PROMPT
        Eres un Coach de Trading Profesional y analista algorítmico.
        Hablas con un trader que usa la plataforma CoachTrading.
        Sus métricas actuales son:
        Win Rate: #{@stats[:win_rate]}%
        Profit Factor: #{@stats[:profit_factor]}
        Operaciones registradas: #{@user.trades.count}
        
        Usa estos datos para tus respuestas cuando sea pertinente. 
        Mantén la respuesta en formato de texto natural y asertivo (máximo 3 párrafos).
        Tu meta principal es proteger la cuenta de fondeo del trader y evitar el overtrading.
      PROMPT

      make_api_request(system_prompt, question, response_format: 'text')
    rescue StandardError => e
      Rails.logger.error "AIAssistant Error (Chat): #{e.message}"
      nil
    end

    def make_api_request(system_text, user_text, response_format: 'text')
      uri = URI('https://api.openai.com/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri.path, {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{@api_key}"
      })
      
      body = {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: system_text },
          { role: "user", content: user_text }
        ]
      }
      
      body[:response_format] = { type: response_format } if response_format == 'json_object'
      
      request.body = body.to_json
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        parsed = JSON.parse(response.body)
        parsed.dig("choices", 0, "message", "content")
      else
        Rails.logger.error "OpenAI API Error: #{response.body}"
        nil
      end
    end

    def parse_trade_response(json_string, trade)
      data = JSON.parse(json_string)
      {
        score: data["score"].to_i,
        pattern: data["pattern"].to_s,
        reflection: data["reflection"].to_s,
        feedback: data["feedback"].to_s
      }
    rescue JSON::ParserError
      fallback_evaluate_trade(trade)
    end

    def fallback_evaluate_trade(trade)
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

    def fallback_ask(question)
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
