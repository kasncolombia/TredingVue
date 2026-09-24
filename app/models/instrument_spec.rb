class InstrumentSpec < ApplicationRecord
  validates :symbol, presence: true, uniqueness: true
end
