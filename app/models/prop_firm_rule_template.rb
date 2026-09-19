class PropFirmRuleTemplate < ApplicationRecord
  has_many :prop_firm_accounts

  validates :firm_name, :plan_name, :account_size, :phase, :drawdown_type, presence: true
  validates :profit_target, :max_drawdown, numericality: { greater_than: 0 }, allow_nil: true
  
  # Constantes de ayuda
  FIRMS = ["Topstep", "Apex Trader Funding", "MyFundedFutures", "Take Profit Trader", "Alpha Futures", "Tradeify", "Lucid"].freeze
  PHASES = ["evaluacion", "fondeada"].freeze
  DRAWDOWN_TYPES = ["eod", "trailing", "static"].freeze
  ACCOUNT_SIZES = ["25K", "50K", "100K", "150K", "250K"].freeze
end
