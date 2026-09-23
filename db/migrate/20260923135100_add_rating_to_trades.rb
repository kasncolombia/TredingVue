class AddRatingToTrades < ActiveRecord::Migration[8.1]
  def change
    add_column :trades, :rating, :integer
  end
end
