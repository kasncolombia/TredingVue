class CreateTradingAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :trading_accounts do |t|
      t.references :user,                null: false, foreign_key: true
      t.references :broker,              null: true,  foreign_key: true
      t.references :prop_firm_account,   null: true,  foreign_key: true
      t.string     :name,                null: false
      t.string     :connection_method,   null: false, default: "manual" # autosync, file_upload, manual
      t.string     :account_type,        default: "real"
      t.string     :time_zone,           default: "UTC"
      t.string     :date_format,         default: "YYYY-MM-DD"
      t.string     :api_key
      t.string     :api_secret
      t.datetime   :last_synced_at

      t.timestamps
    end

    add_reference :trades, :trading_account, foreign_key: true, null: true
  end
end
