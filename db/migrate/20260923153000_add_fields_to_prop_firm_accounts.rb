class AddFieldsToPropFirmAccounts < ActiveRecord::Migration[8.0]
  def change
    add_column :prop_firm_accounts, :burn_reason, :string
    add_column :prop_firm_accounts, :billing_date, :date
  end
end
