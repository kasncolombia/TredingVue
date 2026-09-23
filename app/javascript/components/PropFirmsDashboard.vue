<template>
  <div class="prop-firms-dashboard max-w-7xl mx-auto space-y-6 p-4 md:p-6 text-slate-800 dark:text-slate-100">
    
    <!-- 1. HEADER PRINCIPAL ÚNICO + TOP-RIGHT CTA -->
    <header class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 dark:border-slate-800 pb-4">
      <div>
        <h1 class="text-xl md:text-2xl font-black text-slate-900 dark:text-white flex items-center gap-2">
          <span class="material-symbols-outlined text-sky-500 text-3xl">account_tree</span>
          Prop Firms & Herramientas
        </h1>
        <p class="text-xs md:text-sm text-slate-500 dark:text-slate-400 mt-1 max-w-xl">
          Centro integral para gestionar tus cuentas de fondeo, simulador y rendimiento institucional.
        </p>
      </div>

      <!-- BOTÓN PRINCIPAL SIEMPRE VISIBLE EN LA ESQUINA SUPERIOR DERECHA -->
      <div class="flex items-center gap-3">
        <button
          @click="openNewAccountWizard"
          class="px-5 py-2.5 bg-sky-500 hover:bg-sky-600 text-white font-extrabold text-xs rounded-xl shadow-lg shadow-sky-500/25 transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap active:scale-95"
        >
          <span class="material-symbols-outlined text-lg">add_circle</span>
          <span>+ Nueva Cuenta de Fondeo</span>
        </button>
      </div>
    </header>

    <!-- 2. NAVEGACIÓN INTERNA (PESTAÑAS ALINEADAS A LA IZQUIERDA) -->
    <nav class="flex items-center gap-2 overflow-x-auto pb-1">
      <div class="flex p-1 bg-slate-200/60 dark:bg-slate-800/60 rounded-xl border border-slate-300/60 dark:border-slate-700">
        <button
          v-for="tab in navigationTabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          :class="[
            'py-2 px-4 text-xs font-bold rounded-lg transition-all flex items-center gap-2 cursor-pointer',
            activeTab === tab.id
              ? 'bg-white dark:bg-slate-700 text-sky-500 shadow-sm'
              : 'text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-white'
          ]"
        >
          <span class="material-symbols-outlined text-base">{{ tab.icon }}</span>
          {{ tab.label }}
        </button>
      </div>
    </nav>

    <!-- ================================================================= -->
    <!-- ESTADO VACÍO (USER SIN CUENTAS) -->
    <!-- ================================================================= -->
    <section
      v-if="accounts.length === 0"
      class="bg-white/60 dark:bg-slate-900/60 backdrop-blur-md rounded-3xl p-8 md:p-14 text-center max-w-2xl mx-auto space-y-6 border border-slate-200 dark:border-slate-800 shadow-xl my-8"
    >
      <!-- MOCKUP ILUSTRATIVO DEL MÓDULO CON EFECTO GLOW -->
      <div class="relative w-24 h-24 mx-auto flex items-center justify-center">
        <div class="absolute inset-0 rounded-3xl bg-sky-500/20 blur-2xl animate-pulse"></div>
        <div class="w-20 h-20 rounded-3xl bg-gradient-to-tr from-sky-500 to-emerald-400 text-white flex items-center justify-center shadow-lg relative z-10">
          <span class="material-symbols-outlined text-4xl">account_tree</span>
        </div>
      </div>

      <div class="space-y-2">
        <div class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-sky-500/10 text-sky-500 text-xs font-bold border border-sky-500/20">
          <span class="material-symbols-outlined text-sm">rocket_launch</span>
          Gestión de Fondeo Institucional
        </div>
        <h2 class="text-2xl md:text-3xl font-black text-slate-900 dark:text-white tracking-tight">
          Gestiona tu Empresa de Fondeo como un Negocio
        </h2>
        <p class="text-xs md:text-sm text-slate-500 dark:text-slate-400 max-w-lg mx-auto leading-relaxed">
          Configura tus evaluaciones (Topstep, Apex, FTMO, etc.), audita tus reglas de Drawdown/Profit y monitorea tu balance en un único panel profesional.
        </p>
      </div>

      <div class="pt-2">
        <button
          @click="openNewAccountWizard"
          class="px-8 py-3.5 bg-sky-500 hover:bg-sky-600 text-white font-extrabold text-xs rounded-xl shadow-xl shadow-sky-500/30 transition-all inline-flex items-center justify-center gap-2 cursor-pointer active:scale-95"
        >
          <span class="material-symbols-outlined text-xl">add_circle</span>
          <span>+ Nueva Cuenta de Fondeo</span>
        </button>
      </div>
    </section>

    <!-- ================================================================= -->
    <!-- ESTADO ACTIVO (PANEL DE CONTROL & KPIS) -->
    <!-- ================================================================= -->
    <template v-else>
      <!-- 3. SECCIÓN DE KPIS GLOBALES (TOP-LEVEL ANALYTICS) -->
      <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <!-- KPI 1: CAPITAL FINANCIADO TOTAL -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md p-4 rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-sm">
          <div>
            <span class="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">Capital Monitoreado</span>
            <span class="text-xl font-black text-slate-900 dark:text-white font-mono mt-0.5 block">
              ${{ formatNumber(totalCapital) }}
            </span>
          </div>
          <div class="w-10 h-10 rounded-xl bg-sky-500/10 text-sky-500 flex items-center justify-center font-bold">
            <span class="material-symbols-outlined text-xl">account_balance</span>
          </div>
        </div>

        <!-- KPI 2: INVERSIÓN TOTAL EN EVALUACIONES -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md p-4 rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-sm">
          <div>
            <span class="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">Inversión Evaluaciones</span>
            <span class="text-xl font-black text-slate-900 dark:text-white font-mono mt-0.5 block">
              ${{ formatCurrency(totalInvested) }}
            </span>
          </div>
          <div class="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-500 flex items-center justify-center font-bold">
            <span class="material-symbols-outlined text-xl">receipt_long</span>
          </div>
        </div>

        <!-- KPI 3: PNL / PROFIT ACUMULADO -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md p-4 rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-sm">
          <div>
            <span class="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">PnL Acumulado</span>
            <span
              :class="[
                'text-xl font-black font-mono mt-0.5 block',
                totalPnl >= 0 ? 'text-emerald-500' : 'text-rose-500'
              ]"
            >
              {{ totalPnl >= 0 ? '+' : '' }}${{ formatCurrency(totalPnl) }}
            </span>
          </div>
          <div
            :class="[
              'w-10 h-10 rounded-xl flex items-center justify-center font-bold',
              totalPnl >= 0 ? 'bg-emerald-500/10 text-emerald-500' : 'bg-rose-500/10 text-rose-500'
            ]"
          >
            <span class="material-symbols-outlined text-xl">{{ totalPnl >= 0 ? 'trending_up' : 'trending_down' }}</span>
          </div>
        </div>

        <!-- KPI 4: RETIROS REALIZADOS (PAYOUTS) -->
        <div class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md p-4 rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center justify-between shadow-sm">
          <div>
            <span class="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">Retiros Realizados</span>
            <span class="text-xl font-black text-emerald-500 font-mono mt-0.5 block">
              +${{ formatCurrency(totalPayouts) }}
            </span>
          </div>
          <div class="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-500 flex items-center justify-center font-bold">
            <span class="material-symbols-outlined text-xl">savings</span>
          </div>
        </div>
      </section>

      <!-- 4. FILTROS RÁPIDOS POR TAGS EN EL GRID -->
      <section class="flex flex-col sm:flex-row items-center justify-between gap-3 pt-2">
        <div class="flex items-center gap-1.5 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
          <button
            v-for="filter in statusFilters"
            :key="filter.id"
            @click="activeFilter = filter.id"
            :class="[
              'px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap',
              activeFilter === filter.id
                ? 'bg-sky-500 text-white shadow-sm'
                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:text-sky-500'
            ]"
          >
            {{ filter.label }} ({{ getFilterCount(filter.id) }})
          </button>
        </div>

        <span class="text-xs text-slate-400 font-bold hidden md:inline">
          Mostrando {{ filteredAccounts.length }} de {{ accounts.length }} cuentas
        </span>
      </section>

      <!-- GRID REDISEÑADO DE TARJETAS DE CUENTAS COMPACTAS -->
      <section class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <article
          v-for="acc in filteredAccounts"
          :key="acc.id"
          class="bg-white/70 dark:bg-slate-900/70 backdrop-blur-md rounded-2xl p-4 border border-slate-200/80 dark:border-slate-800 space-y-3 hover:border-sky-500/60 transition-all group shadow-sm"
        >
          <!-- HEADER DE TARJETA CON LOGO & CHIPS DE TAILWIND -->
          <div class="flex items-start justify-between gap-2">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-center font-black text-xs text-sky-500 flex-shrink-0">
                {{ getFirmInitials(acc.firmName) }}
              </div>
              <div>
                <h3 class="text-sm font-black text-slate-900 dark:text-white group-hover:text-sky-500 transition-colors line-clamp-1">
                  {{ acc.name || acc.firmName }}
                </h3>
                <span class="text-[11px] font-mono text-slate-400 font-bold flex items-center gap-1">
                  {{ acc.firmName }} • {{ acc.accountSize }}
                </span>
              </div>
            </div>

            <!-- CHIPS DE ESTADO EN TAILWIND COLORS (emerald, blue, amber, red, purple) -->
            <div class="flex flex-col items-end gap-1">
              <span
                :class="[
                  'px-2 py-0.5 rounded-md text-[9px] font-black uppercase tracking-wider border',
                  getStatusChipStyle(acc.status)
                ]"
              >
                {{ acc.status }}
              </span>
              <span
                :class="[
                  'px-2 py-0.5 rounded-md text-[9px] font-bold uppercase tracking-wider border',
                  getPhaseChipStyle(acc.phase)
                ]"
              >
                {{ acc.phase }}
              </span>
            </div>
          </div>

          <!-- MÉTRICAS COMPACTAS -->
          <div class="grid grid-cols-2 gap-2 text-[11px] font-mono border-t border-slate-200 dark:border-slate-800 pt-3">
            <div class="bg-slate-50 dark:bg-slate-800/60 p-2 rounded-xl border border-slate-200/50 dark:border-slate-700/50">
              <span class="text-slate-400 font-sans block text-[10px]">Profit Actual</span>
              <span
                :class="[
                  'font-bold text-xs',
                  acc.pnl >= 0 ? 'text-emerald-500' : 'text-rose-500'
                ]"
              >
                {{ acc.pnl >= 0 ? '+' : '' }}${{ formatCurrency(acc.pnl) }}
              </span>
            </div>
            <div class="bg-slate-50 dark:bg-slate-800/60 p-2 rounded-xl border border-slate-200/50 dark:border-slate-700/50">
              <span class="text-slate-400 font-sans block text-[10px]">Profit Target</span>
              <span class="font-bold text-xs text-slate-800 dark:text-slate-200">
                ${{ formatNumber(acc.profitTarget) }}
              </span>
            </div>
            <div class="bg-slate-50 dark:bg-slate-800/60 p-2 rounded-xl border border-slate-200/50 dark:border-slate-700/50">
              <span class="text-slate-400 font-sans block text-[10px]">Máx Drawdown</span>
              <span class="font-bold text-xs text-rose-500">
                ${{ formatNumber(acc.maxDrawdown) }}
              </span>
            </div>
            <div class="bg-slate-50 dark:bg-slate-800/60 p-2 rounded-xl border border-slate-200/50 dark:border-slate-700/50">
              <span class="text-slate-400 font-sans block text-[10px]">Cuota Eval.</span>
              <span class="font-bold text-xs text-slate-800 dark:text-slate-200">
                ${{ acc.evalFee || 0 }}
              </span>
            </div>
          </div>

          <!-- BOTÓN DE ACCIÓN INDIVIDUAL -->
          <div class="pt-1">
            <button
              @click="viewAccountDetails(acc.id)"
              class="w-full py-2 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-sky-500 hover:text-white dark:hover:bg-sky-500 text-slate-700 dark:text-slate-200 font-bold text-xs transition-all flex items-center justify-center gap-1.5 cursor-pointer active:scale-98"
            >
              <span class="material-symbols-outlined text-base">visibility</span>
              <span>Ver Detalle</span>
            </button>
          </div>
        </article>
      </section>
    </template>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

