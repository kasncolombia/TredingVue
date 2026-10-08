class UpgradePropFirmAccountWizard < ActiveRecord::Migration[8.0]
  def change
    add_column :prop_firm_accounts, :rules_config, :json, default: {}
    add_column :prop_firm_accounts, :program_steps, :integer, default: 1
    add_column :prop_firm_accounts, :template_key, :string

    reversible do |dir|
      dir.up do
        # Migramos estados "fondeada" -> "activa" con phase = "fondeada"
        # Y "evaluacion" -> "activa" dejando la phase intacta
        execute <<~SQL
          UPDATE prop_firm_accounts SET phase = 'fondeada' WHERE status = 'fondeada';
        SQL
        execute <<~SQL
          UPDATE prop_firm_accounts SET status = 'activa' WHERE status IN ('fondeada', 'evaluacion');
        SQL
      end
      dir.down do
        # Rollback simple logic
        execute <<~SQL
          UPDATE prop_firm_accounts SET status = 'fondeada' WHERE phase = 'fondeada' AND status = 'activa';
        SQL
      end
    end
  end
end
