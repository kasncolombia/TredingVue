class CreatePropFirmAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :prop_firm_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prop_firm_rule_template, foreign_key: true # Opcional si personaliza todo

      t.string  :name, null: false # Nombre puesto por el usuario
      
      # Datos heredados por seguridad en el tiempo (por si el template cambia, no romper historias pasadas)
      t.string  :firm_name,        null: false
      t.string  :plan_name,        null: false
      t.string  :account_size,     null: false
      t.string  :phase,            null: false # evaluación, fondeada
      t.string  :status,           null: false, default: "activa" # activa, aprobada, quemada

      t.decimal :eval_fee,         precision: 10, scale: 2, default: 0.0
      t.decimal :activation_fee,   precision: 10, scale: 2, default: 0.0
      t.date    :start_date

      # Parámetros Overrides (si es NULL se usa el template, si tiene valor es Custom)
      t.decimal :custom_profit_target,    precision: 12, scale: 2
      t.decimal :custom_max_drawdown,     precision: 12, scale: 2
      t.string  :custom_drawdown_type
      t.decimal :custom_daily_loss_limit, precision: 12, scale: 2
      t.decimal :custom_consistency_pct,  precision: 5,  scale: 2
      t.integer :custom_min_trading_days

      t.timestamps
    end

    # Join table para has_and_belongs_to_many
    create_join_table :prop_firm_accounts, :strategies do |t|
      t.index :prop_firm_account_id, name: 'idx_prop_accounts_strategies_pfa_id'
      t.index :strategy_id
    end
  end
end
