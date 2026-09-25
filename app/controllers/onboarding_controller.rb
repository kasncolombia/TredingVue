class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed
  layout 'onboarding'

  def index
  end

  def completar
    intentions = params[:intentions] || []
    markets = params[:markets] || []
    experience = params[:experience]

    if current_user.update(
      trading_goal: intentions.join(','),
      main_market: markets.join(','),
      trader_type: experience,
      onboarding_completed: true
    )
      render json: { success: true }
    else
      render json: { success: false, errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_completed
    # Ignorar si estamos en la acción completar y ya se completó (para evitar redirect ajax)
    return if action_name == 'completar' && current_user&.onboarding_completed?
    redirect_to dashboard_path if current_user&.onboarding_completed?
  end
end
