module Backtesting
  class DashboardController < ApplicationController
    before_action :authenticate_user! # Assuming Devise

    def index
      @sessions = current_user.try(:backtest_sessions) || BacktestSession.all
      
      if @sessions.empty? && params[:skip_intro].blank?
        return redirect_to backtesting_intro_root_path
      end
    end

    def intro
    end
  end
end
