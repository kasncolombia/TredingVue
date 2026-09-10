class ReviewRequest < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :mentor, class_name: "User"
  belongs_to :trade

  validates :message, presence: true, length: { maximum: 2000 }
  validates :status, inclusion: { in: %w[pending accepted completed rejected] }

  scope :recent, -> { order(created_at: :desc) }
end