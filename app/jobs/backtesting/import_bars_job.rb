module Backtesting
  class ImportBarsJob < ActiveJob::Base
    queue_as :default

    rescue_from(Backtesting::MassiveApiClient::RateLimited) do |exception|
      # Massive API plan gratuito tiene limitación estricta de 5 req / min = 12 seg por req. 
      # Si chocamos con el rate limit, reintentaremos en 15 seg.
      retry_job wait: 15.seconds
    end

    def perform(session_id)
      session = BacktestSession.find(session_id)
      
      # Verificamos si ya hay un coverage completed que envuelva estas fechas
      # Una forma simple para MVP: buscamos si las barras ya existen.
      # Una forma estructurada es con HistoricalDataCoverage
      coverage = HistoricalDataCoverage.find_or_create_by!(
        symbol: session.symbol,
        from_date: session.start_date,
        to_date: session.end_date
      )

      # Si está completo o falló, igual intentar? Si falló deberíamos reintentar. 
      return if coverage.status == "completed"

      coverage.update!(status: "importing")
      
      begin
        count = Backtesting::MassiveImporter.import_historical_range(
          session.symbol,
          session.start_date,
          session.end_date
        )

        coverage.update!(status: "completed", error_message: nil)

        # La sesión ahora está "paused" o "ready" y puede usarse.
        session.update!(status: "active", state: "paused")

      rescue Backtesting::MassiveApiClient::RateLimited => e
        # Raise to trigger the rescue_from above
        raise e

      rescue StandardError => e
        coverage.update!(status: "failed", error_message: e.message)
        session.update!(status: "failed", state: "failed", notes: "Fallo importación: #{e.message}")
      end
    end
  end
end
