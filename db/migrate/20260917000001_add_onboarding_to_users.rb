class AddOnboardingToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :onboarding_completed, :boolean, default: false, null: false
    add_column :users, :trader_type, :string
    add_column :users, :main_market, :string
    add_column :users, :trading_goal, :string
  end
end
