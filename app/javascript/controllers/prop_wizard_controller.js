import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initWizardGlobals();
    
    const hasErrors = this.element.dataset.hasFormErrors === 'true';
    if (hasErrors) {
      window.propWizardState.step = 3;
    } else {
      window.propWizardState = { step: 1, mode: 'preset', firm: 'Topstep', plan: 'Estándar', size: '50K', tab: 'step1', program_steps: 1 };
    }
    
    if (typeof window.initWizard === "function") {
      window.initWizard();
    }
  }

  initWizardGlobals() {
    window.RULES_DATABASE = {
      "10K":  { target: "$600",   max_dd: "$1,000 (EOD)", daily: "$500",  consistency: "50%", min_days: "2 días", steps: 1 },
      "25K":  { target: "$1,500", max_dd: "$1,500 (EOD)", daily: "$1,000", consistency: "50%", min_days: "2 días", steps: 1 },
      "50K":  { target: "$3,000", max_dd: "$2,000 (EOD)", daily: "$1,000", consistency: "50%", min_days: "2 días", steps: 1 },
      "100K": { target: "$6,000", max_dd: "$3,000 (EOD)", daily: "$2,000", consistency: "50%", min_days: "2 días", steps: 1 },
      "150K": { target: "$9,000", max_dd: "$4,500 (EOD)", daily: "$3,000", consistency: "50%", min_days: "2 días", steps: 1 },
      "200K": { target: "$12,000", max_dd: "$5,000 (EOD)", daily: "$4,000", consistency: "50%", min_days: "2 días", steps: 1 },
      "250K": { target: "$15,000", max_dd: "$6,000 (EOD)", daily: "$5,000", consistency: "50%", min_days: "2 días", steps: 1 }
    };

    if (typeof window.propWizardState === 'undefined') {
      window.propWizardState = { step: 1, mode: 'preset', firm: 'Topstep', plan: 'Estándar', size: '50K', tab: 'step1', program_steps: 1 };
    }

    window.setDisplay = function(el, show) {
      if (!el) return;
      if (show) {
        el.classList.remove("hidden");
        el.style.display = "block";
      } else {
        el.classList.add("hidden");
        el.style.display = "none";
      }
    };

    window.syncManualFirm = function(val) {
      const f = document.getElementById("prop_firm_name_field");
      if (f) f.value = val;
      window.propWizardState.firm = val || "Personalizada";
      window.updateRulesDisplay();
    };

    window.syncManualSize = function(val) {
      const s = document.getElementById("prop_account_size_field");
      if (s) s.value = val;
      window.propWizardState.size = val || "50K";
      window.updateRulesDisplay();
    };

    window.selectPropAccountMode = function(mode, cardEl) {
      window.propWizardState.mode = mode || "preset";
      const step2 = document.getElementById("wizard-step-2");
      if (step2) step2.setAttribute("data-mode", window.propWizardState.mode);

      document.querySelectorAll(".account-mode-card").forEach(c => {
        c.classList.remove("active", "border-brand", "ring-4", "ring-brand/10");
        c.classList.add("border-slate-200", "dark:border-darkBorder");
      });
      if (cardEl) {
        cardEl.classList.add("active", "border-brand", "ring-4", "ring-brand/10");
        cardEl.classList.remove("border-slate-200", "dark:border-darkBorder");
      }

      const label2 = document.getElementById("step-label-2");
      if (label2) {
        if (mode === "preset") label2.textContent = "Firma & Reglas";
        else if (mode === "manual") label2.textContent = "Reglas Manuales";
        else if (mode === "csv") label2.textContent = "Adjuntar CSV";
      }

      window.goToStep(2);
    };

    window.goToStep = function(stepNum) {
      stepNum = parseInt(stepNum) || 1;
      if (stepNum < 1) stepNum = 1;
      if (stepNum > 3) stepNum = 3;

      if (window.propWizardState.mode === "manual") {
        const mf = document.getElementById("manual-firm-input");
        const ms = document.getElementById("manual-size-input");
        if (mf && mf.value.trim()) window.syncManualFirm(mf.value.trim());
        if (ms && ms.value.trim()) window.syncManualSize(ms.value.trim());
      }

      window.propWizardState.step = stepNum;

      window.setDisplay(document.getElementById("wizard-step-1"), stepNum === 1);
      window.setDisplay(document.getElementById("wizard-step-2"), stepNum === 2);
      window.setDisplay(document.getElementById("wizard-step-3"), stepNum === 3);

      if (stepNum === 2) {
        window.setDisplay(document.getElementById("mode-panel-preset"), window.propWizardState.mode === "preset");
        window.setDisplay(document.getElementById("mode-panel-manual"), window.propWizardState.mode === "manual");
        window.setDisplay(document.getElementById("mode-panel-csv"),    window.propWizardState.mode === "csv");
      }

      const progressBar = document.getElementById("stepper-progress-bar");
      if (progressBar) progressBar.style.width = (((stepNum - 1) / 2) * 100) + "%";

      for (let i = 1; i <= 3; i++) {
        const node = document.getElementById("step-node-" + i);
        const label = document.getElementById("step-label-" + i);
        if (!node) continue;
        if (i <= stepNum) {
          node.className = "w-10 h-10 rounded-full bg-brand text-white font-extrabold text-sm flex items-center justify-center shadow-md ring-4 ring-brand/20 transition-all";
          if (label) label.className = "text-xs font-bold text-brand transition-colors";
        } else {
          node.className = "w-10 h-10 rounded-full bg-slate-200 dark:bg-darkBorder text-slate-500 font-extrabold text-sm flex items-center justify-center transition-all";
          if (label) label.className = "text-xs font-bold text-slate-400 transition-colors";
        }
      }

      try {
        const formEl = document.getElementById("onboarding-wizard-form");
        if (formEl && stepNum > 1) {
          formEl.scrollIntoView({ behavior: "smooth", block: "start" });
        }
      } catch(e) {}
    };

    window.nextStep = function() { window.goToStep(window.propWizardState.step + 1); };
    window.prevStep = function() { window.goToStep(window.propWizardState.step - 1); };

    window.selectFirmConfig = function(firmName, btn) {
      window.propWizardState.firm = firmName;
      const f = document.getElementById("prop_firm_name_field");
      if (f) f.value = firmName;
      document.querySelectorAll(".firm-selector-btn").forEach(b =>
        b.classList.remove("ring-2", "ring-brand", "border-brand", "bg-brand/10")
      );
      if (btn) btn.classList.add("ring-2", "ring-brand", "border-brand", "bg-brand/10");
      const lbl = document.getElementById("firm-plan-label");
      if (lbl) lbl.textContent = `2 - CONFIGURACIÓN DE PLAN DE ${firmName.toUpperCase()}`;
      
      // Auto toggle FTMO / 2-Step
      if (firmName.toLowerCase().includes("ftmo")) {
        window.propWizardState.program_steps = 2;
      } else {
        window.propWizardState.program_steps = 1;
      }

      window.updateRulesDisplay();
    };

    window.setPlanType = function(planType, btn) {
      window.propWizardState.plan = planType;
      const p = document.getElementById("prop_plan_name_field");
      if (p) p.value = planType;
      document.querySelectorAll(".plan-type-btn").forEach(b =>
        b.classList.remove("ring-2", "ring-brand", "border-brand", "bg-brand/10")
      );
      if (btn) btn.classList.add("ring-2", "ring-brand", "border-brand", "bg-brand/10");
      window.updateRulesDisplay();
    };

    window.setAccountSize = function(size, btn) {
      window.propWizardState.size = size;
      const s = document.getElementById("prop_account_size_field");
      if (s) s.value = size;
      document.querySelectorAll(".size-btn").forEach(b =>
        b.classList.remove("ring-2", "ring-brand", "border-brand", "bg-brand/10")
      );
      if (btn) btn.classList.add("ring-2", "ring-brand", "border-brand", "bg-brand/10");
      
      // Sync modal size input
      const mInput = document.getElementById("modal-account-size-input");
      if (mInput) {
        const raw = size.includes("K") ? parseFloat(size) * 1000 : parseFloat(size);
        mInput.value = raw;
      }

      window.updateRulesDisplay();
    };

    window.setAccountPhase = function(phaseId, btn) {
      const p = document.getElementById("prop_phase_field");
      if (p) p.value = phaseId;
      document.querySelectorAll(".phase-btn").forEach(b =>
        b.classList.remove("ring-2", "ring-emerald-500", "border-emerald-500", "bg-emerald-500/10", "text-emerald-500")
      );
      if (btn) btn.classList.add("ring-2", "ring-emerald-500", "border-emerald-500", "bg-emerald-500/10", "text-emerald-500");
    };

    window.setAccountStatus = function(statusId, btn) {
      const s = document.getElementById("prop_status_field");
      if (s) s.value = statusId;
      document.querySelectorAll(".status-btn").forEach(b =>
        b.classList.remove("ring-2", "ring-emerald-500", "border-emerald-500", "bg-emerald-500/10", "text-emerald-500")
      );
      if (btn) btn.classList.add("ring-2", "ring-emerald-500", "border-emerald-500", "bg-emerald-500/10", "text-emerald-500");

      const burnContainer = document.getElementById("burn-reason-container");
      const burnSelect = document.getElementById("burn_reason_select");
      if (burnContainer) {
        if (statusId === "quemada") {
          burnContainer.classList.remove("hidden");
          if (burnSelect) burnSelect.required = true;
        } else {
          burnContainer.classList.add("hidden");
          if (burnSelect) {
            burnSelect.required = false;
            burnSelect.value = "";
          }
        }
      }
    };

    window.switchRuleTab = function(tabName, btn) {
      window.propWizardState.tab = tabName;
      document.querySelectorAll(".rule-tab-btn").forEach(b => {
        b.classList.remove("bg-white", "dark:bg-slate-700", "text-brand", "shadow-xs");
        b.classList.add("text-slate-400");
      });
      if (btn) {
        btn.classList.add("bg-white", "dark:bg-slate-700", "text-brand", "shadow-xs");
        btn.classList.remove("text-slate-400");
      }
      window.updateRulesDisplay();
    };

    window.updateRulesDisplay = function() {
      const title = document.getElementById("rules-box-title");
      if (title) title.textContent = `3 - REGLAS: ${(window.propWizardState.firm || 'TOPSTEP').toUpperCase()} (${window.propWizardState.size})`;

      const isTwoStep = window.propWizardState.program_steps === 2;
      const tabStep2Btn = document.getElementById("rule-tab-step2");
      const detailsStep2 = document.getElementById("details-step2");
      const phaseBtnStep2 = document.getElementById("phase-btn-paso_2");

      if (tabStep2Btn) {
        if (isTwoStep) tabStep2Btn.classList.remove("hidden");
        else tabStep2Btn.classList.add("hidden");
      }
      if (detailsStep2) {
        if (isTwoStep) detailsStep2.classList.remove("hidden");
        else detailsStep2.classList.add("hidden");
      }
      if (phaseBtnStep2) {
        if (isTwoStep) phaseBtnStep2.classList.remove("hidden");
        else phaseBtnStep2.classList.add("hidden");
      }

      // Read from modal inputs if present
      const targetVal = document.getElementById("step1_profit_val")?.value || "3000";
      const targetUnit = document.getElementById("step1_profit_unit")?.value || "$";
      const ddVal = document.getElementById("step1_dd_val")?.value || "2000";
      const ddType = document.getElementById("step1_dd_type")?.value || "eod";
      const ddFloor = document.getElementById("step1_dd_floor")?.value || "initial_balance";
      const dailyVal = document.getElementById("step1_daily_val")?.value || "1000";
      const dailyEnabled = document.getElementById("step1_daily_enabled")?.checked;
      const consVal = document.getElementById("step1_consistency_pct")?.value || "50";
      const consEnabled = document.getElementById("step1_consistency_enabled")?.checked;
      const minDaysVal = document.getElementById("step1_min_days")?.value || "2";
      const unlimitedVal = document.getElementById("step1_unlimited")?.checked;

      const elTarget = document.getElementById("rule-target");
      const elMaxDD  = document.getElementById("rule-max-dd");
      const elDaily  = document.getElementById("rule-daily-loss");
      const elCons   = document.getElementById("rule-consistency");
      const elMinDays = document.getElementById("rule-min-days");

      if (window.propWizardState.tab === "funded") {
        if (elTarget) elTarget.textContent = "N/A (Retiros / Payouts)";
        if (elMaxDD)  elMaxDD.textContent  = `$${ddVal} (${ddType.toUpperCase()})`;
        if (elDaily)  elDaily.textContent  = dailyEnabled ? `$${dailyVal}` : "No aplica";
        if (elCons)   elCons.textContent   = consEnabled ? `${consVal}% (Regla Retiro)` : "No aplica";
        if (elMinDays) elMinDays.textContent = `${minDaysVal} días`;
      } else {
        if (elTarget) elTarget.textContent = `${targetUnit === 'percent' ? '' : '$'}${targetVal}${targetUnit === 'percent' ? '%' : ''}`;
        if (elMaxDD)  elMaxDD.textContent  = `$${ddVal} (${ddType.toUpperCase()} - ${ddFloor === 'initial_balance' ? 'Balance inicial' : 'Fijo'})`;
        if (elDaily)  elDaily.textContent  = dailyEnabled ? `$${dailyVal}` : "No aplica";
        if (elCons)   elCons.textContent   = consEnabled ? `${consVal}% máx` : "No aplica";
        if (elMinDays) elMinDays.textContent = `${minDaysVal} días (${unlimitedVal ? 'Sin límite' : 'Limitado'})`;
      }
    };

    window.toggleCustomRulesModal = function() {
      const m = document.getElementById("custom-rules-modal");
      if (m) m.classList.toggle("hidden");
    };

    window.applyModalRules = function() {
      window.updateRulesDisplay();
      window.toggleCustomRulesModal();
    };

    window.toggleUnlimited = function(step) {
      const unl = document.getElementById(`${step}_unlimited`);
      const input = document.getElementById(`${step}_period_days`);
      if (input && unl) {
        input.disabled = unl.checked;
        if (unl.checked) input.value = "";
      }
    };

    window.toggleDailyLoss = function(step) {
      const en = document.getElementById(`${step}_daily_enabled`);
      const val = document.getElementById(`${step}_daily_val`);
      const unit = document.getElementById(`${step}_daily_unit`);
      if (val && en) {
        val.disabled = !en.checked;
        if (unit) unit.disabled = !en.checked;
      }
    };

    window.toggleConsistency = function(step) {
      const en = document.getElementById(`${step}_consistency_enabled`);
      const val = document.getElementById(`${step}_consistency_pct`);
      if (val && en) {
        val.disabled = !en.checked;
      }
    };

    window.updateConsistencyHelp = function(step) {
      const val = document.getElementById(`${step}_consistency_pct`)?.value || "50";
      const help = document.getElementById(`${step}_consistency_help`);
      if (help) help.textContent = `Tu mejor día debe estar por debajo del ${val}% de tu profit total.`;
    };

    window.toggleSameAsStep1 = function(isSame) {
      const fields = document.querySelectorAll("#step2-fields-container input, #step2-fields-container select");
      fields.forEach(f => {
        f.disabled = isSame;
        if (isSame) {
          const step1Id = f.id.replace("step2_", "step1_");
          const step1El = document.getElementById(step1Id);
          if (step1El) f.value = step1El.value;
        }
      });
    };

    window.applyTemplateToModal = function(templateKey) {
      if (templateKey.includes("FTMO") || templateKey.includes("2Step")) {
        window.propWizardState.program_steps = 2;
      } else {
        window.propWizardState.program_steps = 1;
      }
      window.updateRulesDisplay();
    };

    window.selectModalSizeChip = function(sizeLabel, btn) {
      document.querySelectorAll(".modal-size-chip").forEach(b => b.classList.remove("border-brand", "text-brand", "bg-brand/10"));
      if (btn) btn.classList.add("border-brand", "text-brand", "bg-brand/10");
      window.setAccountSize(sizeLabel);
    };

    window.syncModalAccountSize = function(val) {
      const sizeStr = val >= 1000 ? `${Math.round(val / 1000)}K` : val;
      const s = document.getElementById("prop_account_size_field");
      if (s) s.value = sizeStr;
      window.propWizardState.size = sizeStr;
      window.updateRulesDisplay();
    };

    window.updateStrategiesSummary = function() {
      const checked = document.querySelectorAll(".strategy-checkbox:checked");
      const summary = document.getElementById("strategies-selected-summary");
      if (summary) {
        if (checked.length === 0) {
          summary.textContent = "Seleccionar estrategias...";
          summary.className = "text-slate-400";
        } else {
          summary.textContent = `${checked.length} estrategia(s) seleccionada(s)`;
          summary.className = "text-brand font-bold";
        }
      }
    };

    window.initWizard = function() {
      window.goToStep(window.propWizardState.step);
    };
  }
}
