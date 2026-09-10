class Strategy < ApplicationRecord
  belongs_to :user
  has_many :trades, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :user_id }
end
