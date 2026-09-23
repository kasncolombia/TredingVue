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
    ActiveRecord::Base.transaction do
      @trading_account = current_user.trading_accounts.build(trading_account_params)
      @trading_account.save!

      created_trade = nil
      csv_count = 0

      # Si se ingresaron datos de trade manual en el paso 4
      if params[:trade].present? && params[:trade][:symbol].present?
        tp = trade_params
        tp[:user_id] = current_user.id
        tp[:trading_account_id] = @trading_account.id
        tp[:portfolio_mode] = @trading_account.prop_firm_account_id.present? ? "prop_firm" : "real_account"
        tp[:prop_firm_account_id] = @trading_account.prop_firm_account_id

        # Normalizar dirección (BUY/LONG vs SELL/SHORT)
        dir = tp[:direction].to_s.upcase
        tp[:direction] = dir.in?(%w[BUY LONG]) ? "LONG" : "SHORT"

        # Defaults para campos numéricos y fechas requeridas
        tp[:symbol] = tp[:symbol].to_s.strip.upcase
        tp[:entry_price] = tp[:entry_price].presence&.to_f || 0.0
        tp[:exit_price] = tp[:exit_price].presence&.to_f || 0.0
        tp[:position_size] = tp[:position_size].presence&.to_f || 1.0
        tp[:pnl] = tp[:pnl].presence&.to_f || 0.0

        if tp[:entry_at].present?
          tp[:entry_at] = Time.zone.parse(tp[:entry_at].to_s) rescue Time.current
        else
          tp[:entry_at] = Time.current
        end

        if tp[:exit_at].present?
          tp[:exit_at] = Time.zone.parse(tp[:exit_at].to_s) rescue Time.current
        end

        created_trade = current_user.trades.build(tp)
        created_trade.save!

        begin
          Trading::AlertManager.new(current_user).evaluate_trade(created_trade)
        rescue => e
          Rails.logger.warn "AlertManager error: #{e.message}"
        end
      end

      # Si se subió un archivo CSV en el paso 4
      if params[:csv_file].present?
        file = params[:csv_file]
        csv_text = file.read.force_encoding("UTF-8")
        csv_count = Trading::CsvImporter.new(current_user, csv_text).call rescue 0
      end

      # REDIRECCIÓN INTELIGENTE SEGÚN RESULTADO:
      if created_trade.present?
        redirect_target = trade_path(created_trade)
        notice_msg = "¡Cuenta '#{@trading_account.name}' vinculada y operación #{created_trade.symbol} (#{created_trade.direction}) guardada exitosamente en tu diario!"
      elsif csv_count > 0
        redirect_target = trades_path(account_id: @trading_account.id)
        notice_msg = "¡Cuenta '#{@trading_account.name}' vinculada e importadas #{csv_count} operaciones desde CSV!"
      else
        redirect_target = trading_accounts_path
        notice_msg = "¡Cuenta '#{@trading_account.name}' conectada exitosamente!"
      end

      respond_to do |format|
        format.html { redirect_to redirect_target, notice: notice_msg }
        format.json { render json: { status: "success", account: @trading_account, trade_id: created_trade&.id, csv_count: csv_count }, status: :created }
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { redirect_to trading_accounts_path, alert: "Error al registrar la cuenta/operación: #{e.message}" }
      format.json { render json: { status: "error", errors: e.message }, status: :unprocessable_entity }
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

  def trade_params
    params.require(:trade).permit(
      :market, :symbol, :direction, :entry_at, :exit_at,
      :entry_price, :exit_price, :position_size, :pnl, :notes
    )
  end
end
