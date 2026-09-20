class PropFirmAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account, only: [:show, :edit, :update, :destroy]

  def show
    redirect_to edit_prop_firm_account_path(@account)
  end

  def index
    @accounts = current_user.prop_firm_accounts.order(created_at: :desc)
    @new_account = current_user.prop_firm_accounts.new
    @strategies = current_user.strategies
  end

  def new
    @account = current_user.prop_firm_accounts.new
    @strategies = current_user.strategies
  end

  def create
    @account = current_user.prop_firm_accounts.new(account_params)
    @account.status ||= "active"

    if params[:strategy_ids].present?
      @account.strategy_ids = params[:strategy_ids]
    end

    if @account.save
      redirect_to prop_firm_accounts_path, notice: "Cuenta de Fondeo creada exitosamente."
    else
      @strategies = current_user.strategies
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @strategies = current_user.strategies
  end

  def update
    if params[:strategy_ids].present?
      @account.strategy_ids = params[:strategy_ids]
    end

    if @account.update(account_params)
      redirect_to prop_firm_accounts_path, notice: "Cuenta de Fondeo actualizada."
    else
      @strategies = current_user.strategies
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    redirect_to prop_firm_accounts_path, notice: "Cuenta eliminada."
  end

  private

  def set_account
    @account = current_user.prop_firm_accounts.find(params[:id])
  end

  def account_params
    params.require(:prop_firm_account).permit(
      :name, :firm_name, :plan_name, :account_size, :phase, :status,
      :eval_fee, :activation_fee,
      :custom_profit_target, :custom_max_drawdown, :custom_drawdown_type,
      :custom_daily_loss_limit, :custom_consistency_pct, :custom_min_trading_days
    )
  end
end
