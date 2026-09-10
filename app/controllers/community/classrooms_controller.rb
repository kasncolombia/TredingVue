module Community
  class ClassroomsController < ApplicationController
    before_action :authenticate_user!

    def index
      @classrooms = Classroom.all.includes(:author).recent.limit(20)
    end

    def show
      @classroom = Classroom.includes(:author).find(params[:id])
      @enrollments = @classroom.enrollments.includes(:user).limit(50)
    end

    def new
      @classroom = current_user.classrooms.build
    end

    def create
      @classroom = current_user.classrooms.build(classroom_params)
      if @classroom.save
        redirect_to community_classrooms_path, notice: "Clase creada"
      else
        @classrooms = Classroom.all
        render :index
      end
    end

    def enroll
      @classroom = Classroom.find(params[:id])
      @classroom.enrollments.find_or_create_by(user: current_user)
      redirect_to community_classroom_path(@classroom), notice: "Inscrito en la clase"
    end

    private

    def classroom_params
      params.require(:classroom).permit(:title, :description, :category)
    end
  end
end