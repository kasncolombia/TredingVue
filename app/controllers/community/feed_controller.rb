module Community
  class FeedController < ApplicationController
    before_action :authenticate_user!

    def new
      @post = current_user.posts.build
    end

    def index
      @posts = Post.public_posts.recent.limit(20)
      @new_post = current_user.posts.build
      @trade_shares = current_user.trade_shares.where(privacy: "public").recent.limit(10)
    end

    def show
      @post = Post.find(params[:id])
      @comments = @post.comments.includes(:user).order(created_at: :asc)
      @new_comment = @post.comments.build
    end

    def create
      @post = current_user.posts.build(post_params)
      if @post.save
        redirect_to community_feed_index_path, notice: "Publicación creada"
      else
        @posts = Post.public_posts.recent
        render :index
      end
    end

    def destroy
      @post = current_user.posts.find(params[:id])
      @post.destroy
      redirect_to community_feed_index_path, notice: "Publicación eliminada"
    end

    private

    def post_params
      params.require(:post).permit(:content, :visibility)
    end
  end
end