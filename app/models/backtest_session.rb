# app/models/backtest_session.rb
class BacktestSession < ApplicationRecord
  belongs_to :user
  belongs_to :strategy, optional: true

  has_many :backtest_orders,    dependent: :destroy
  has_many :backtest_positions, dependent: :destroy
  has_many :backtest_trades,    dependent: :destroy

  # Estados del Replay Engine
  STATES = %w[created running playing paused finished].freeze

  validates :name,   presence: true
  validates :symbol, presence: true
  validates :state,  inclusion: { in: STATES }

  # Helpers útiles
  def running?
    state == "running" || state == "playing"
  end

  def paused?
    state == "paused"
  end

  def finished?
    state == "finished"
  end
end