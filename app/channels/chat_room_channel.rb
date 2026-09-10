class ChatRoomChannel < ApplicationCable::Channel
  def subscribed
    @chat_room = ChatRoom.find(params[:id])
    stream_for @chat_room
  end

  def unsubscribed
    stop_all_streams
  end

  def speak(data)
    @chat_room = ChatRoom.find(params[:id])
    message = @chat_room.messages.create!(
      user: current_user,
      content: data["message"]
    )
    ActionCable.server.broadcast("chat_room_#{@chat_room.id}",
      message: render_message(message),
      chat_room_id: @chat_room.id
    )
  end

  private

  def render_message(message)
    ApplicationController.render(
      partial: "messages/message",
      locals: { message: message }
    )
  end
end