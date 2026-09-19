class PropTransactionsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @transactions = current_user.prop_transactions.recent
    @total_expenses = current_user.prop_transactions.total_expenses
    @total_payouts = current_user.prop_transactions.total_payouts
    @net_profit = current_user.prop_transactions.net_profit
    @roi = current_user.prop_transactions.roi_percentage
    @new_transaction = current_user.prop_transactions.new
  end

  def create
    @transaction = current_user.prop_transactions.build(transaction_params)
    if @transaction.save
      redirect_to prop_transactions_path, notice: "Transacción contable guardada exitosamente."
    else
      redirect_to prop_transactions_path, alert: "Error al registrar la transacción: #{@transaction.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @transaction = current_user.prop_transactions.find(params[:id])
    @transaction.destroy
    redirect_to prop_transactions_path, notice: "Recibo contable eliminado correctamente."
  end

  private

  def transaction_params
    params.require(:prop_transaction).permit(:company_name, :transaction_type, :amount, :description, :transaction_date)
  end
end
