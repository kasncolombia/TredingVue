class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def new
    # Checkout Page View
  end

  def create
    # Simulador de Pago PayPal Exitoso
    current_user.update!(
      pro_status: true,
      subscription_expires_at: 1.month.from_now,
      paypal_subscription_id: "SIM-PAYPAL-#{SecureRandom.hex(6).upcase}"
    )
    redirect_to dashboard_path, notice: "¡Pago exitoso! Bienvenido a CoachTrading PRO. Tus funcionalidades están desbloqueadas."
  end

  def destroy
    # Simulador de Cancelación
    current_user.update!(pro_status: false, paypal_subscription_id: nil)
    redirect_to profile_path, alert: "Membresía PRO cancelada con éxito."
  end
end
