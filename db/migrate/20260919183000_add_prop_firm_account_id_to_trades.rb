class AddPropFirmAccountIdToTrades < ActiveRecord::Migration[8.0]
  def change
    add_reference :trades, :prop_firm_account, foreign_key: true, null: true
  end
end
