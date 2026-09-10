module Community
  class ResourcesController < ApplicationController
    before_action :authenticate_user!

    def index
      @resources = Resource.all.includes(:author).recent.limit(20)
    end

    def show
      @resource = Resource.includes(:author).find(params[:id])
    end

    def new
      @resource = current_user.resources.build
    end

    def create
      @resource = current_user.resources.build(resource_params)
      if @resource.save
        redirect_to community_resources_path, notice: "Recurso agregado"
      else
        @resources = Resource.all
        render :index
      end
    end

    private

    def resource_params
      params.require(:resource).permit(:title, :url, :category, :description)
    end
  end
end