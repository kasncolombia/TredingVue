class ProToolsController < ApplicationController
  before_action :authenticate_user!

  def index
    @active_tab = params[:tab].presence || "backtest"

    # --- BACKTEST TAB DATA ---
    @sessions     = current_user.backtest_sessions.where(session_type: "backtest").recent
    @new_session  = current_user.backtest_sessions.new(session_type: "backtest")
    @strategies   = current_user.strategies
    @prop_firms   = BacktestSession::PROP_FIRMS

    # --- PROP FIRM TAB DATA ---
    @prop_sessions     = current_user.backtest_sessions.where(session_type: "prop_firm").recent
    @new_prop_session  = current_user.backtest_sessions.new(session_type: "prop_firm")
    @transactions      = current_user.prop_transactions.order(transaction_date: :desc)
    @total_expenses    = current_user.prop_transactions.total_expenses
    @total_payouts     = current_user.prop_transactions.total_payouts
    @net_profit        = current_user.prop_transactions.net_profit
    @roi               = current_user.prop_transactions.roi_percentage
    @new_transaction   = current_user.prop_transactions.new
  end
end
