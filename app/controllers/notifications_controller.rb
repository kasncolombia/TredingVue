class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications.recent.limit(20)
  end

  def mark_all_read
    current_user.notifications.unread.update_all(read: true)
    redirect_to request.referer || dashboard_path, notice: "Marcadas como leídas."
  end
end
