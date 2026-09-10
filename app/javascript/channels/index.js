import consumer from "./consumer"
import { createConsumer } from "@hotwired/turbo-rails"

const consumer = createConsumer()

document.addEventListener("turbo:load", () => {
  const chatRoomId = document.querySelector("[data-chat-room-id]")?.dataset.chatRoomId
  if (!chatRoomId) return

  const channel = consumer.subscriptions.create({ channel: "ChatRoomChannel", id: chatRoomId }, {
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
})