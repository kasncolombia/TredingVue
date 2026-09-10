import { createConsumer } from "@hotwired/turbo-rails"
import consumer from "./consumer"

consumer.subscriptions.create({ channel: "ChatRoomChannel", id: document.querySelector("[data-chat-room-id]")?.dataset.chatRoomId }, {
  connected() {
    console.log("Connected to chat room")
  },
  disconnected() {
    console.log("Disconnected from chat room")
  },
  received(data) {
    const messagesContainer = document.getElementById("chat-messages")
    if (messagesContainer) {
      messagesContainer.insertAdjacentHTML("beforeend", data.message)
      messagesContainer.scrollTop = messagesContainer.scrollHeight
    }
  }
})