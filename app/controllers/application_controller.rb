class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :ensure_onboarding_completed, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_wizard_data, if: :user_signed_in?

  private

  def set_wizard_data
    @brokers = Broker.order(:name)
    @prop_firm_accounts = current_user.prop_firm_accounts.order(created_at: :desc) if current_user
  end

  protected

  def ensure_onboarding_completed
    return unless user_signed_in?
    return if is_a?(OnboardingController) || is_a?(PagesController)

    unless current_user.onboarding_completed?
      redirect_to onboarding_paso_1_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :timezone, :preferred_currency, :initial_capital, :trader_type, :main_market, :trading_goal])
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