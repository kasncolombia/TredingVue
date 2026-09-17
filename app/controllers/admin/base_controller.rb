class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  layout "admin"

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acceso denegado. Se requieren permisos de administrador."
    end
  end
end
