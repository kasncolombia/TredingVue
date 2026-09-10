class TradeShare < ApplicationRecord
  belongs_to :user
  belongs_to :trade

  validates :privacy, inclusion: { in: %w[public followers private] }
  validates :title, presence: true, length: { maximum: 200 }

  scope :recent, -> { order(created_at: :desc) }
end