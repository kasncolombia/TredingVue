class AiCoachController < ApplicationController
  before_action :require_pro!
  
  def show
    @stats          = Trading::CalculateStatistics.new(current_user.trades).call
    @recent_trade   = current_user.trades.recent.first
    @last_analysis  = @recent_trade&.ai_analyses&.last
    @conversation   = current_user.ai_conversations.last ||
                      current_user.ai_conversations.create!(title: "Sesión de Coaching")
    @messages       = @conversation.ai_messages.order(:created_at)
  end

  def analyze_trade
    trade  = current_user.trades.find(params[:trade_id])
    stats  = Trading::CalculateStatistics.new(current_user.trades).call
    coach  = Ai::TradingCoach.new(current_user, stats)
    result = coach.evaluate_trade(trade)

    AiAnalysis.create!(
      trade:              trade,
      user:               current_user,
      discipline_score:   result[:score],
      pattern_detected:   result[:pattern],
      feedback:           result[:feedback],
      reflection_question: result[:reflection]
    )

    render json: result
  end

  def chat
    question     = params[:message].to_s.strip
    stats        = Trading::CalculateStatistics.new(current_user.trades).call
    coach        = Ai::TradingCoach.new(current_user, stats)
    reply        = coach.ask(question)

    conversation = current_user.ai_conversations.last ||
                   current_user.ai_conversations.create!(title: "Sesión de Coaching")

    conversation.ai_messages.create!(role: "user",      content: question)
    conversation.ai_messages.create!(role: "assistant", content: reply)

    render json: { message: reply }
  end
end
