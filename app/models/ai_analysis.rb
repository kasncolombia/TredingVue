class AiAnalysis < ApplicationRecord
  belongs_to :trade
  belongs_to :user

  validates :discipline_score, numericality: { in: 1..10 }, allow_nil: true
end
