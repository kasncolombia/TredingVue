class PropFirmAccount < ApplicationRecord
  belongs_to :user
  belongs_to :prop_firm_rule_template, optional: true
  has_many :trades, dependent: :nullify
  has_and_belongs_to_many :strategies

  validates :name, :firm_name, :plan_name, :account_size, :phase, :status, presence: true

  # ── CONSTANTES ──
  STATUSES = %w[activa quemada fondeada reseteada pausada].freeze
  PHASES   = %w[paso_1 paso_2 fondeada express sim].freeze

  BURN_REASONS = [
    "Rompió drawdown máximo",
    "Rompió pérdida diaria",
    "Overtrading",
    "Presión de tiempo",
    "Falta de gestión de riesgo",
    "Noticia / Evento inesperado",
    "Error técnico / Plataforma",
    "Otro"
  ].freeze

  # ── SCOPES ──
  scope :active,  -> { where(status: "activa") }
  scope :burned,  -> { where(status: "quemada") }
  scope :funded,  -> { where(status: "fondeada") }

  # ── REGLAS ACTIVAS (Fallback a templates) ──
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
    custom_min_trading_days || prop_firm_rule_template&.min_trading_days || 0
  end

  # ── CÁLCULOS DE NEGOCIO ──
  def initial_balance
    account_size.to_s.gsub(/[^\d.]/, '').to_f * 1000
  end

  def pnl_total
    trades.sum(:pnl).to_f
  end

  def current_balance
    initial_balance + pnl_total
  end

  def days_traded
    trades.where.not(entry_at: nil).pluck("DATE(entry_at)").uniq.count
  end

  def win_rate
    total = trades.count
    return 0.0 if total.zero?
    (trades.wins.count.to_f / total * 100).round(1)
  end

  def profit_factor
    wins_amount = trades.wins.sum(:pnl).to_f
    losses_amount = trades.losses.sum(:pnl).to_f.abs
    return wins_amount.round(2) if losses_amount.zero?
    (wins_amount / losses_amount).round(2)
  end

  # ── DRAWDOWN ──
  def drawdown_floor
    max_dd = active_max_drawdown.to_f
    return 0.0 if max_dd.zero?
    initial_balance - max_dd
  end

  def margin_to_floor
    current_balance - drawdown_floor
  end

  def drawdown_consumed_pct
    max_dd = active_max_drawdown.to_f
    return 0.0 if max_dd.zero?
    consumed = [initial_balance - current_balance, 0].max
    [(consumed / max_dd * 100).round(1), 100.0].min
  end

  # Retorna :safe, :warning, :danger
  def drawdown_status
    pct = drawdown_consumed_pct
    if pct >= 80
      :danger
    elsif pct >= 50
      :warning
    else
      :safe
    end
  end

  def daily_pnl_today
    trades.where("entry_at >= ?", Time.current.beginning_of_day).sum(:pnl).to_f
  end

  def daily_loss_breached?
    limit = active_daily_loss_limit.to_f
    return false if limit.zero?
    daily_pnl_today.abs >= limit && daily_pnl_today < 0
  end

  # ── PATH TO FUNDING ──
  def profit_target_pct
    target = active_profit_target.to_f
    return 0.0 if target.zero?
    pnl = pnl_total
    [(pnl / target * 100).round(1), 100.0].min
  end

  def min_days_progress_pct
    min_days = active_min_trading_days.to_i
    return 100.0 if min_days.zero?
    [(days_traded.to_f / min_days * 100).round(1), 100.0].min
  end

  def consistency_check
    total_pnl = pnl_total
    return { pass: true, best_day_pct: 0.0 } if total_pnl <= 0

    best_day_pnl = trades.where.not(entry_at: nil)
                         .group("DATE(entry_at)")
                         .sum(:pnl)
                         .values
                         .map(&:to_f)
                         .max || 0.0

    limit_pct = active_consistency_pct.to_f
    limit_pct = 50.0 if limit_pct.zero?
    best_day_share = (best_day_pnl / total_pnl * 100).round(1)

    { pass: best_day_share <= limit_pct, best_day_pct: best_day_share, limit_pct: limit_pct }
  end

  def path_to_funding
    {
      profit_pct: profit_target_pct,
      min_days_pct: min_days_progress_pct,
      drawdown_consumed_pct: drawdown_consumed_pct,
      consistency: consistency_check,
      drawdown_status: drawdown_status
    }
  end

  # ── ACCIONES DE ESTADO ──
  def mark_as_burned!(reason)
    update!(status: "quemada", custom_drawdown_type: "#{custom_drawdown_type}|burn:#{reason}")
  end

  def reset_account!(reset_cost = 0)
    transaction do
      update!(status: "activa")
      if reset_cost.to_f > 0
        user.prop_transactions.create!(
          company_name: firm_name,
          transaction_type: "expense",
          amount: reset_cost.to_f,
          description: "Reset de cuenta: #{name}",
          transaction_date: Date.today
        )
      end
    end
  end

  def move_to_funded!(activation_cost = 0)
    transaction do
      update!(status: "fondeada", phase: "fondeada")
      if activation_cost.to_f > 0
        user.prop_transactions.create!(
          company_name: firm_name,
          transaction_type: "expense",
          amount: activation_cost.to_f,
          description: "Activación cuenta fondeada: #{name}",
          transaction_date: Date.today
        )
      end
    end
  end

  def burn_reason
    return nil unless status == "quemada"
    type_data = custom_drawdown_type.to_s
    match = type_data.match(/burn:(.+)/)
    match ? match[1] : nil
  end
end
