module Community
  class ReviewRequestsController < ApplicationController
    before_action :authenticate_user!

    def index
      @requests_as_requester = current_user.review_requests_as_requester.includes(:mentor, :trade).recent
      @requests_as_mentor = current_user.review_requests_as_mentor.includes(:requester, :trade).recent
    end

    def create
      @request = current_user.review_requests_as_requester.build(review_request_params)
      @request.status = "pending"
      if @request.save
        redirect_to community_review_requests_path, notice: "Solicitud de revisión enviada"
      else
        @trades = current_user.trades
        render :new
      end
    end

    def new
      @request = current_user.review_requests_as_requester.build
      @trades = current_user.trades
      @mentors = User.where.not(id: current_user.id).limit(20)
    end

    def update
      @request = ReviewRequest.find(params[:id])
      @request.update!(review_request_update_params)
      redirect_to community_review_requests_path, notice: "Solicitud actualizada"
    end

    def destroy
      @request = current_user.review_requests_as_requester.find(params[:id])
      @request.destroy
      redirect_to community_review_requests_path, notice: "Solicitud eliminada"
    end

    private

    def review_request_params
      params.require(:review_request).permit(:mentor_id, :trade_id, :message)
    end

    def review_request_update_params
      params.require(:review_request).permit(:status)
    end
  end
end