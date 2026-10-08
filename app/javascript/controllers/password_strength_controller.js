import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "badge", "bar", "chipLength", "chipComplexity", "chipSymbol"]

  connect() {
    this.check()
  }

  check() {
    const value = this.inputTarget.value
    
    // Validaciones
    const hasLength = value.length >= 8
    const hasComplexity = /[A-Z]/.test(value) && /[0-9]/.test(value)
    const hasSymbol = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]+/.test(value)

    // Actualizar Chips (Labels de requisitos)
    this.updateChip(this.chipLengthTarget, hasLength)
    this.updateChip(this.chipComplexityTarget, hasComplexity)
    this.updateChip(this.chipSymbolTarget, hasSymbol)

    // Calcular puntaje
    let score = -1
    if (value.length > 0) {
      score = 0
      if (hasLength) score++
      if (hasComplexity) score++
      if (hasSymbol) score++
    }

    // Actualizar Barras y Badge (Nivel de seguridad)
    this.updateStrengthUI(score)
  }

  updateChip(chip, isMet) {
    const icon = chip.querySelector('.material-symbols-outlined')
    const originalLabelText = chip.dataset.label
    
    if (isMet) {
      chip.className = 'inline-flex items-center gap-1 text-[10px] px-2.5 py-0.5 rounded-full font-medium bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/20'
      if (icon) icon.textContent = 'check_circle'
    } else {
      chip.className = 'inline-flex items-center gap-1 text-[10px] px-2.5 py-0.5 rounded-full font-medium bg-slate-100 dark:bg-white/5 text-slate-400 dark:text-slate-500 border border-slate-200 dark:border-white/10'
      if (icon) icon.textContent = 'radio_button_unchecked'
    }
  }

  updateStrengthUI(score) {
    const bars = this.barTargets
    
    // Reset all bars
    bars.forEach(bar => {
      bar.className = 'h-1.5 flex-1 rounded-full bg-slate-200 dark:bg-white/10 transition-colors'
    })

    if (score < 0) { // Empty input
      this.badgeTarget.className = 'px-2.5 py-0.5 rounded-full text-[10px] font-semibold border flex items-center gap-1 bg-slate-100 dark:bg-white/5 text-slate-500 dark:text-slate-400 border-slate-200 dark:border-white/10'
      this.badgeTarget.innerHTML = `<span class="material-symbols-outlined text-[13px]">lock</span> Ingresa tu clave`
      return
    }

    if (score === 0 || score === 1) { // 0 o 1 requisito cumplido
      bars[0].classList.replace('bg-slate-200', 'bg-rose-500')
      bars[0].classList.replace('dark:bg-white/10', 'bg-rose-500')
      if (score === 1) {
        bars[1].classList.replace('bg-slate-200', 'bg-rose-500')
        bars[1].classList.replace('dark:bg-white/10', 'bg-rose-500')
      }
      this.setBadgeStyle('text-rose-500', 'bg-rose-50', 'border-rose-200', 'dark:bg-rose-500/10', 'dark:border-rose-500/20', `<span class="material-symbols-outlined text-[13px]">warning</span> Débil`)
    } else if (score === 2) { // 2 requisitos cumplidos
      bars[0].classList.replace('bg-slate-200', 'bg-[#009DFA]')
      bars[0].classList.replace('dark:bg-white/10', 'bg-[#009DFA]')
      bars[1].classList.replace('bg-slate-200', 'bg-[#009DFA]')
      bars[1].classList.replace('dark:bg-white/10', 'bg-[#009DFA]')
      bars[2].classList.replace('bg-slate-200', 'bg-[#009DFA]')
      bars[2].classList.replace('dark:bg-white/10', 'bg-[#009DFA]')
      this.setBadgeStyle('text-[#009DFA]', 'bg-[#009DFA]/10', 'border-[#009DFA]/20', 'dark:bg-[#009DFA]/10', 'dark:border-[#009DFA]/20', `<span class="material-symbols-outlined text-[13px]">security</span> Buena`)
    } else if (score === 3) { // 3 requisitos cumplidos
      bars.forEach(bar => {
        bar.classList.replace('bg-slate-200', 'bg-emerald-500')
        bar.classList.replace('dark:bg-white/10', 'bg-emerald-500')
      })
      this.setBadgeStyle('text-emerald-500', 'bg-emerald-50', 'border-emerald-200', 'dark:bg-emerald-500/10', 'dark:border-emerald-500/20', `<span class="material-symbols-outlined text-[13px]">verified_user</span> Excelente`)
    }
  }

  setBadgeStyle(textColor, bgColor, borderColor, darkBgColor, darkBorderColor, innerHtml) {
    this.badgeTarget.className = `px-2.5 py-0.5 rounded-full text-[10px] font-semibold border flex items-center gap-1 ${textColor} ${bgColor} ${borderColor} ${darkBgColor} ${darkBorderColor}`
    this.badgeTarget.innerHTML = innerHtml
  }
}
