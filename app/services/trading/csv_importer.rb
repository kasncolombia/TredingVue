require 'csv'

module Trading
  class CsvImporter
    def initialize(user, file_content)
      @user = user
      @file_content = file_content
      @imported_count = 0
    end

    def call
      # Eliminamos el BOM si existe y parseamos el CSV
      @file_content.sub!("\xEF\xBB\xBF", '') 
      
      CSV.parse(@file_content, headers: true, quote_char: '"', col_sep: ',').each do |row|
        build_trade_from_row(row.to_h)
      end
      
      @imported_count
    end

    private

    def build_trade_from_row(row_hash)
      # Normalizamos keys (simples downcase y strip)
      row = row_hash.transform_keys { |k| k.to_s.downcase.strip }
      
      trade_attributes = if row.key?('instrument') && (row.key?('profit') || row.key?('p&l'))
                           parse_tradovate(row)
                         elsif (row.key?('market') || row.key?('instrument')) && row.key?('net pnl')
                           parse_ninjatrader(row)
                         else 
                           parse_standard(row)
                         end
                         
      return unless trade_attributes

      trade = @user.trades.build(trade_attributes)
      
      # Si el resultado no venía forzado, lo asignamos automáticamente según el pnl
      unless trade.result.present?
        trade.result = trade.pnl >= 0 ? "WIN" : "LOSS"
      end
      
      if trade.save
        @imported_count += 1
      end
    rescue StandardError => e
      Rails.logger.error "Error en CsvImporter de fila: #{e.message} - Fila: #{row}"
    end

    def parse_standard(row)
      return nil unless row["symbol"] || row["market"]
      {
        symbol:      row["symbol"] || row["market"] || "UNKNOWN",
        direction:   (row["direction"] || row["side"] || "LONG").upcase,
        entry_price: sanitize_number(row["entry_price"] || row["entry"]),
        exit_price:  sanitize_number(row["exit_price"]  || row["exit"]),
        pnl:         sanitize_number(row["pnl"] || "0"),
        entry_at:    parse_date(row["entry_at"] || row["date"] || row["time"])
      }
    end

    def parse_ninjatrader(row)
      pnl = sanitize_number(row["net pnl"])
      {
        symbol:      row["instrument"] || row["market"] || "UNKNOWN",
        direction:   row["action"].to_s.upcase.include?("BUY") ? "LONG" : "SHORT",
        entry_price: sanitize_number(row["entry price"] || row["price"]),
        exit_price:  sanitize_number(row["exit price"]),
        pnl:         pnl,
        entry_at:    parse_date(row["time"] || row["entry time"])
      }
    end

    def parse_tradovate(row)
      pnl = sanitize_number(row["profit"]) || sanitize_number(row["p&l"])
      {
        symbol:      row["symbol"] || row["instrument"] || "UNKNOWN",
        direction:   row["b/s"].to_s.upcase == "B" ? "LONG" : "SHORT",
        entry_price: sanitize_number(row["entry price"] || row["price"]),
        exit_price:  sanitize_number(row["exit price"]),
        pnl:         pnl,
        entry_at:    parse_date(row["entry time"] || row["timestamp"])
      }
    end

    def sanitize_number(val)
      return nil if val.blank?
      # Limpiamos caracteres de moneda para castear puro flotante (Soporta $1,200.50 y -15.0)
      val.to_s.gsub(/[^\d\.\-]/, '').to_f
    end

    def parse_date(val)
      return Time.current if val.blank?
      begin
        Time.zone.parse(val.to_s)
      rescue
        Time.current
      end
    end
  end
end
