class AddCategoryToPropTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :prop_transactions, :category, :string
    
    # Migrar datos existentes
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE prop_transactions 
          SET category = 'payout' 
          WHERE transaction_type = 'payout';
          
          UPDATE prop_transactions 
          SET category = 'evaluacion' 
          WHERE transaction_type = 'expense' AND category IS NULL;
        SQL
      end
    end
  end
end
