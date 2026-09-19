class CreatePropFirmRuleTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :prop_firm_rule_templates do |t|
      t.string  :firm_name,        null: false # Topstep, Apex, etc.
      t.string  :plan_name,        null: false # Estándar, Sin Cuota, etc.
      t.string  :account_size,     null: false # 50K, 100K, 150K
      t.string  :phase,            null: false # evaluación, fondeada
      
      t.decimal :profit_target,    precision: 12, scale: 2
      t.decimal :max_drawdown,     precision: 12, scale: 2
      t.string  :drawdown_type,    null: false, default: 'eod' # eod, trailing, static
      
      t.decimal :daily_loss_limit, precision: 12, scale: 2 # Nullable si no aplica
      t.decimal :consistency_pct,  precision: 5,  scale: 2 # Ej: 50.0 para 50%
      t.integer :min_trading_days, default: 0
      t.integer :max_contracts
      
      t.decimal :default_eval_fee,       precision: 10, scale: 2
      t.decimal :default_activation_fee, precision: 10, scale: 2

      t.timestamps
    end
    
    add_index :prop_firm_rule_templates, [:firm_name, :plan_name, :account_size, :phase], unique: true, name: 'idx_prop_rule_templates_uniqueness'
  end
end
