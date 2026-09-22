class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { user: "user", admin: "admin" }

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
  has_many :prop_transactions, dependent: :destroy
  has_many :prop_firm_accounts, dependent: :destroy
  has_many :trading_accounts, dependent: :destroy
  has_many :backtest_sessions, dependent: :destroy

  has_many :enrollments,       dependent: :destroy

  validates :email, presence: true, uniqueness: true

  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :send_welcome_notification

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

  private

  def send_welcome_notification
    notifications.create!(
      title: "¡Bienvenido a CoachTrading PRO! 🚀",
      message: "Tu plataforma de trading asistida por IA está lista. Configura tus estrategias, importa tu historial CSV o consulta a tu AI Coach para comenzar.",
      category: "system"
    )
  rescue => e
    Rails.logger.error "Error al crear notificación de bienvenida: #{e.message}"
  end
end