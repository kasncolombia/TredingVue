class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :timezone, :preferred_currency, :initial_capital])
  end

  def require_pro!
    unless current_user&.pro?
      redirect_to new_subscription_path, alert: "El AI Coach es exclusivo para usuarios PRO. Por favor actualiza tu membresía."
    end
  end
end

module Community
  class ApplicationController < ::ApplicationController
    layout "application"
  end
end