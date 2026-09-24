import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initWizardGlobals();
    
    // El elemento (this.element) es el <form>
    const hasErrors = this.element.dataset.hasFormErrors === 'true';
    if (hasErrors) {
      window.propWizardState.step = 3;
    } else {
      window.propWizardState = { step: 1, mode: 'preset', firm: 'Topstep', plan: 'Estándar', size: '50K', tab: 'step1' };
    }
    
    if (typeof window.initWizard === "function") {
      window.initWizard();
    }
  }

  initWizardGlobals() {
    window.RULES_DATABASE = {
      "10K":  { target: "$600",   max_dd: "$1,000 (EOD)", daily: "$500",  consistency: "50%", min_days: "2 días" },
      "25K":  { target: "$1,500", max_dd: "$1,500 (EOD)", daily: "$1,000", consistency: "50%", min_days: "2 días" },
      "50K":  { target: "$3,000", max_dd: "$2,000 (EOD)", daily: "$1,000", consistency: "50%", min_days: "2 días" },
      "100K": { target: "$6,000", max_dd: "$3,000 (EOD)", daily: "$2,000", consistency: "50%", min_days: "2 días" },
      "150K": { target: "$9,000", max_dd: "$4,500 (EOD)", daily: "$3,000", consistency: "50%", min_days: "2 días" },
      "200K": { target: "$12,000", max_dd: "$5,000 (EOD)", daily: "$4,000", consistency: "50%", min_days: "2 días" },
      "250K": { target: "$15,000", max_dd: "$6,000 (EOD)", daily: "$5,000", consistency: "50%", min_days: "2 días" }
    };

    if (typeof window.propWizardState === 'undefined') {
      window.propWizardState = { step: 1, mode: 'preset', firm: 'Topstep', plan: 'Estándar', size: '50K', tab: 'step1' };
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
    };

    window.syncManualSize = function(val) {
      const s = document.getElementById("prop_account_size_field");
      if (s) s.value = val;
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
          if (label) label.className = "text-[11px] font-bold text-brand transition-colors";
        } else {
          node.className = "w-10 h-10 rounded-full bg-slate-200 dark:bg-darkBorder text-slate-500 font-extrabold text-sm flex items-center justify-center transition-all";
          if (label) label.className = "text-[11px] font-bold text-slate-400 transition-colors";
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
      if (title) title.textContent = `3 - REGLAS: ${window.propWizardState.firm.toUpperCase()} (${window.propWizardState.size})`;
      const data = window.RULES_DATABASE[window.propWizardState.size] || window.RULES_DATABASE["50K"];

      const elTarget = document.getElementById("rule-target");
      const elMaxDD  = document.getElementById("rule-max-dd");
      const elDaily  = document.getElementById("rule-daily-loss");
      const elCons   = document.getElementById("rule-consistency");

      if (window.propWizardState.tab === "funded") {
        if (elTarget) elTarget.textContent = "N/A (Retiros / Payouts)";
        if (elMaxDD)  elMaxDD.textContent  = data.max_dd;
        if (elDaily)  elDaily.textContent  = data.daily;
        if (elCons)   elCons.textContent   = "30% (Regla Retiro)";
      } else {
        if (elTarget) elTarget.textContent = data.target;
        if (elMaxDD)  elMaxDD.textContent  = data.max_dd;
        if (elDaily)  elDaily.textContent  = data.daily;
        if (elCons)   elCons.textContent   = data.consistency;
      }
    };

    window.toggleCustomRulesModal = function() {
      const m = document.getElementById("custom-rules-modal");
      if (m) m.classList.toggle("hidden");
    };

    window.switchModalTab = function(tabName, btn) {
      document.querySelectorAll(".modal-tab-btn").forEach(b => {
        b.classList.remove("bg-white", "dark:bg-slate-700", "text-brand", "shadow-xs");
        b.classList.add("text-slate-400");
      });
      if (btn) {
        btn.classList.add("bg-white", "dark:bg-slate-700", "text-brand", "shadow-xs");
        btn.classList.remove("text-slate-400");
      }
      const ev = document.getElementById("modal-sec-eval");
      const fu = document.getElementById("modal-sec-funded");
      if (tabName === "funded") {
        if (ev) ev.classList.add("hidden");
        if (fu) fu.classList.remove("hidden");
      } else {
        if (ev) ev.classList.remove("hidden");
        if (fu) fu.classList.add("hidden");
      }
    };

    window.initWizard = function() {
      window.goToStep(window.propWizardState.step);
    };
  }
}
