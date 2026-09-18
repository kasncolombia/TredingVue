class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed

  STEPS = %w[paso_1 paso_2 paso_3].freeze

  def paso_1; end

  def paso_2
    # Necesita el tipo de trader del paso 1
    if params[:user].blank? || params[:user][:trader_type].blank?
      redirect_to onboarding_paso_1_path, alert: "Por favor selecciona tu tipo de trader."
      return
    end
    session[:onboarding] ||= {}
    session[:onboarding][:trader_type] = params[:user][:trader_type]
  end

  def paso_3
    if params[:user].blank? || params[:user][:main_market].blank?
      redirect_to onboarding_paso_2_path, alert: "Por favor selecciona tu mercado principal."
      return
    end
    session[:onboarding] ||= {}
    session[:onboarding][:main_market] = params[:user][:main_market]
  end

  def completar
    if params[:user].blank? || params[:user][:trading_goal].blank?
      redirect_to onboarding_paso_3_path, alert: "Por favor selecciona tu objetivo."
      return
    end

    session[:onboarding] ||= {}
    session[:onboarding][:trading_goal] = params[:user][:trading_goal]

    if current_user.update(
      trader_type:          session[:onboarding][:trader_type],
      main_market:          session[:onboarding][:main_market],
      trading_goal:         session[:onboarding][:trading_goal],
      onboarding_completed: true
    )
      session.delete(:onboarding)
      redirect_to dashboard_path, notice: "¡Bienvenido a CoachTrading PRO! Tu perfil de trader está configurado. 🚀"
    else
      redirect_to onboarding_paso_3_path, alert: "No se pudo guardar tu perfil. Inténtalo de nuevo."
    end
  end

  private

  def redirect_if_completed
    redirect_to dashboard_path if current_user&.onboarding_completed?
  end
end
