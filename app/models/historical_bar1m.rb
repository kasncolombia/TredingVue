class HistoricalBar1m < ApplicationRecord
  validates :symbol, :timestamp_utc, :open, :high, :low, :close, presence: true
end
