class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { user: "user", admin: "admin" }

  has_many :trades,           dependent: :destroy
  has_many :strategies,       dependent: :destroy
  has_many :ai_conversations, dependent: :destroy
  has_many :ai_analyses,      dependent: :destroy
  has_many :posts,            dependent: :destroy
  has_many :comments,         dependent: :destroy
  has_many :reactions,        dependent: :destroy
  has_many :trade_shares,     dependent: :destroy
  has_many :review_requests_as_requester, class_name: "ReviewRequest", foreign_key: "requester_id", dependent: :destroy
  has_many :review_requests_as_mentor,    class_name: "ReviewRequest", foreign_key: "mentor_id", dependent: :destroy
  has_many :classrooms,       dependent: :destroy
  has_many :resources,        dependent: :destroy
  has_many :chat_rooms,       dependent: :destroy
  has_many :notifications,    dependent: :destroy

  has_many :enrollments,       dependent: :destroy

  validates :email, presence: true, uniqueness: true

  scope :recent, -> { order(created_at: :desc) }

  def trade_count
    trades.count
  end

  def win_rate
    return 0.0 if trades.count == 0
    trades.where(result: "WIN").count.to_f / trades.count * 100
  end

  def total_pnl
    trades.sum(:pnl)
  end

  def pro?
    pro_status == true && (subscription_expires_at.nil? || subscription_expires_at > Time.current)
  end
end