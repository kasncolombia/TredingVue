class CreateReviewRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :review_requests do |t|
      t.references :requester, null: false, foreign_key: true
      t.references :mentor, null: false, foreign_key: true
      t.references :trade, null: false, foreign_key: true
      t.text :message
      t.string :status

      t.timestamps
    end
  end
end
