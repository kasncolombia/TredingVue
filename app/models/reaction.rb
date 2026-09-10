class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :reaction_type, inclusion: { in: %w[like heart fire celebrate] }
  validates :user_id, uniqueness: { scope: :post_id }
end