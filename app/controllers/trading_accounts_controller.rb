class TradingAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trading_account, only: [:destroy]

  def index
    @trading_accounts = current_user.trading_accounts.includes(:broker, :prop_firm_account).order(created_at: :desc)
    @brokers = Broker.order(:name)
  end

  def wizard
    @brokers = Broker.order(:name)
    @prop_firm_accounts = current_user.prop_firm_accounts.where(status: "activa")
    render layout: false if request.xhr?
  end

  def brokers_json
    query = params[:q].to_s.downcase.strip
    brokers = Broker.order(:name)
    brokers = brokers.where("LOWER(name) LIKE ?", "%#{query}%") if query.present?

    render json: brokers.map { |b|
      {
        id: b.id,
        name: b.name,
        category: b.category,
        logo_url: b.logo_url ? ActionController::Base.helpers.image_path(b.logo_url) : nil,
        supports_autosync: b.supports_autosync,
        supports_file_upload: b.supports_file_upload,
        supports_manual: b.supports_manual,
        autosync_instructions: b.autosync_instructions
      }
    }
  end

  def create
    @trading_account = current_user.trading_accounts.build(trading_account_params)

    if @trading_account.save
      respond_to do |format|
        format.html { redirect_to trading_accounts_path, notice: "¡Cuenta conectada exitosamente!" }
        format.json { render json: { status: "success", account: @trading_account }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to wizard_trading_accounts_path, alert: @trading_account.errors.full_messages.join(", ") }
        format.json { render json: { status: "error", errors: @trading_account.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @trading_account.destroy
    redirect_to trading_accounts_path, notice: "Conexión de cuenta eliminada."
  end

  private

  def set_trading_account
    @trading_account = current_user.trading_accounts.find(params[:id])
  end

  def trading_account_params
    p = params.require(:trading_account).permit(
      :name, :broker_id, :prop_firm_account_id, :connection_method,
      :account_type, :time_zone, :date_format, :api_key, :api_secret
    )
    p[:broker_id] = nil if p[:broker_id].blank? || !Broker.exists?(p[:broker_id])
    p[:prop_firm_account_id] = nil if p[:prop_firm_account_id].blank? || !current_user.prop_firm_accounts.exists?(p[:prop_firm_account_id])
    p
  end
end