// ── PESTAÑAS DE NAVEGACIÓN PRINCIPAL ──
const activeTab = ref('accounts');
const navigationTabs = [
  { id: 'accounts', label: 'Mis Cuentas', icon: 'account_tree' },
  { id: 'simulator', label: 'Simulador', icon: 'sports_esports' },
  { id: 'finances', label: 'Finanzas', icon: 'account_balance_wallet' },
  { id: 'brokers', label: 'Brokers', icon: 'hub' }
];

// ── ESTADO REACTIVO DE CUENTAS (MOCK/PROPS) ──
const accounts = ref([
  {
    id: 1,
    name: 'Topstep 50K Express #1',
    firmName: 'Topstep',
    accountSize: '50K',
    rawSize: 50000,
    status: 'activa',
    phase: 'paso_1',
    pnl: 1450.0,
    profitTarget: 3000,
    maxDrawdown: 2000,
    evalFee: 49
  },
  {
    id: 2,
    name: 'Apex 100K Funded Live',
    firmName: 'Apex Trader Funding',
    accountSize: '100K',
    rawSize: 100000,
    status: 'fondeada',
    phase: 'fondeada',
    pnl: 3820.5,
    profitTarget: 6000,
    maxDrawdown: 3000,
    evalFee: 149
  },
  {
    id: 3,
    name: 'Funding Pips 25K Challenge',
    firmName: 'Funding Pips',
    accountSize: '25K',
    rawSize: 25000,
    status: 'activa',
    phase: 'paso_2',
    pnl: -420.0,
    profitTarget: 1750,
    maxDrawdown: 1250,
    evalFee: 39
  }
]);

