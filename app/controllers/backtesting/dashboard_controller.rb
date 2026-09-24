module Backtesting
  class DashboardController < ApplicationController
    before_action :authenticate_user! # Assuming Devise

    def index
      @sessions = current_user.try(:backtest_sessions) || BacktestSession.all
      # We could calculate aggregate KPIs across sessions here for the dashboard
    end
  end
end
