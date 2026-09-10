class ChatRoom < ApplicationRecord
  has_many :messages, dependent: :destroy
  belongs_to :user, optional: true

  validates :name, presence: true, length: { maximum: 100 }
end