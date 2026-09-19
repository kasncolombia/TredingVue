class CreatePropTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :prop_transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name, null: false
      t.string :transaction_type, null: false, default: "expense"
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :description
      t.date :transaction_date, null: false

      t.timestamps
    end
  end
end
