class PropFirmAccount < ApplicationRecord
  belongs_to :user
  belongs_to :prop_firm_rule_template, optional: true
  has_many :trades, dependent: :nullify
  has_many :prop_transactions, class_name: "PropTransaction", dependent: :nullify
  has_and_belongs_to_many :strategies

  # ── CONSTANTES ──
  STATUSES = %w[activa quemada reseteada pausada].freeze
  PHASES = %w[paso_1 paso_2 fondeada express sim].freeze

  BURN_REASONS = [
    "Pérdida diaria superada",
    "Drawdown máximo superado",
    "Días límite / Inactividad",
    "Operar en noticias restringidas",
    "Falta de gestión de riesgo / Overtrading",
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

  # ── SCOPES ──
  scope :evaluacion, -> { where(status: "activa", phase: %w[paso_1 paso_2 express sim]) }
  scope :fondeada,   -> { where(status: "activa", phase: "fondeada") }
  scope :quemada,    -> { where(status: "quemada") }
  scope :pausada,    -> { where(status: "pausada") }
  scope :reseteada,  -> { where(status: "reseteada") }
  scope :activas,    -> { where(status: "activa") }

  # ── ESTADO: PREDICADOS ──
  def evaluacion?
    status == "activa" && phase.in?(%w[paso_1 paso_2 express sim])
  end

  def fondeada?
    status == "activa" && phase == "fondeada"
  end

  def quemada?
    status == "quemada"
  end
  
  def pausada?
    status == "pausada"
  end

  def reseteada?
    status == "reseteada"
  end

  def cerrada?
    # Para retrocompatibilidad
    quemada? || pausada?
  end

  # ── ETIQUETA LEGIBLE DE ESTADO (para la UI) ──
  def status_label
    status&.capitalize
  end

  def phase_label
    return nil unless phase.present?
    case phase
    when "paso_1" then "Paso 1 (Eval)"
    when "paso_2" then "Paso 2 (Eval)"
    when "fondeada" then "Fondeada / Live"
    when "express" then "Express"
    when "sim" then "Simulación"
    else phase.gsub("_", " ").capitalize
    end
  end

  # ── CONFIG DE REGLAS ──
  def current_rules_section
    case phase
    when "paso_1", "express", "sim"
      "step1"
    when "paso_2"
      rules_config.dig("step2", "same_as_step1") ? "step1" : "step2"
    when "fondeada"
      "funded"
    else
      "step1"
    end
  end
  
  def rule_value_for(field)
    return current_rules[field.to_s] if current_rules && current_rules.key?(field.to_s)
    # Check legacy custom configs
    legacy_val = send("custom_#{field}") if respond_to?("custom_#{field}")
    return legacy_val if legacy_val.present?
    
    # Check template
    prop_firm_rule_template&.send(field) if prop_firm_rule_template.respond_to?(field)
  end
  
  def current_rules
    rules_config.present? ? (rules_config[current_rules_section] || {}) : {}
  end
  
  def to_amount(value_hash)
    return 0.0 unless value_hash.is_a?(Hash)
    val = value_hash["value"].to_f
    unit = value_hash["unit"]
    return val if unit == "amount"
    (val / 100.0) * initial_balance
  end

  # ── REGLAS ACTIVAS ──
  def active_profit_target
    v = current_rules["profit_target"]
    return to_amount(v) if v.is_a?(Hash)
    rule_value_for(:profit_target)
  end

  def active_max_drawdown
    v = current_rules["max_drawdown"]
    return to_amount(v) if v.is_a?(Hash)
    rule_value_for(:max_drawdown)
  end

  def active_drawdown_type
    v = current_rules["max_drawdown"]
    return v["type"] if v.is_a?(Hash) && v["type"].present?
    rule_value_for(:drawdown_type)
  end
  
  def active_drawdown_floor
    current_rules["drawdown_floor"] || "initial_balance"
  end

  def active_daily_loss_limit
    v = current_rules["daily_loss"]
    if v.is_a?(Hash)
      return 0.0 unless v["enabled"]
      return to_amount(v)
    end
    rule_value_for(:daily_loss_limit)
  end

  def active_consistency_pct
    c = current_rules["consistency"]
    if c.is_a?(Hash)
      return 0.0 unless c["enabled"]
      return c["pct"].to_f
    end
    rule_value_for(:consistency_pct)
  end

  def active_min_trading_days
    current_rules["min_trading_days"].present? ? current_rules["min_trading_days"].to_i : rule_value_for(:min_trading_days).to_i
  end
  
  def active_period_days
    return nil if current_rules["unlimited_period"]
    current_rules["period_days"].presence
  end

  # ── CÁLCULOS DE NEGOCIO ──

  def initial_balance
    raw = account_size.to_s.strip
    if raw =~ /\A[\d.]+K\z/i
      raw.gsub(/K/i, "").to_f * 1_000
    else
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
    
    if active_drawdown_type == "static"
      initial_balance - max_dd
    elsif active_drawdown_floor == "fixed"
      # Si es fixed, se basa en el balance actual máximo - max_dd pero sin estancarse, o piso al start? En legacy era initial_balance para 'floor'.
      # Mantenemos inicial_balance - max_dd para simplicidad si type != 'trailing' o si es intraday pero usa floor=initial_balance
      initial_balance - max_dd
    else
      # Trailing regular (intraday)
      # Esto requeriría calcular el max balance histórico, por simplicidad para la UI:
      initial_balance - max_dd 
    end
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

  # ── TRANSICIONES DE ESTADO ──

  def pasar_a_fondeada!(costo_activacion: nil)
    raise "Solo cuentas en evaluación pueden pasar a fondeada" unless evaluacion?

    transaction do
      update!(
        phase: "fondeada",
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

  def quemar!(motivo:)
    raise "No se puede quemar una cuenta ya quemada" if quemada?
    raise "Motivo de quema es obligatorio" if motivo.blank?

    update!(
      status: "quemada",
      burn_reason: motivo,
      burned_at: Date.current
    )
  end

  def cerrar!
    update!(status: "pausada")
  end

  def resetear!(costo_reset: 0)
    raise "Solo cuentas quemadas se pueden resetear" unless quemada?

    transaction do
      update!(
        status: "activa",
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

  def account_size_within_range
    return if account_size.blank?
    balance = initial_balance
    if balance < 1_000 || balance > 5_000_000
      errors.add(:account_size, "debe representar un valor entre $1,000 y $5,000,000")
    end
  end
end
