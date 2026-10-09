class HistoricalDataCoverage < ApplicationRecord
  validates :symbol, presence: true
  validates :from_date, presence: true
  validates :to_date, presence: true
  validates :status, presence: true

  # status: pending, importing, completed, failed
end
