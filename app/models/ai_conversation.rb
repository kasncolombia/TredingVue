class AiConversation < ApplicationRecord
  belongs_to :user
  has_many :ai_messages, dependent: :destroy

  validates :title, presence: true
end
