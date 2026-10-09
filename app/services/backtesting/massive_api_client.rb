module Backtesting
  class MassiveApiClient
    require 'net/http'
    require 'json'
    require 'uri'

    class ApiError < StandardError; end
    class RateLimited < ApiError; end
    class NoDataError < ApiError; end

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

      url = "#{API_BASE}/aggs/ticker/#{CGI.escape(ticker.to_s.upcase)}/range/#{multiplier}/#{timespan}/#{from_str}/#{to_str}?limit=50000"
      
      all_results = []
      
      loop do
        response = fetch_json(url)
        all_results.concat(response["results"] || [])
        
        url = response["next_url"]
        break unless url
        url = "#{url}&limit=50000" unless url.include?('limit=')
      end
      
      if all_results.empty?
        raise NoDataError, "No hay datos disponibles para #{ticker} del #{from_str} al #{to_str}"
      end
      
      all_results
    end

    private

    def fetch_json(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      
      response = http.request(request)
      
      if response.code == "429"
        raise RateLimited, "429 Too Many Requests de Massive API"
      elsif !response.is_a?(Net::HTTPSuccess)
        raise ApiError, "Error HTTP #{response.code}: #{response.message}"
      end
      
      data = JSON.parse(response.body)
      if data["status"] != "OK" && data["status"] != "DELAYED"
        Rails.logger.error "[MassiveAPI] Error status: #{data.inspect}"
      end
      data
    rescue JSON::ParserError
      raise ApiError, "Respuesta JSON inválida de la API"
    rescue RateLimited => e
      raise e
    rescue StandardError => e
      raise ApiError, "Error de red/API: #{e.message}"
    end
  end
end
