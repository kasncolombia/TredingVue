class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :strategy, optional: true
  has_many :trade_notes,  dependent: :destroy
  has_many :ai_analyses,  dependent: :destroy

  before_validation :set_result

  validates :symbol, :direction, :entry_price, :exit_price, :pnl, presence: true
  validates :direction, inclusion: { in: %w[LONG SHORT] }
  validates :result,    inclusion: { in: %w[WIN LOSS BREAKEVEN] }

  scope :wins,       -> { where(result: "WIN") }
  scope :losses,     -> { where(result: "LOSS") }
  scope :longs,      -> { where(direction: "LONG") }
  scope :shorts,     -> { where(direction: "SHORT") }
  scope :by_symbol,  ->(sym) { where(symbol: sym) }
  scope :recent,     -> { order(entry_at: :desc) }

  def win?
    result == "WIN" || pnl.to_f > 0
  end

  def loss?
    result == "LOSS" || pnl.to_f < 0
  end

  private

  def set_result
    self.result = pnl.to_f >= 0 ? "WIN" : "LOSS" if result.blank?
  end
end
