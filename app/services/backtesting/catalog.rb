module Backtesting
  class Catalog
    ITEMS = [
      { symbol: "AAPL", name: "Apple", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "MSFT", name: "Microsoft", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "NVDA", name: "NVIDIA", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "TSLA", name: "Tesla", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "AMZN", name: "Amazon", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "GOOGL", name: "Alphabet (Google)", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "META", name: "Meta Platforms", market: "US Equity", status: "available", note: "Acción" },
      { symbol: "SPY", name: "SPDR S&P 500 ETF", market: "US Equity", status: "available", note: "ETF (S&P 500)" },
      { symbol: "QQQ", name: "Invesco QQQ Trust", market: "US Equity", status: "available", note: "ETF (Nasdaq)" },
      { symbol: "IWM", name: "iShares Russell 2000 ETF", market: "US Equity", status: "available", note: "ETF" },

      # Próximamente
      { symbol: "NQ", name: "Nasdaq E-mini Futures", market: "Futures", status: "coming_soon", note: "Próximamente" },
      { symbol: "ES", name: "S&P 500 E-mini Futures", market: "Futures", status: "coming_soon", note: "Próximamente" },
      { symbol: "MNQ", name: "Micro Nasdaq Futures", market: "Futures", status: "coming_soon", note: "Próximamente" },
      { symbol: "MES", name: "Micro S&P Futures", market: "Futures", status: "coming_soon", note: "Próximamente" },
      { symbol: "EURUSD", name: "Euro / US Dollar", market: "Forex", status: "coming_soon", note: "Próximamente" },
      { symbol: "XAUUSD", name: "Gold / US Dollar", market: "Forex", status: "coming_soon", note: "Próximamente" },
      { symbol: "BTCUSD", name: "Bitcoin / USD", market: "Crypto", status: "coming_soon", note: "Próximamente" }
    ].freeze

    def self.all
      ITEMS
    end

    def self.available
      ITEMS.select { |i| i[:status] == "available" }
    end

    def self.coming_soon
      ITEMS.select { |i| i[:status] == "coming_soon" }
    end

    def self.available?(symbol)
      available.any? { |i| i[:symbol] == symbol.upcase }
    end
  end
end
