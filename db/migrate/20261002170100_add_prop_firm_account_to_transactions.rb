# Fase 1 complemento: agregar FK de cuenta a prop_transactions
class AddPropFirmAccountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :prop_transactions, :prop_firm_account, foreign_key: true, null: true
  end
end
