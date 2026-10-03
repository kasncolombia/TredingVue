import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    this.handleKeyDown = this.handleKeyDown.bind(this)
    window.addEventListener("keydown", this.handleKeyDown)
    
    // Asignar funciones globales para compatibilidad retroactiva si algún botón usa onclick inline
    if (this.element.id) {
      const modalId = this.element.id
      const camelCaseId = modalId.replace(/-([a-z])/g, (_, g) => g.toUpperCase())
      const pascalCaseId = camelCaseId.charAt(0).toUpperCase() + camelCaseId.slice(1)

      window[`open_${modalId}`] = () => this.open()
      window[`close_${modalId}`] = () => this.close()
      window[`open${pascalCaseId}`] = () => this.open()
      window[`close${pascalCaseId}`] = () => this.close()
    }
  }

  disconnect() {
    window.removeEventListener("keydown", this.handleKeyDown)
  }

  open() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("hidden")
    } else {
      this.element.classList.remove("hidden")
    }
  }

  close() {
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add("hidden")
    } else {
      this.element.classList.add("hidden")
    }
  }

  closeOnBackdrop(event) {
    if (event.target === event.currentTarget) {
      this.close()
    }
  }

  handleKeyDown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
