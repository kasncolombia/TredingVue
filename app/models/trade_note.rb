class TradeNote < ApplicationRecord
  belongs_to :trade

  validates :content, presence: true
end
