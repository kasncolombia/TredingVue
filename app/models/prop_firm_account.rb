class PropFirmAccount < ApplicationRecord
  belongs_to :user
  belongs_to :prop_firm_rule_template, optional: true
  has_many :trades, dependent: :nullify
  has_and_belongs_to_many :strategies

  validates :name, :firm_name, :plan_name, :account_size, :phase, :status, presence: true

  # Fallback a los templates si no hay custom overrides
  def active_profit_target
    custom_profit_target || prop_firm_rule_template&.profit_target
  end

  def active_max_drawdown
    custom_max_drawdown || prop_firm_rule_template&.max_drawdown
  end

  def active_drawdown_type
    custom_drawdown_type || prop_firm_rule_template&.drawdown_type
  end

  def active_daily_loss_limit
    custom_daily_loss_limit || prop_firm_rule_template&.daily_loss_limit
  end

  def active_consistency_pct
    custom_consistency_pct || prop_firm_rule_template&.consistency_pct
  end

  def active_min_trading_days
    custom_min_trading_days || prop_firm_rule_template&.min_trading_days
  end
end
