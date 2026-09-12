class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:landing]

  def landing
    if user_signed_in? && params[:force_landing].blank?
      redirect_to dashboard_path
    end
  end
end
