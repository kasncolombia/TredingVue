class PropFirmAccount < ApplicationRecord
  belongs_to :user
  belongs_to :prop_firm_rule_template, optional: true
  has_many :trades, dependent: :nullify
  has_many :prop_transactions, class_name: "PropTransaction", dependent: :nullify
  has_and_belongs_to_many :strategies

  # ── CONSTANTES ──
  # Estados mutuamente excluyentes (un solo campo `status`)
  STATUSES = %w[evaluacion fondeada quemada cerrada].freeze

  # Fases de evaluación (solo aplica cuando status == evaluacion)
  PHASES = %w[paso_1 paso_2].freeze

  BURN_REASONS = [
    "Falta de gestión de riesgo",
    "Noticia",
    "Overtrading",
    "Regla de consistencia",
    "Drawdown máximo",
    "Pérdida diaria máxima",
    "Presión de tiempo",
    "Error técnico / Plataforma",
    "Otro"
  ].freeze

  # ── VALIDACIONES ──
  validates :name, :firm_name, :plan_name, :status, presence: true
  validates :account_size, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :phase, inclusion: { in: PHASES }, allow_nil: true
  validates :burn_reason, presence: true, if: -> { quemada? }
  validate :account_size_within_range
  validate :phase_only_in_evaluacion

  # ── SCOPES ──
  scope :evaluacion, -> { where(status: "evaluacion") }
  scope :fondeada,   -> { where(status: "fondeada") }
  scope :quemada,    -> { where(status: "quemada") }
  scope :cerrada,    -> { where(status: "cerrada") }
  scope :activas,    -> { where(status: %w[evaluacion fondeada]) }

  # ── ESTADO: PREDICADOS ──
  def evaluacion?
    status == "evaluacion"
  end

  def fondeada?
    status == "fondeada"
  end

  def quemada?
    status == "quemada"
  end

  def cerrada?
    status == "cerrada"
  end

  # ── ETIQUETA LEGIBLE DE ESTADO (para la UI) ──
  def status_label
    case status
    when "evaluacion" then "Evaluación"
    when "fondeada"   then "Fondeada"
    when "quemada"    then "Quemada"
    when "cerrada"    then "Cerrada"
    else status&.capitalize
    end
  end

  def phase_label
    return nil unless evaluacion? && phase.present?
    phase.gsub("_", " ").capitalize # "paso_1" → "Paso 1"
  end

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

  # Interpreta account_size de forma segura.
  # Soporta formatos: "50K", "100K", "150000", 50000
  def initial_balance
    raw = account_size.to_s.strip
    if raw =~ /\A[\d.]+K\z/i
      # Formato "50K" → 50_000
      raw.gsub(/K/i, "").to_f * 1_000
    else
      # Formato numérico directo "50000"
      raw.gsub(/[^\d.]/, "").to_f
    end
  end

  def pnl_total
    trades.sum(:pnl).to_f
  end

  def current_balance
    initial_balance + pnl_total
  end

  def days_traded
    trades.where.not(entry_at: nil).pluck(:entry_at).map(&:to_date).uniq.count
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
                         .group_by { |t| t.entry_at.to_date }
                         .transform_values { |ts| ts.sum { |t| t.pnl.to_f } }
                         .values
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

  # ══════════════════════════════════════════
  # TRANSICIONES DE ESTADO
  # Cada método valida la transición y crea
  # transacciones financieras cuando corresponde.
  # ══════════════════════════════════════════

  # Pasa la cuenta a fondeada. Opcionalmente registra gasto de activación.
  def pasar_a_fondeada!(costo_activacion: nil)
    raise "Solo cuentas en evaluación pueden pasar a fondeada" unless evaluacion?

    transaction do
      update!(
        status: "fondeada",
        phase: nil,
        funded_at: Date.current
      )

      costo = costo_activacion || activation_fee.to_f
      if costo > 0
        user.prop_transactions.create!(
          prop_firm_account: self,
          company_name: firm_name,
          transaction_type: "expense",
          category: "activacion",
          amount: costo,
          description: "Activación cuenta fondeada: #{name}",
          transaction_date: Date.current
        )
      end
    end
  end

  # Marca la cuenta como quemada. Motivo es obligatorio.
  def quemar!(motivo:)
    raise "No se puede quemar una cuenta ya quemada o cerrada" if quemada? || cerrada?
    raise "Motivo de quema es obligatorio" if motivo.blank?

    update!(
      status: "quemada",
      burn_reason: motivo,
      burned_at: Date.current,
      phase: nil
    )
  end

  # Cierra definitivamente la cuenta.
  def cerrar!
    raise "Solo cuentas fondeadas o quemadas se pueden cerrar" unless fondeada? || quemada?

    update!(status: "cerrada", phase: nil)
  end

  # Resetea una cuenta quemada a evaluación. Opcionalmente registra gasto de reset.
  def resetear!(costo_reset: 0)
    raise "Solo cuentas quemadas se pueden resetear" unless quemada?

    transaction do
      update!(
        status: "evaluacion",
        phase: "paso_1",
        burn_reason: nil,
        burned_at: nil
      )

      if costo_reset.to_f > 0
        user.prop_transactions.create!(
          prop_firm_account: self,
          company_name: firm_name,
          transaction_type: "expense",
          category: "reset",
          amount: costo_reset.to_f,
          description: "Reset de cuenta: #{name}",
          transaction_date: Date.current
        )
      end
    end
  end

  # ── LEGACY ALIASES (compatibilidad con controlador existente) ──
  def mark_as_burned!(reason)
    quemar!(motivo: reason)
  end

  def reset_account!(reset_cost = 0)
    resetear!(costo_reset: reset_cost)
  end

  def move_to_funded!(activation_cost = 0)
    pasar_a_fondeada!(costo_activacion: activation_cost)
  end

  def burn_reason_name
    burn_reason.presence
  end

  private

  # Valida que el tamaño de cuenta interpretado esté en un rango razonable
  def account_size_within_range
    return if account_size.blank?
    balance = initial_balance
    if balance < 5_000 || balance > 1_000_000
      errors.add(:account_size, "debe representar un valor entre $5,000 y $1,000,000 (valor interpretado: $#{balance.to_i})")
    end
  end

  # La fase solo tiene sentido cuando el status es evaluación
  def phase_only_in_evaluacion
    if phase.present? && !evaluacion?
      errors.add(:phase, "solo aplica cuando la cuenta está en evaluación")
    end
  end
end
