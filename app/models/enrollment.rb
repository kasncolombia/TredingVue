class Enrollment < ApplicationRecord
  belongs_to :classroom
  belongs_to :user

  validates :classroom_id, uniqueness: { scope: :user_id }
end