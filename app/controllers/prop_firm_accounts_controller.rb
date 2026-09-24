class PropFirmAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [
    :show, :edit, :update, :destroy,
    :mark_burned, :reset_account, :move_to_funded
  ]

  def index
    @accounts   = current_user.prop_firm_accounts.order(created_at: :desc)
    @strategies = current_user.strategies
  end

  def show
    @trades      = @account.trades.recent.limit(20)
    @equity_data = Trading::CalculateDrawdown.new(@account.trades).equity_curve
    @stats       = Trading::CalculateStatistics.new(@account.trades).call
    @path        = @account.path_to_funding
    @daily_pnl_today = @account.daily_pnl_today
  end

  def new
    @account    = current_user.prop_firm_accounts.new
    @templates  = PropFirmRuleTemplate.all.order(:firm_name, :account_size)
    @strategies = current_user.strategies
  end

  def edit
    @templates  = PropFirmRuleTemplate.all.order(:firm_name, :account_size)
    @strategies = current_user.strategies
  end

def create
  @account = current_user.prop_firm_accounts.new(account_params)
  @account.status ||= "activa"

  strategy_ids = Array(params[:strategy_ids]).reject(&:blank?)

  if strategy_ids.any?
    @account.strategy_ids = current_user.strategies.where(id: strategy_ids).ids
  end

  if @account.save
    redirect_to prop_firm_account_path(@account),
                notice: "✅ Cuenta de Fondeo creada exitosamente."
  else
    @templates  = PropFirmRuleTemplate.all.order(:firm_name, :account_size)
    @strategies = current_user.strategies
    render :new, status: :unprocessable_entity
  end
end

  def update
    @account.strategy_ids = params[:strategy_ids] if params[:strategy_ids].present?

    if @account.update(account_params)
      redirect_to prop_firm_account_path(@account), notice: "Cuenta actualizada."
    else
      @templates  = PropFirmRuleTemplate.all.order(:firm_name, :account_size)
      @strategies = current_user.strategies
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to prop_firm_accounts_path, notice: "Cuenta eliminada."
  end

  # ── ACCIONES DE ESTADO ──

  def mark_burned
    reason = params[:burn_reason].presence || "Otro"
    @account.mark_as_burned!(reason)
    redirect_to prop_firm_account_path(@account),
                notice: "🔴 Cuenta marcada como quemada. Motivo: #{reason}"
  rescue => e
    redirect_to prop_firm_account_path(@account), alert: "Error: #{e.message}"
  end

  def reset_account
    cost = params[:reset_cost].to_f
    @account.reset_account!(cost)
    msg = cost > 0 ? "Cuenta reseteada. Se registró gasto de $#{cost}." : "Cuenta reseteada a Evaluación."
    redirect_to prop_firm_account_path(@account), notice: "♻️ #{msg}"
  rescue => e
    redirect_to prop_firm_account_path(@account), alert: "Error: #{e.message}"
  end

  def move_to_funded
    cost = params[:activation_cost].to_f
    @account.move_to_funded!(cost)
    msg = cost > 0 ? "¡Cuenta fondeada! Cuota de activación $#{cost} registrada." : "¡Cuenta movida a Fondeada!"
    redirect_to prop_firm_account_path(@account), notice: "🚀 #{msg}"
  rescue => e
    redirect_to prop_firm_account_path(@account), alert: "Error: #{e.message}"
  end

  # ── API JSON para Stimulus (precarga de templates) ──
  def templates_json
    templates = PropFirmRuleTemplate.where(
      firm_name: params[:firm_name],
      account_size: params[:account_size]
    )
    render json: templates.map { |t|
      {
        id: t.id, phase: t.phase,
        profit_target: t.profit_target,
        max_drawdown: t.max_drawdown,
        drawdown_type: t.drawdown_type,
        daily_loss_limit: t.daily_loss_limit,
        consistency_pct: t.consistency_pct,
        min_trading_days: t.min_trading_days,
        default_eval_fee: t.default_eval_fee,
        default_activation_fee: t.default_activation_fee
      }
    }
  end

  private

  def set_account
    @account = current_user.prop_firm_accounts.find(params[:id])
  end

  def account_params
    params.require(:prop_firm_account).permit(
      :name, :firm_name, :plan_name, :account_size, :phase, :status,
      :eval_fee, :activation_fee, :start_date, :billing_date, :burn_reason, :prop_firm_rule_template_id,
      :custom_profit_target, :custom_max_drawdown, :custom_drawdown_type,
      :custom_daily_loss_limit, :custom_consistency_pct, :custom_min_trading_days
    )
  end
end
