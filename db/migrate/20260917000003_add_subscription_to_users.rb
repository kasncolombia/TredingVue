class AddSubscriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pro_status, :boolean, default: false, null: false
    add_column :users, :subscription_expires_at, :datetime
    add_column :users, :paypal_subscription_id, :string
  end
end
