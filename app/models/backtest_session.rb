# app/models/backtest_session.rb
class BacktestSession < ApplicationRecord
  belongs_to :user
  belongs_to :strategy, optional: true

  has_many :backtest_orders,    dependent: :destroy
  has_many :backtest_positions, dependent: :destroy
  has_many :backtest_trades,    dependent: :destroy

  # Estados del Replay Engine
  STATES = %w[created running playing paused finished].freeze

  # Constantes actualizadas con estados en español humanizables
  STATUSES = %w[active en_curso en_pausa finalizada].freeze
  DATA_STATUSES = %w[pendiente importando lista fallo].freeze

  validates :name,   presence: true
  validates :symbol, presence: true
  validates :state,  inclusion: { in: STATES }
  validates :status, inclusion: { in: STATUSES }
  validates :data_status, inclusion: { in: DATA_STATUSES }, allow_nil: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  
  validate :dates_within_limits

  # Virtual attributes para dashboard
  def pnl_neto
    (balance_actual || balance_inicial) - balance_inicial
  end

  def trades_count
    backtest_trades.count
  end

  def progress_percentage
    return 0 unless start_date && end_date && replay_cursor_at
    total_seconds = end_date.end_of_day.to_i - start_date.beginning_of_day.to_i
    elapsed_seconds = replay_cursor_at.to_i - start_date.beginning_of_day.to_i
    return 0 if total_seconds <= 0
    pct = (elapsed_seconds.to_f / total_seconds) * 100
    pct.clamp(0, 100)
  end

  def human_status
    # Normalizador compatible hacia atrás
    return "en_curso" if status == "active"
    status
  end

  # Helpers útiles
  def running?
    state == "running" || state == "playing" || status == "en_curso"
  end

  def paused?
    state == "paused"
  end

  def finished?
    state == "finished"
  end

  private

  def dates_within_limits
    return if start_date.blank? || end_date.blank?

    if start_date < 2.years.ago.to_date
      errors.add(:start_date, "no puede ser anterior a 2 años atrás")
    end

    max_date = Date.today
    max_date -= 1.day while max_date.saturday? || max_date.sunday? || max_date == Date.today

    if end_date > max_date
      errors.add(:end_date, "no puede ser posterior al último día hábil (#{max_date})")
    end

    if (end_date - start_date).to_i > 30
      errors.add(:base, "El rango máximo es de 30 días por sesión")
    end

    if start_date > end_date
      errors.add(:start_date, "debe ser anterior o igual a la fecha de fin")
    end
  end
end