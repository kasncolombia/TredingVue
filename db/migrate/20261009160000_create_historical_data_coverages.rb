class CreateHistoricalDataCoverages < ActiveRecord::Migration[8.1]
  def change
    create_table :historical_data_coverages do |t|
      t.string :symbol, null: false
      t.date :from_date, null: false
      t.date :to_date, null: false
      t.string :status, default: "pending", null: false
      t.text :error_message

      t.timestamps
    end
    add_index :historical_data_coverages, [:symbol, :from_date, :to_date], unique: true, name: 'idx_historical_coverages'
  end
end
