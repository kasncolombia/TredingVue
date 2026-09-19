class BacktestSession < ApplicationRecord
  belongs_to :user
  belongs_to :strategy, optional: true

  enum :session_type, { backtest: "backtest", prop_firm: "prop_firm" }
  enum :status,       { active: "active", completed: "completed", failed: "failed" }

  validates :name, :session_type, :account_size, presence: true
  validates :account_size, numericality: { greater_than: 0 }

  scope :recent, -> { order(created_at: :desc) }

  # Conocidas Prop Firms disponibles como presets
  PROP_FIRMS = [
    { name: "Apex Trader Funding",    daily_loss: 3.0, max_dd: 6.0,  target: 6.0  },
    { name: "Topstep",               daily_loss: 2.0, max_dd: 6.0,  target: 6.0  },
    { name: "My Funded Futures",      daily_loss: 2.0, max_dd: 8.0,  target: 8.0  },
    { name: "Take Profit Trader",     daily_loss: 2.0, max_dd: 6.0,  target: 8.0  },
    { name: "Tradeify",              daily_loss: 2.0, max_dd: 6.0,  target: 6.0  },
    { name: "Alpha Futures",          daily_loss: 2.0, max_dd: 8.0,  target: 8.0  },
    { name: "Lucid Trading",          daily_loss: 2.5, max_dd: 5.0,  target: 10.0 },
  ].freeze

  def portfolio_mode_value
    session_type == "prop_firm" ? "prop_firm" : "backtest"
  end

  def max_daily_loss_amount
    account_size * max_daily_loss_pct / 100
  end

  def max_drawdown_amount
    account_size * max_drawdown_pct / 100
  end

  def profit_target_amount
    account_size * profit_target_pct / 100
  end
end
