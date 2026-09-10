class Resource < ApplicationRecord
  belongs_to :author, class_name: "User"

  validates :title, presence: true, length: { maximum: 200 }
  validates :url, presence: true
  validates :category, inclusion: { in: %w[book video article podcast course] }

  scope :recent, -> { order(created_at: :desc) }
end