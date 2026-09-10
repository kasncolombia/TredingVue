module Community
  class ChatRoomsController < ApplicationController
    before_action :authenticate_user!

    def index
      @chat_rooms = ChatRoom.all
      @chat_room = ChatRoom.find_or_create_by(name: "General")
      @messages = @chat_room.messages.includes(:user).order(created_at: :asc).last(50)
      @new_message = @chat_room.messages.build
    end

    def show
      @chat_room = ChatRoom.find(params[:id])
      @messages = @chat_room.messages.includes(:user).order(created_at: :asc).limit(50)
      @new_message = @chat_room.messages.build
    end

    def new
      @chat_room = ChatRoom.new
    end

    def create
      @chat_room = ChatRoom.find_or_create_by(name: params[:chat_room][:name])
      redirect_to community_chat_room_path(@chat_room)
    end

    private

    def chat_room_params
      params.require(:chat_room).permit(:name)
    end
  end
end