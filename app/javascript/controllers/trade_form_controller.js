import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modeSlider", "btnBeginner", "btnExpert",
    "coachTitle", "coachBeginner", "coachExpert", "hintExecution",
    "expertOnly", "symbolInput",
    "entryPrice", "exitPrice", "positionSize", "stopLoss", "actualPnl",
    "calcPnl", "calcR", "calcPct",
    "propFirmContainer", "selectedPropFirmInput", "propFirmChip"
  ]

  connect() {
    this.currentMode = "beginner"
    this.setMode("beginner")
    this.togglePropFirmSelector()
    this.calculate()
  }

  setBeginnerMode() {
    this.setMode("beginner")
  }

  setExpertMode() {
    this.setMode("expert")
  }

  setMode(mode) {
    this.currentMode = mode

    if (this.hasModeSliderTarget) {
      this.modeSliderTarget.style.transform = mode === "beginner" ? "translateX(0)" : "translateX(100%)"
    }

    if (this.hasBtnBeginnerTarget && this.hasBtnExpertTarget) {
      if (mode === "beginner") {
        this.btnBeginnerTarget.classList.add("text-brand")
        this.btnBeginnerTarget.classList.remove("text-slate-500", "dark:text-slate-400")
        this.btnExpertTarget.classList.add("text-slate-500", "dark:text-slate-400")
        this.btnExpertTarget.classList.remove("text-brand")
      } else {
        this.btnExpertTarget.classList.add("text-brand")
        this.btnExpertTarget.classList.remove("text-slate-500", "dark:text-slate-400")
        this.btnBeginnerTarget.classList.add("text-slate-500", "dark:text-slate-400")
        this.btnBeginnerTarget.classList.remove("text-brand")
      }
    }

    if (this.hasCoachTitleTarget) {
      this.coachTitleTarget.innerHTML = mode === "beginner" 
        ? "MODO BÁSICO ACTIVO" 
        : "MODO EXPERTO ACTIVO <span class='animate-pulse inline-block'>🔬</span>"
    }

    if (this.hasCoachBeginnerTarget && this.hasCoachExpertTarget) {
      if (mode === "beginner") {
        this.coachBeginnerTarget.classList.remove("hidden")
        this.coachExpertTarget.classList.add("hidden")
      } else {
        this.coachExpertTarget.classList.remove("hidden")
        this.coachBeginnerTarget.classList.add("hidden")
      }
    }

    if (this.hasHintExecutionTarget) {
      this.hintExecutionTarget.textContent = mode === "beginner"
        ? "Ingresa a qué precio compraste y vendiste."
        : "El sistema gestionará tamaño de contratos, fees y RR ratio matemáticamente."
    }

    this.expertOnlyTargets.forEach(el => {
      if (mode === "beginner") {
        el.classList.add("hidden")
      } else {
        el.classList.remove("hidden")
      }
    })

    if (mode === "beginner") {
      if (this.hasPositionSizeTarget) this.positionSizeTarget.value = 1
      if (this.hasStopLossTarget) this.stopLossTarget.value = ""
    }

    this.calculate()
  }

  selectSymbol(event) {
    const symbol = event.currentTarget.dataset.symbol
    if (symbol && this.hasSymbolInputTarget) {
      this.symbolInputTarget.value = symbol
      this.symbolInputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    }
  }

  togglePropFirmSelector() {
    if (!this.hasPropFirmContainerTarget) return

    const selectedRadio = this.element.querySelector('input[name="trade[portfolio_mode]"]:checked')
    if (selectedRadio && selectedRadio.value === "prop_firm") {
      this.propFirmContainerTarget.classList.remove("hidden")
    } else {
      this.propFirmContainerTarget.classList.add("hidden")
    }
  }

  selectPropFirm(event) {
    const name = event.currentTarget.dataset.firmName
    if (this.hasSelectedPropFirmInputTarget) {
      this.selectedPropFirmInputTarget.value = name
    }

    this.propFirmChipTargets.forEach(chip => {
      chip.classList.remove("ring-2", "ring-brand", "border-brand", "bg-brand/10")
    })

    event.currentTarget.classList.add("ring-2", "ring-brand", "border-brand", "bg-brand/10")
  }

  calculate() {
    const entry = parseFloat(this.hasEntryPriceTarget ? this.entryPriceTarget.value : 0) || 0
    const exit = parseFloat(this.hasExitPriceTarget ? this.exitPriceTarget.value : 0) || 0
    const size = parseFloat(this.hasPositionSizeTarget ? this.positionSizeTarget.value : 1) || 1
    const sl = parseFloat(this.hasStopLossTarget ? this.stopLossTarget.value : 0) || 0

    const directionEl = this.element.querySelector('input[name="trade[direction]"]:checked')
    const isLong = directionEl ? directionEl.value === "LONG" : true

    if (entry <= 0 || exit <= 0) return

    const pointsCaptured = isLong ? (exit - entry) : (entry - exit)
    const pnl = pointsCaptured * size

    let riskPoints = 0
    if (sl > 0) {
      riskPoints = isLong ? (entry - sl) : (sl - entry)
    }
    const riskDollar = riskPoints * size
    const r = (riskDollar > 0) ? (pnl / riskDollar).toFixed(2) + "R" : "—"

    const g = "text-emerald-500", rd = "text-rose-500", w = "text-slate-800 dark:text-white"

    if (this.hasCalcPnlTarget) {
      this.calcPnlTarget.textContent = (pnl >= 0 ? "+" : "") + "$" + pnl.toFixed(2)
      this.calcPnlTarget.className = "text-xl font-black font-mono transition-all " + (pnl >= 0 ? g : rd)
    }

    if (this.hasCalcPctTarget) {
      this.calcPctTarget.textContent = (pointsCaptured >= 0 ? "+" : "") + pointsCaptured.toFixed(2) + " pts"
      this.calcPctTarget.className = "text-xl font-black font-mono transition-all " + (pointsCaptured >= 0 ? g : rd)
    }

    if (this.hasCalcRTarget) {
      this.calcRTarget.textContent = r
      this.calcRTarget.className = "text-xl font-black font-mono transition-all " + w
    }

    if (this.hasActualPnlTarget && document.activeElement !== this.actualPnlTarget) {
      this.actualPnlTarget.value = pnl.toFixed(2)
    }
  }
}