const totalPayouts = ref(4200.0);

// ── KPIS CALCULADOS ──
const totalCapital = computed(() => accounts.value.reduce((acc, a) => acc + a.rawSize, 0));
const totalInvested = computed(() => accounts.value.reduce((acc, a) => acc + (a.evalFee || 0), 0));
const totalPnl = computed(() => accounts.value.reduce((acc, a) => acc + a.pnl, 0));

// ── FILTROS RÁPIDOS ──
const activeFilter = ref('all');
const statusFilters = [
  { id: 'all', label: 'Todas' },
  { id: 'activa', label: 'Activas' },
  { id: 'eval', label: 'En Evaluación' },
  { id: 'fondeada', label: 'Fondeadas' },
  { id: 'quemada', label: 'Quemadas' }
];

const filteredAccounts = computed(() => {
  if (activeFilter.value === 'all') return accounts.value;
  if (activeFilter.value === 'eval') {
    return accounts.value.filter(a => a.phase.includes('paso') || a.phase === 'express');
  }
  return accounts.value.filter(a => a.status === activeFilter.value);
});

const getFilterCount = (filterId) => {
  if (filterId === 'all') return accounts.value.length;
  if (filterId === 'eval') {
    return accounts.value.filter(a => a.phase.includes('paso') || a.phase === 'express').length;
  }
  return accounts.value.filter(a => a.status === filterId).length;
};

