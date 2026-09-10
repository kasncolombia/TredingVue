class FixCommunityForeignKeys < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    execute("PRAGMA foreign_keys=OFF")
    remove_foreign_key :classrooms, :authors
    add_foreign_key :classrooms, :users, column: :author_id

    remove_foreign_key :resources, :authors
    add_foreign_key :resources, :users, column: :author_id

    remove_foreign_key :review_requests, :mentors
    remove_foreign_key :review_requests, :requesters
    add_foreign_key :review_requests, :users, column: :mentor_id
    add_foreign_key :review_requests, :users, column: :requester_id
    execute("PRAGMA foreign_keys=ON")
  end
end
