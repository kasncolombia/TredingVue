import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 
    "step", "backButton", "nextButton", "submitButton", 
    "intention", "market", "experience",
    "progressContainer", "progressText", "progressBar",
    "submitText", "submitSpinner",
    "multipleSelectionList", "multipleSelectionOptions"
  ]
  
  static values = {
    wizardUrl: String,
    backtesterUrl: String,
    journalUrl: String,
    dashboardUrl: String
  }

  connect() {
    this.currentStepIndex = 0
    // Load progress if abandoned
    const savedStep = localStorage.getItem("onboarding_step")
    if (savedStep && parseInt(savedStep) > 0 && parseInt(savedStep) < 4) {
      this.currentStepIndex = parseInt(savedStep)
    }
    this.showCurrentStep(false)
  }

  next() {
    this.currentStepIndex++
    localStorage.setItem("onboarding_step", this.currentStepIndex)
    this.showCurrentStep()
  }

  back() {
    if (this.currentStepIndex > 0) {
      this.currentStepIndex--
      localStorage.setItem("onboarding_step", this.currentStepIndex)
      this.showCurrentStep()
    }
  }

  showCurrentStep(animate = true) {
    this.stepTargets.forEach(step => {
      // Hide all steps
      step.classList.add("hidden", "opacity-0", "translate-y-4")
      // Force remove display flex to correctly hide
      if(step.classList.contains("flex")) {
          step.style.display = 'none';
      }
      step.classList.remove("opacity-100", "translate-y-0", "flex")
    })

    // Show current step
    const currentStep = this.stepTargets.find(s => parseInt(s.dataset.step) === this.currentStepIndex)
    if (currentStep) {
      currentStep.classList.remove("hidden")
      currentStep.classList.add("flex")
      currentStep.style.display = ''; // Clear inline block constraints

      if (animate) {
        setTimeout(() => {
          currentStep.classList.remove("opacity-0", "translate-y-4")
          currentStep.classList.add("opacity-100", "translate-y-0")
        }, 30)
      } else {
        currentStep.classList.remove("opacity-0", "translate-y-4")
        currentStep.classList.add("opacity-100", "translate-y-0")
      }
    }

    // Toggle Back Button
    if (this.currentStepIndex > 0 && this.currentStepIndex < 4) {
      this.backButtonTarget.classList.remove("hidden")
    } else {
      this.backButtonTarget.classList.add("hidden")
    }

    // Update Progress Indicator
    if (this.currentStepIndex >= 1 && this.currentStepIndex <= 3) {
      this.progressContainerTarget.classList.remove("hidden")
      this.progressContainerTarget.classList.add("flex")
      
      setTimeout(() => {
        this.progressContainerTarget.classList.remove("opacity-0")
        this.progressContainerTarget.classList.add("opacity-100")
      }, 30)

      if (this.hasProgressTextTarget) {
        this.progressTextTarget.textContent = this.currentStepIndex
      }
      if (this.hasProgressBarTarget) {
        const percentage = (this.currentStepIndex / 3) * 100
        this.progressBarTarget.style.width = `${percentage}%`
      }
    } else {
      this.progressContainerTarget.classList.add("opacity-0")
      this.progressContainerTarget.classList.remove("opacity-100")
      setTimeout(() => {
        this.progressContainerTarget.classList.add("hidden")
        this.progressContainerTarget.classList.remove("flex")
      }, 300)
    }

    this.checkInputs() // Check valid state for this step
  }

  updateNextButton() {
    this.checkInputs()
  }

  checkInputs() {
    let isValid = false
    
    if (this.currentStepIndex === 1) {
      isValid = this.intentionTargets.some(i => i.checked)
    } else if (this.currentStepIndex === 2) {
      isValid = this.marketTargets.some(i => i.checked)
    } else if (this.currentStepIndex === 3) {
      isValid = this.experienceTargets.some(i => i.checked)
    }

    // Buttons for index 1 and 2
    if (this.currentStepIndex >= 1 && this.currentStepIndex <= 2) {
      const currentNextButton = this.nextButtonTargets[this.currentStepIndex - 1]
      if (currentNextButton) {
        if (isValid) {
          currentNextButton.disabled = false
          currentNextButton.classList.remove("bg-gray-700", "cursor-not-allowed", "opacity-50")
          currentNextButton.classList.add("bg-[#009DFA]", "hover:bg-blue-600", "shadow-[0_0_20px_rgba(0,157,250,0.4)]")
        } else {
          currentNextButton.disabled = true
          currentNextButton.classList.add("bg-gray-700", "cursor-not-allowed", "opacity-50")
          currentNextButton.classList.remove("bg-[#009DFA]", "hover:bg-blue-600", "shadow-[0_0_20px_rgba(0,157,250,0.4)]")
        }
      }
    }

    if (this.currentStepIndex === 3) {
      const submitBtn = this.submitButtonTarget
      if (isValid) {
        submitBtn.disabled = false
        submitBtn.classList.remove("bg-gray-700", "cursor-not-allowed", "opacity-50")
        submitBtn.classList.add("bg-[#009DFA]", "hover:bg-blue-600", "shadow-[0_0_20px_rgba(0,157,250,0.4)]")
      } else {
        submitBtn.disabled = true
        submitBtn.classList.add("bg-gray-700", "cursor-not-allowed", "opacity-50")
        submitBtn.classList.remove("bg-[#009DFA]", "hover:bg-blue-600", "shadow-[0_0_20px_rgba(0,157,250,0.4)]")
      }
    }
  }

  async submit(e) {
    if (e) e.preventDefault()

    const intentions = this.intentionTargets.filter(i => i.checked).map(i => i.value)
    const markets = this.marketTargets.filter(i => i.checked).map(i => i.value)
    const experience = this.experienceTargets.find(i => i.checked)?.value

    // disable and spinner
    this.submitButtonTarget.disabled = true
    this.submitTextTarget.classList.add("opacity-0")
    this.submitSpinnerTarget.classList.remove("hidden")

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']").content

      const response = await fetch("/onboarding/completar", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          intentions,
          markets,
          experience
        })
      })

      if (response.ok) {
        localStorage.removeItem("onboarding_step")
        
        // Show step 4 ("Perfecto...")
        this.currentStepIndex = 4
        this.showCurrentStep()
        
        setTimeout(() => {
          // Mostrar SIEMPRE la pantalla final de selección de módulos (Paso 5)
          const validIntentions = intentions.length > 0 ? intentions : ["Prop Firms", "Backtesting", "Journal & Analytics"]
          this.buildMultipleSelectionOptions(validIntentions)
          this.currentStepIndex = 5
          this.showCurrentStep()
        }, 1500)
      } else {
        alert("Ocurrió un error al guardar tu perfil.")
        this.resetSubmitButton()
      }
    } catch (error) {
      console.error(error)
      alert("Error de conexión.")
      this.resetSubmitButton()
    }
  }
  
  resetSubmitButton() {
      this.submitButtonTarget.disabled = false
      this.submitTextTarget.classList.remove("opacity-0")
      this.submitSpinnerTarget.classList.add("hidden")
  }

  buildMultipleSelectionOptions(intentions) {
    this.multipleSelectionListTarget.innerHTML = intentions.map(i => `<span class="flex items-center"><svg class="w-4 h-4 mr-1 text-[#009DFA]" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>${i}</span>`).join('<span class="mx-2 text-gray-600">|</span>')
    
    let buttonsHtml = ""
    
    intentions.forEach(intention => {
      let url = ""
      let icon = ""
      let title = ""
      
      if (intention === "Prop Firms") {
        url = this.wizardUrlValue
        icon = "🏦"
        title = "Configurar Prop Firms"
      } else if (intention === "Backtesting") {
        url = this.backtesterUrlValue
        icon = "📊"
        title = "Crear Backtesting"
      } else if (intention === "Journal & Analytics") {
        url = this.journalUrlValue
        icon = "📓"
        title = "Ir a mi Journal"
      }

      if (url) {
        buttonsHtml += `
          <a href="${url}" class="p-4 rounded-xl border border-gray-700 bg-gray-800/50 hover:bg-[#009DFA]/10 hover:border-[#009DFA] transition-all duration-200 flex items-center group w-full">
            <div class="text-2xl mr-4 group-hover:scale-110 transition-transform">${icon}</div>
            <div class="flex-1 font-semibold text-white group-hover:text-[#009DFA] transition-colors">${title}</div>
            <svg class="w-6 h-6 text-gray-500 group-hover:text-[#009DFA] transform group-hover:translate-x-1 transition-all" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path></svg>
          </a>
        `
      }
    })

    buttonsHtml += `
      <a href="${this.dashboardUrlValue}" class="p-4 rounded-xl border border-transparent hover:bg-gray-800 text-gray-400 hover:text-white transition-all duration-200 flex items-center justify-center mt-2 group w-full">
        <span class="mr-2">O continuar al Dashboard</span>
        <svg class="w-4 h-4 transform group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path></svg>
      </a>
    `

    this.multipleSelectionOptionsTarget.innerHTML = buttonsHtml
  }
}
