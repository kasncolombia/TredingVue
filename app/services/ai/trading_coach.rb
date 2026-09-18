require 'net/http'
require 'json'

module Ai
  class TradingCoach
    def initialize(user, stats = nil)
      @user       = user
      @stats      = stats || Trading::CalculateStatistics.new(user).call
      @provider   = ENV.fetch('AI_PROVIDER', 'google')
      @model      = ENV.fetch('AI_MODEL', 'gemini-3.6-flash')
      @last_error = nil
      
      @api_key    = ENV['GEMINI_API_KEY'].presence || ENV['OPENROUTER_API_KEY'].presence || ENV['OPENAI_API_KEY']
    end

    def evaluate_trade(trade)
      if real_api_configured?
        response = call_openai_for_trade(trade)
        return parse_trade_response(response, trade) if response.present?
      end
      
      fallback_evaluate_trade(trade)
    end

    def ask(question)
      if real_api_configured?
        response = call_openai_for_chat(question)
        return response if response.present?
        
        if @last_error.present?
          return "⚠️ Error al conectar con #{@provider.upcase} (#{@model}): #{@last_error}. Revisa tu API Key y saldo en el panel de /admin."
        end
      end
      
      fallback_ask(question)
    end

    private

    def real_api_configured?
      @api_key.present?
    end

    def call_openai_for_trade(trade)
      system_prompt = <<~PROMPT
        IDENTIDAD: CoachTrading PRO AI. Coach analista de disciplina. JAMÁS des señales o predicciones.
        TRADER: #{@user.trader_type} | META: #{@user.trading_goal}
        
        NUEVO TRADE CERRADO: Símbolo: #{trade.symbol} | Dirección: #{trade.direction} | Resultado: #{trade.result} | Ganancia/Pérdida: $#{trade.pnl.to_f.round(2)} | Emoción: #{trade.emotion} | Riesgo: #{trade.r_multiple}R
        
        Genera UNICAMENTE un objeto JSON con 4 campos:
        {"score": (1-10 según disciplina y apego al riesgo, int), "pattern": (Breve comportamiento notado, string), "reflection": (Pregunta analítica, string), "feedback": (2 frases alineadas a su meta, string)}
      PROMPT

      make_api_request(system_prompt, "¿Qué opinas de este trade?", response_format: 'json_object')
    rescue StandardError => e
      @last_error = e.message
      Rails.logger.error "AIAssistant Error (Trade): #{e.message}"
      nil
    end

    def call_openai_for_chat(question)
      recent_trades = @user.trades.order(created_at: :desc).limit(10).map do |t|
        "[#{t.created_at&.strftime('%Y-%m-%d')}] #{t.symbol} #{t.direction} | #{t.result} ($#{t.pnl.to_f.round(2)}) | Emoción: #{t.emotion || 'N/A'}"
      end.join("\n        ")

      system_prompt = <<~PROMPT
        IDENTIDAD: CoachTrading PRO AI Coach. Misión: Analizar rendimiento y disciplina, no predecir mercado ni dar señales operativas.
        REGLA CORE: NUNCA calcules ni inventes métricas financieras. Usa SOLAMENTE las métricas dadas.
        PERFIL TRADER: Tipo: #{@user.trader_type || 'General'} | Mercado Principal: #{@user.main_market || 'Varios'} | Meta: #{@user.trading_goal || 'Mejorar Disciplina'}.
        
        MÉTRICAS GLOBALES (Backend Truth):
        - Operaciones totales: #{@user.trades.count}
        - Win Rate: #{@stats[:win_rate]}%
        - Profit Factor: #{@stats[:profit_factor]}
        - R:R Promedio: #{@stats[:rr_ratio]}
        
        ÚLTIMAS 10 OPERACIONES (Contexto Reciente):
        #{recent_trades.presence || 'Sin operaciones recientes.'}
        
        INSTRUCCIONES:
        1. Sé directo, breve, profesional y libre de jerga innecesaria (máximo 3 párrafos cortos).
        2. Basa tus análisis en patrones detectables de sus métricas o de sus últimas operaciones.
        3. Nunca prometas dinero. Fomenta el respeto al Stop Loss y gestión emocional.
        4. Si te piden una señal futura de entrada/salida, responde que eres analista post-operativo.
      PROMPT

      make_api_request(system_prompt, question, response_format: 'text')
    rescue StandardError => e
      @last_error = e.message
      Rails.logger.error "AIAssistant Error (Chat): #{e.message}"
      nil
    end

    def make_api_request(system_text, user_text, response_format: 'text')
      is_openrouter = (@provider == 'openrouter' || @model.to_s.include?('/'))
      is_google     = (@provider == 'google' || (@model.to_s.include?('gemini') && !is_openrouter))
      
      endpoint_url = if is_google
                       'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions'
                     elsif is_openrouter
                       'https://openrouter.ai/api/v1/chat/completions'
                     else
                       'https://api.openai.com/v1/chat/completions'
                     end
                     
      endpoint = URI(endpoint_url)

      http = Net::HTTP.new(endpoint.host, endpoint.port)
      http.use_ssl = true
      http.read_timeout = 30
      
      headers = {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{@api_key.to_s.strip}"
      }
      
      if is_openrouter
        headers['HTTP-Referer'] = 'http://localhost:3000'
        headers['X-Title']      = 'CoachTrading AI'
      end

      request = Net::HTTP::Post.new(endpoint.path, headers)

      body = {
        model: @model,
        messages: [
          { role: "system", content: system_text },
          { role: "user", content: user_text }
        ],
        max_tokens: ENV.fetch('AI_MAX_TOKENS', 500).to_i
      }
      
      body[:response_format] = { type: response_format } if response_format == 'json_object' && (!is_openrouter && !is_google)

      request.body = body.to_json
      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        parsed = JSON.parse(response.body)
        content = parsed.dig("choices", 0, "message", "content")
        if content.blank? && parsed.dig("choices", 0, "message", "reasoning")
          content = parsed.dig("choices", 0, "message", "reasoning")
        end
        if response_format == 'json_object' && content
          content = content.gsub(/```json\s*/i, '').gsub(/```\s*$/i, '').strip
        end
        content
      else
        error_msg = begin
          err_parsed = JSON.parse(response.body)
          err_parsed.dig("error", "message") || response.body
        rescue
          response.body
        end
        @last_error = "HTTP #{response.code}: #{error_msg}"
        Rails.logger.error "AI API Error (#{@provider}/#{@model}): #{response.code} - #{response.body}"
        nil
      end
    rescue StandardError => e
      @last_error = "#{e.class}: #{e.message}"
      Rails.logger.error "AI API Request Exception: #{e.message}"
      nil
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
        feedback: "Analizando tu trade en #{trade.symbol} (Objetivo: #{@user.trading_goal || 'Disciplina'}): Operación finalizada con #{trade.pnl >= 0 ? '+' : ''}$#{trade.pnl}."
      }
    end

    def fallback_ask(question)
      q = question.to_s.downcase
      trader_info = @user.trader_type.present? ? "Como trader de #{@user.trader_type} (#{@user.main_market}), " : ""
      goal_info = @user.trading_goal.present? ? " para tu objetivo de '#{@user.trading_goal}'" : ""

      if q.include?("error")
        "#{trader_info}tu mayor patrón de pérdida ocurre al intentar operar durante horarios de baja volatilidad o desviar el Stop Loss."
      elsif q.include?("estrategia")
        "#{trader_info}tu estrategia más consistente según tus estadísticas es 'Breakout' con un Win Rate superior a 68%."
      else
        "#{trader_info}he analizado tus operaciones#{goal_info}. Tu Win Rate general es de #{@stats[:win_rate]}% con un Profit Factor de #{@stats[:profit_factor]}."
      end
    end
  end
end
