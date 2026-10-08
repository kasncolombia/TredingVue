import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  toggle() {
    const input = this.inputTarget
    const icon = this.iconTarget

    if (input.type === "password") {
      input.type = "text"
      icon.textContent = "visibility_off"
    } else {
      input.type = "password"
      icon.textContent = "visibility"
    }
  }
}
