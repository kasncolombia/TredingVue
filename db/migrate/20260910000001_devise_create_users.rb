class DeviseCreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name,                 null: false, default: ""
      t.string :email,                null: false, default: ""
      t.string :encrypted_password,  null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :timezone,            default: "UTC"
      t.string :preferred_currency,  default: "USD"
      t.decimal :initial_capital,    precision: 15, scale: 2
      t.timestamps null: false
    end
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
