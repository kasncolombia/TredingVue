import { Controller } from "@hotwired/stimulus"

// Intro por pasos para páginas completas (Prop Firms, Backtesting, etc.)
export default class extends Controller {
  static targets = ["step", "dot", "bar", "prev", "next", "counter"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.onKey = (e) => {
      if (e.key === "ArrowRight") this.next()
      if (e.key === "ArrowLeft") this.prev()
    }
    document.addEventListener("keydown", this.onKey)
    this.render()
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey)
  }

  next() {
    if (this.indexValue < this.stepTargets.length - 1) {
      this.indexValue++
      this.render()
    }
  }

  prev() {
    if (this.indexValue > 0) {
      this.indexValue--
      this.render()
    }
  }

  goTo(event) {
    this.indexValue = parseInt(event.currentTarget.dataset.index, 10)
    this.render()
  }

  render() {
    const total = this.stepTargets.length
    const i = this.indexValue
    const last = i === total - 1

    this.stepTargets.forEach((el, idx) => {
      el.classList.toggle("hidden", idx !== i)
      el.classList.toggle("flex", idx === i)
    })

    this.dotTargets.forEach((dot, idx) => {
      dot.classList.toggle("w-6", idx === i)
      dot.classList.toggle("w-2", idx !== i)
      dot.classList.toggle("opacity-40", idx !== i)
    })

    this.prevTarget.classList.toggle("invisible", i === 0)
    this.nextTarget.classList.toggle("invisible", last)
    this.barTarget.style.width = `${((i + 1) / total) * 100}%`
    this.counterTarget.textContent = `${i + 1} / ${total}`
  }
}
