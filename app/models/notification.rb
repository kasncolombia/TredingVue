class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit do
    broadcast_prepend_to "notifications_#{user_id}",
                         target: "notifications_list",
                         partial: "notifications/notification",
                         locals: { notification: self }
                         
    broadcast_replace_to "notifications_#{user_id}",
                         target: "notifications_counter",
                         partial: "notifications/counter",
                         locals: { count: user.notifications.unread.count }
  end
end
