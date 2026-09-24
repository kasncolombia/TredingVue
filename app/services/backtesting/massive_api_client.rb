module Backtesting
  class MassiveApiClient
    require 'net/http'
    require 'json'
    require 'uri'

    API_BASE = "https://api.massive.com/v2"

    def initialize
      @api_key = ENV['MASSIVE_API_KEY']
      raise "MASSIVE_API_KEY no detectada en environment. Verifica tu .env" if @api_key.blank?
    end

    # Request aggregate bars (OHLCV)
    # multiplier: 1, timespan: 'minute', from: '2023-01-01', to: '2023-01-31'
    def aggs(ticker:, multiplier: 1, timespan: "minute", from:, to:)
      # Normalizar formato de fechas yyyy-mm-dd si se entregan objetos Time/Date
      from_str = from.is_a?(Time) || from.is_a?(Date) ? from.strftime("%Y-%m-%d") : from
      to_str = to.is_a?(Time) || to.is_a?(Date) ? to.strftime("%Y-%m-%d") : to

      url = "#{API_BASE}/aggs/ticker/#{CGI.escape(ticker.to_s.upcase)}/range/#{multiplier}/#{timespan}/#{from_str}/#{to_str}?apiKey=#{@api_key}&limit=50000"
      
      response = fetch_json(url)
      
      if response["status"] != "OK" && response["status"] != "DELAYED"
        Rails.logger.error "[MassiveAPI] Error en repuesta: #{response.inspect}"
      end
      
      response["results"] || []
    end

    private

    def fetch_json(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      JSON.parse(response.body)
    rescue => e
      Rails.logger.error "[MassiveAPI] Network error: #{e.message}"
      { "status" => "ERROR", "error" => e.message }
    end
  end
end
