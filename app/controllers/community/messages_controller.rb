module Community
  class MessagesController < ApplicationController
    before_action :authenticate_user!

    def index
      @chat_room = ChatRoom.find(params[:chat_room_id])
      @messages = @chat_room.messages.includes(:user).order(created_at: :asc).limit(50)
      @new_message = @chat_room.messages.build
    end

    def create
      @chat_room = ChatRoom.find(params[:chat_room_id])
      @message = @chat_room.messages.build(message_params.merge(user: current_user))
      if @message.save
        redirect_to community_chat_room_messages_path(@chat_room), notice: "Mensaje enviado"
      else
        @messages = @chat_room.messages.includes(:user).order(created_at: :asc).limit(50)
        render :index
      end
    end

    private

    def message_params
      params.require(:message).permit(:content)
    end
  end
end