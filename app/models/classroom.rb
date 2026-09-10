class Classroom < ApplicationRecord
  belongs_to :author, class_name: "User"
  has_many :enrollments, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :category, inclusion: { in: %w[beginner intermediate advanced] }

  scope :recent, -> { order(created_at: :desc) }
end