// ── HELPERS VISUALES ──
const getFirmInitials = (firm) => (firm ? firm.slice(0, 2).toUpperCase() : 'PF');

const getStatusChipStyle = (status) => {
  switch (status.toLowerCase()) {
    case 'activa': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/30';
    case 'fondeada': return 'bg-purple-500/10 text-purple-400 border-purple-500/30';
    case 'quemada': return 'bg-red-500/10 text-red-500 border-red-500/30';
    default: return 'bg-amber-500/10 text-amber-500 border-amber-500/30';
  }
};

const getPhaseChipStyle = (phase) => {
  switch (phase.toLowerCase()) {
    case 'paso_1': return 'bg-blue-500/10 text-blue-500 border-blue-500/30';
    case 'paso_2': return 'bg-amber-500/10 text-amber-500 border-amber-500/30';
    case 'fondeada': return 'bg-purple-500/10 text-purple-400 border-purple-500/30';
    default: return 'bg-slate-500/10 text-slate-400 border-slate-500/30';
  }
};

const formatNumber = (val) => Number(val || 0).toLocaleString('en-US');
const formatCurrency = (val) => Number(val || 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// ── EVENTOS / ACCIONES ──
const openNewAccountWizard = () => {
  console.log('Abrir Wizard de Nueva Cuenta de Fondeo');
};

const viewAccountDetails = (id) => {
  console.log('Ver detalle de cuenta ID:', id);
};
</script>
