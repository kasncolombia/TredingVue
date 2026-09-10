class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy

  validates :content, presence: true, length: { maximum: 2000 }
  validates :visibility, inclusion: { in: %w[public friends private] }
  validates :status, inclusion: { in: %w[active archived] }

  scope :active, -> { where(status: "active") }
  scope :public_posts, -> { where(visibility: "public", status: "active") }
  scope :recent, -> { order(created_at: :desc) }
end