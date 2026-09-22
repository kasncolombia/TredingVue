class Trade < ApplicationRecord
  belongs_to :user
  belongs_to :strategy, optional: true
  belongs_to :prop_firm_account, optional: true
  belongs_to :trading_account, optional: true
  has_many :ai_analyses,  dependent: :destroy
  has_one  :ai_analysis,  -> { order(created_at: :desc) }, dependent: :destroy

  before_validation :set_result
  before_validation :set_entry_at

  validates :symbol, :direction, :entry_price, :exit_price, :pnl, presence: true
  validates :direction, inclusion: { in: %w[LONG SHORT] }
  validates :result,    inclusion: { in: %w[WIN LOSS BREAKEVEN] }

  scope :wins,       -> { where(result: "WIN") }
  scope :losses,     -> { where(result: "LOSS") }
  scope :longs,      -> { where(direction: "LONG") }
  scope :shorts,     -> { where(direction: "SHORT") }
  scope :by_symbol,  ->(sym) { where(symbol: sym) }
  scope :recent,     -> { order(entry_at: :desc) }

  enum :portfolio_mode, { real_account: 0, prop_firm: 1, backtest: 2 }, default: :real_account

  scope :is_real,       -> { where(portfolio_mode: :real_account) }
  scope :is_prop_firm,  -> { where(portfolio_mode: :prop_firm) }
  scope :is_backtest,   -> { where(portfolio_mode: :backtest) }

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

  def set_entry_at
    self.entry_at ||= Time.current
  end
end
