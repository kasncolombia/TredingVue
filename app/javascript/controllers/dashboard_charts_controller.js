import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "equityChart", "drawdownChart", "radarChart", "dailyPnlChart",
    "scatterChart", "portfolioChart",
    "sparkBalance", "sparkWinRate", "sparkPf", "sparkAvg",
    "btnPnlNeto", "btnBalance", "btnWinrate",
    "btnTrailing", "btnInversion",
    "dailyWindowLabel", "dailyWindowMenu", "dailyWindowOpt",
    "layoutWrapper3x2", "layoutWrapperClassic",
    "layout3x2Container", "classicColLeft", "classicColRight", "classicRowBottom",
    "btnLayout3x2", "btnLayoutClassic",
    "cardEquity", "cardDailyPnl", "cardRadar", "cardDrawdown", "cardScatter", "cardTrades"
  ]

  static values = {
    equity: Array,
    stats: Object,
    durations: Array,
    portfolio: Array
  }

  connect() {
    this.charts = []
    this.currentEquityMode = "pnl"
    this.currentDdMode = "trailing"
    this.currentDailyWindow = "30D"

    this.initLayout()
    this.renderAllCharts()

    this.onResize = () => {
      this.charts.forEach(chart => {
        if (chart && !chart.isDisposed()) {
          chart.resize()
        }
      })
    }
    window.addEventListener("resize", this.onResize)

    this.onOutsideClick = (e) => {
      if (this.hasDailyWindowMenuTarget) {
        const btn = this.element.querySelector('#btn-daily-window')
        if (btn && !btn.contains(e.target) && !this.dailyWindowMenuTarget.contains(e.target)) {
          this.dailyWindowMenuTarget.classList.add("hidden")
        }
      }
    }
    document.addEventListener("click", this.onOutsideClick)
  }

  disconnect() {
    window.removeEventListener("resize", this.onResize)
    document.removeEventListener("click", this.onOutsideClick)
    this.charts.forEach(chart => {
      if (chart && !chart.isDisposed()) {
        chart.dispose()
      }
    })
    this.charts = []
  }

  // --- LAYOUT SWITCHER (3x2 vs Classic) ---
  initLayout() {
    const savedMode = localStorage.getItem("coachtrading_layout_mode") || "3x2"
    this.applyLayout(savedMode)
  }

  setLayout3x2() {
    this.applyLayout("3x2")
  }

  setLayoutClassic() {
    this.applyLayout("classic")
  }

  applyLayout(mode) {
    localStorage.setItem("coachtrading_layout_mode", mode)

    if (!this.hasCardEquityTarget || !this.hasLayout3x2ContainerTarget || !this.hasClassicColLeftTarget) return

    if (mode === "classic") {
      if (this.hasLayoutWrapper3x2Target) this.layoutWrapper3x2Target.classList.add("hidden")
      if (this.hasLayoutWrapperClassicTarget) this.layoutWrapperClassicTarget.classList.remove("hidden")

      if (this.hasClassicColLeftTarget) {
        if (this.hasCardEquityTarget) this.classicColLeftTarget.appendChild(this.cardEquityTarget)
        if (this.hasCardDrawdownTarget) this.classicColLeftTarget.appendChild(this.cardDrawdownTarget)
      }
      
      if (this.hasClassicColRightTarget) {
        if (this.hasCardRadarTarget) this.classicColRightTarget.appendChild(this.cardRadarTarget)
        if (this.hasCardTradesTarget) this.classicColRightTarget.appendChild(this.cardTradesTarget)
      }

      if (this.hasClassicRowBottomTarget) {
        if (this.hasCardDailyPnlTarget) this.classicRowBottomTarget.appendChild(this.cardDailyPnlTarget)
        if (this.hasCardScatterTarget) this.classicRowBottomTarget.appendChild(this.cardScatterTarget)
      }

      if (this.hasBtnLayoutClassicTarget && this.hasBtnLayout3x2Target) {
        this.btnLayoutClassicTarget.className = "py-1.5 px-3 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5 cursor-pointer bg-white dark:bg-slate-700 text-brand shadow-xs"
        this.btnLayout3x2Target.className = "py-1.5 px-3 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5 cursor-pointer text-slate-400 hover:text-slate-700 dark:hover:text-white"
      }
    } else {
      if (this.hasLayoutWrapperClassicTarget) this.layoutWrapperClassicTarget.classList.add("hidden")
      if (this.hasLayoutWrapper3x2Target) this.layoutWrapper3x2Target.classList.remove("hidden")

      if (this.hasLayout3x2ContainerTarget) {
        if (this.hasCardEquityTarget) this.layout3x2ContainerTarget.appendChild(this.cardEquityTarget)
        if (this.hasCardDailyPnlTarget) this.layout3x2ContainerTarget.appendChild(this.cardDailyPnlTarget)
        if (this.hasCardRadarTarget) this.layout3x2ContainerTarget.appendChild(this.cardRadarTarget)
        if (this.hasCardDrawdownTarget) this.layout3x2ContainerTarget.appendChild(this.cardDrawdownTarget)
        if (this.hasCardScatterTarget) this.layout3x2ContainerTarget.appendChild(this.cardScatterTarget)
        if (this.hasCardTradesTarget) this.layout3x2ContainerTarget.appendChild(this.cardTradesTarget)
      }

      if (this.hasBtnLayoutClassicTarget && this.hasBtnLayout3x2Target) {
        this.btnLayout3x2Target.className = "py-1.5 px-3 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5 cursor-pointer bg-white dark:bg-slate-700 text-brand shadow-xs"
        this.btnLayoutClassicTarget.className = "py-1.5 px-3 text-xs font-bold rounded-lg transition-all flex items-center gap-1.5 cursor-pointer text-slate-400 hover:text-slate-700 dark:hover:text-white"
      }
    }

    setTimeout(() => window.dispatchEvent(new Event("resize")), 60)
  }

  // --- RENDER ALL CHARTS ---
  renderAllCharts() {
    if (typeof window.echarts === "undefined") return

    this.isDark = document.documentElement.classList.contains("dark")
    
    this.renderEquityChart(this.currentEquityMode)
    this.renderDrawdownChart()
    this.renderRadarChart()
    this.renderSparklines()
    this.renderDailyPnlBarChart()
    this.renderScatterChart()
    this.renderPortfolioDonutChart()
  }

  // --- 1. EQUITY CURVE ---
  switchEquityMode(event) {
    const mode = event.currentTarget.dataset.mode
    this.currentEquityMode = mode

    const btnClsBase = "px-[12px] py-[6px] rounded-[8px] text-[10px] font-bold uppercase tracking-[0.05em] transition-all cursor-pointer"
    const clsActive = `${btnClsBase} shadow-sm sm:shadow-none dark:bg-[#151322] dark:text-[#8b7cf6] bg-[#ffffff] text-[#4f46e5]`
    const clsInactive = `${btnClsBase} shadow-none dark:text-[#6b7088] text-[#8b93a7] bg-transparent hover:dark:text-slate-200 hover:text-slate-700`

    if (this.hasBtnPnlNetoTarget) this.btnPnlNetoTarget.className = (mode === "pnl") ? clsActive : clsInactive
    if (this.hasBtnBalanceTarget) this.btnBalanceTarget.className = (mode === "balance") ? clsActive : clsInactive
    if (this.hasBtnWinrateTarget) this.btnWinrateTarget.className = (mode === "winrate") ? clsActive : clsInactive

    this.renderEquityChart(mode)
  }

  renderEquityChart(mode) {
    if (!this.hasEquityChartTarget) return

    const container = this.equityChartTarget
    let existing = window.echarts.getInstanceByDom(container)
    if (existing) existing.dispose()

    const chart = window.echarts.init(container)
    this.charts.push(chart)

    const isDarkGlobal = this.isDark
    const cGreen = isDarkGlobal ? '#19b57a' : '#10a56d'
    const cRed = isDarkGlobal ? '#ef4b55' : '#e5365c'
    const cAxisLine = isDarkGlobal ? '#3a3f55' : '#cfd4e0'
    const cAxisText = isDarkGlobal ? '#5f657c' : '#8b93a7'
    const cZeroLine = isDarkGlobal ? '#6b7280' : '#b8bdca'
    const gridLineColor = isDarkGlobal ? 'rgba(255,255,255,0.04)' : 'rgba(15,23,42,0.06)'

    const PNL_POINTS = [
      [0.000, 0], [0.026, 195], [0.042, 325], [0.051, 357], [0.058, 195],
      [0.067, -260], [0.076, -455], [0.090, -390], [0.106, -227], [0.119, 130],
      [0.129, 292], [0.140, 195], [0.153, 130], [0.167, 260], [0.181, 357],
      [0.199, 617], [0.217, 812], [0.231, 909], [0.245, 844], [0.263, 682],
      [0.286, 520], [0.309, 390], [0.318, -32], [0.327, -455], [0.336, -585],
      [0.363, -617], [0.384, -617], [0.405, -455], [0.418, -520], [0.437, -585],
      [0.446, -357], [0.455, -97], [0.473, 32], [0.491, 130], [0.505, 325],
      [0.523, 390], [0.546, 390], [0.583, 455], [0.596, 390], [0.612, 260],
      [0.619, 292], [0.637, 487], [0.665, 585], [0.694, 585], [0.706, 942],
      [0.720, 1266], [0.738, 1396], [0.770, 1494], [0.779, 1656], [0.793, 1916],
      [0.806, 1850], [0.820, 1786], [0.838, 2110], [0.866, 2110], [0.893, 2078],
      [0.920, 2175], [0.948, 2110], [0.957, 2175], [0.975, 2468], [1.000, 2792]
    ]

    const xLabelsConf = [
      { v: 0.051, t: '6 feb' }, { v: 0.102, t: '11 feb' }, { v: 0.174, t: '16 feb' },
      { v: 0.257, t: '20 feb' }, { v: 0.329, t: '27 feb' }, { v: 0.408, t: '5 mar' },
      { v: 0.487, t: '10 mar' }, { v: 0.563, t: '18 mar' }, { v: 0.640, t: '25 mar' },
      { v: 0.716, t: '1 abr' }, { v: 0.768, t: '6 abr' }, { v: 0.846, t: '15 abr' },
      { v: 0.929, t: '24 abr' }, { v: 1.000, t: '30 abr' }
    ]

    let finalData = PNL_POINTS
    let yLabelsFn = (v) => v === 0 ? "$0" : `${v > 0 ? '$' : '$-'}${Math.abs(v)}`
    let minBound = -5000
    let maxBound = 5000

    if (mode === 'balance') {
      const initB = 100000
      finalData = PNL_POINTS.map(p => [p[0], initB + p[1]])
      minBound = 95000; maxBound = 105000
      yLabelsFn = (v) => `$${v.toLocaleString()}`
    } else if (mode === 'winrate') {
      finalData = PNL_POINTS.map(p => [p[0], 50 + (p[1]/100)])
      minBound = 0; maxBound = 100
      yLabelsFn = (v) => `${v}%`
    }

    const posValues = finalData.map(p => [p[0], p[1] >= (mode==='balance'?100000:0) ? p[1] : (mode==='balance'?100000:0)])
    const negValues = finalData.map(p => [p[0], p[1] <= (mode==='balance'?100000:0) ? p[1] : (mode==='balance'?100000:0)])

    const areaColorPos = isDarkGlobal ? 'rgba(25,181,122,0.75)' : 'rgba(16,165,109,0.60)'
    const areaColorNeg = isDarkGlobal ? 'rgba(239,75,85,0.75)' : 'rgba(229,54,92,0.60)'

    chart.setOption({
      backgroundColor: 'transparent',
      animationDuration: 600,
      grid: { left: 56, right: 12, top: 16, bottom: 34 },
      tooltip: {
        trigger: 'axis',
        backgroundColor: isDarkGlobal ? '#222222' : '#ffffff',
        borderColor: isDarkGlobal ? '#333333' : '#e3e6ee',
        borderWidth: 1, padding: [10, 14],
        textStyle: { color: isDarkGlobal ? '#ffffff' : '#111827', fontSize: 12 },
        extraCssText: isDarkGlobal ? 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.6)' : 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.08)',
        formatter: (params) => {
          if (!params || !params.length) return ''
          const p = params.find(item => item.seriesIndex === 2) || params[0]
          const usdVal = p.data[1]
          let xDate = "Día -"
          let closestXDist = 999
          xLabelsConf.forEach(xl => {
            const dist = Math.abs(xl.v - p.data[0])
            if (dist < closestXDist) {
              closestXDist = dist
              xDate = xl.t
            }
          })
          const isPos = mode === 'balance' ? usdVal >= 100000 : usdVal >= 0
          const color = isPos ? cGreen : cRed
          let displayVal = mode === 'balance' 
            ? `$${usdVal.toLocaleString('en-US', {minimumFractionDigits:2, maximumFractionDigits:2})}`
            : (mode === 'winrate' ? `${usdVal.toFixed(1)}%` : (usdVal >= 0 ? `+$${usdVal.toLocaleString('en-US',{minimumFractionDigits:2, maximumFractionDigits:2})}` : `-$${Math.abs(usdVal).toLocaleString('en-US',{minimumFractionDigits:2, maximumFractionDigits:2})}`))

          return `
            <div style="font-family:'Inter',system-ui,sans-serif;min-width:110px;padding:2px">
              <div style="font-size:11px;color:#999;margin-bottom:4px;font-weight:600">${xDate}</div>
              <div style="font-size:15px;font-weight:800;color:${color};letter-spacing:-0.3px">
                <span style="display:inline-block;width:5px;height:5px;border-radius:50%;background:${color};margin-right:4px;vertical-align:middle;"></span>
                ${displayVal}
              </div>
            </div>`
        },
        axisPointer: { lineStyle: { color: isDarkGlobal ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)', type: 'solid', width: 1 } }
      },
      xAxis: {
        type: 'value', min: 0, max: 1, boundaryGap: false,
        axisLine: { onZero: false, lineStyle: { color: cAxisLine, width: 1 } },
        axisTick: { show: true, length: 4, lineStyle: { color: cAxisLine } },
        axisLabel: {
          color: cAxisText, fontSize: 11, margin: 10,
          formatter: (v) => {
            const match = xLabelsConf.find(l => Math.abs(l.v - v) < 0.01)
            return match ? match.t : ""
          }
        },
        splitLine: { show: false }
      },
      yAxis: {
        type: 'value', min: minBound, max: maxBound, interval: mode==='winrate'?25:(maxBound-minBound)/4,
        axisLine: { show: true, lineStyle: { color: cAxisLine, width: 1 } },
        axisTick: { show: false },
        axisLabel: { color: cAxisText, fontSize: 11, margin: 6, formatter: yLabelsFn },
        splitLine: { show: true, lineStyle: { color: gridLineColor, type: 'dashed' } }
      },
      series: [
        {
          name: 'pos', type: 'line', data: posValues, smooth: 0.4, showSymbol: false, lineStyle: { width: 0 },
          areaStyle: {
            color: new window.echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: areaColorPos },
              { offset: 1, color: isDarkGlobal ? 'rgba(25,181,122,0.05)' : 'rgba(16,165,109,0.05)' }
            ])
          },
          silent: true, z: 1
        },
        {
          name: 'neg', type: 'line', data: negValues, smooth: 0.4, showSymbol: false, lineStyle: { width: 0 },
          areaStyle: {
            color: new window.echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: isDarkGlobal ? 'rgba(239,75,85,0.05)' : 'rgba(229,54,92,0.05)' },
              { offset: 1, color: areaColorNeg }
            ])
          },
          silent: true, z: 1
        },
        {
          name: 'main', type: 'line', data: finalData, smooth: 0.4, showSymbol: false,
          itemStyle: { color: cGreen },
          lineStyle: { width: 3, shadowColor: isDarkGlobal ? 'rgba(0,0,0,0.5)' : 'rgba(0,0,0,0.2)', shadowBlur: 8, shadowOffsetY: 2 },
          z: 3,
          markLine: {
            silent: true, symbol: 'none',
            lineStyle: { color: cZeroLine, type: 'dashed', width: 1 },
            label: { show: false },
            data: [{ yAxis: mode==='balance'?100000:0 }]
          }
        }
      ]
    }, true)
  }

  // --- 2. DRAWDOWN CHART ---
  switchDrawdownMode(event) {
    const mode = event.currentTarget.dataset.mode
    this.currentDdMode = mode

    const btnClsBase = 'px-2.5 py-1.5 rounded-[8px] text-[10px] font-bold uppercase tracking-[0.05em] transition-all cursor-pointer flex items-center gap-1'
    const CLS_ACTIVE = `${btnClsBase} dark:bg-[#151322] dark:text-[#8b7cf6] bg-[#ffffff] text-[#f0426a] shadow-sm sm:shadow-none`
    const CLS_INACTIVE = `${btnClsBase} dark:text-[#6b7088] text-[#8b93a7] bg-transparent shadow-none hover:dark:text-slate-200 hover:text-slate-700`
    const iconHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-trending-down"><polyline points="22 17 13.5 8.5 8.5 13.5 2 7"/><polyline points="16 17 22 17 22 11"/></svg>`

    if (this.hasBtnTrailingTarget) {
      this.btnTrailingTarget.className = (mode === 'trailing') ? CLS_ACTIVE : CLS_INACTIVE
      this.btnTrailingTarget.innerHTML = (mode === 'trailing') ? `${iconHTML} TRAILING` : 'TRAILING'
    }
    if (this.hasBtnInversionTarget) {
      this.btnInversionTarget.className = (mode === 'inversion') ? CLS_ACTIVE : CLS_INACTIVE
      this.btnInversionTarget.innerHTML = (mode === 'inversion') ? `${iconHTML} $ INVERSIÓN` : '$ INVERSIÓN'
    }

    this.renderDrawdownChart()
  }

  renderDrawdownChart() {
    if (!this.hasDrawdownChartTarget) return

    const container = this.drawdownChartTarget
    let existing = window.echarts.getInstanceByDom(container)
    if (existing) existing.dispose()

    const chart = window.echarts.init(container)
    this.charts.push(chart)

    const isDarkGlobal = this.isDark
    const C_DD_LINE = '#f0426a'
    const textColor = isDarkGlobal ? '#5f657c' : '#8b93a7'
    const axisColor = isDarkGlobal ? '#3a3f55' : '#cfd4e0'
    const gridLineColor = isDarkGlobal ? 'rgba(255, 255, 255, 0.06)' : 'rgba(15, 23, 42, 0.06)'

    const DRAWDOWN_POINTS = [
      [0.000, 0], [0.052, 0], [0.066, -350], [0.077, -746], [0.090, -700],
      [0.106, -580], [0.127, -206], [0.156, -180], [0.178, 0], [0.232, 0],
      [0.255, -155], [0.282, -257], [0.304, -425], [0.323, -900], [0.333,-1500],
      [0.363,-1515], [0.386,-1525], [0.408,-1229], [0.417,-1229], [0.437,-1400],
      [0.449,-1014], [0.462, -852], [0.485, -785], [0.507, -502], [0.543, -502],
      [0.566, -470], [0.588, -444], [0.602, -470], [0.615, -573], [0.642, -335],
      [0.665, -283], [0.696, -283], [0.714, -25], [0.742, -150], [0.768, -110],
      [0.794, 0], [0.820, -135], [0.845, 0], [0.868, -240], [0.899, -283],
      [0.922, -425], [0.949, -240], [0.972, 0], [1.000, 0]
    ]

    function T(val) {
      if (val >= 0) return 284
      if (val >= -785) return 284 - (Math.abs(val) / 785) * (284 - 162)
      if (val >= -1000) return 162 - ((Math.abs(val) - 785) / 215) * (162 - 91)
      if (val >= -2000) return 91 - ((Math.abs(val) - 1000) / 1000) * (91 - 21)
      if (val >= -2300) return 21 - ((Math.abs(val) - 2000) / 300) * (21 - 0)
      return 0
    }

    const seriesData = DRAWDOWN_POINTS.map(p => [p[0], T(p[1]), p[1]])

    const xLabelsConf = [
      { v: 0.05, t: '6 feb' }, { v: 0.10, t: '11 feb' }, { v: 0.18, t: '16 feb' },
      { v: 0.26, t: '20 feb' }, { v: 0.33, t: '27 feb' }, { v: 0.41, t: '5 mar' },
      { v: 0.49, t: '10 mar' }, { v: 0.56, t: '18 mar' }, { v: 0.64, t: '25 mar' },
      { v: 0.72, t: '1 abr' }, { v: 0.76, t: '6 abr' }, { v: 0.84, t: '15 abr' },
      { v: 0.92, t: '24 abr' }, { v: 1.00, t: '30 abr' }
    ]

    function yLabelFormat(val) {
      const rd = Math.round(val)
      if (Math.abs(rd - Math.round(T(0))) <= 1) return "$0"
      if (Math.abs(rd - Math.round(T(-785))) <= 1) return "-$785"
      if (Math.abs(rd - Math.round(T(-1000))) <= 1) return "-$1K"
      if (Math.abs(rd - Math.round(T(-2000))) <= 1) return "-$2K"
      return ""
    }

    chart.setOption({
      backgroundColor: 'transparent',
      animationDuration: 600,
      grid: { left: 56, right: 12, top: 16, bottom: 34 },
      tooltip: {
        trigger: 'axis',
        backgroundColor: isDarkGlobal ? '#222222' : '#ffffff',
        borderColor: isDarkGlobal ? '#333333' : '#e3e6ee',
        borderWidth: 1, padding: [10, 14],
        textStyle: { color: isDarkGlobal ? '#ffffff' : '#111827', fontSize: 12 },
        extraCssText: isDarkGlobal ? 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.6)' : 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.08)',
        formatter: (params) => {
          if (!params || !params.length) return ''
          const p = params[0]
          const usdVal = p.data[2]
          let xDate = "Día O."
          let closestXDist = 999
          xLabelsConf.forEach(xl => {
            const dist = Math.abs(xl.v - p.data[0])
            if (dist < closestXDist) {
              closestXDist = dist
              xDate = xl.t
            }
          })
          const displayVal = Math.abs(usdVal) >= 1000
            ? `-$${(Math.abs(usdVal)/1000).toLocaleString('es-MX', {minimumFractionDigits:1, maximumFractionDigits:2})}K`
            : `-$${Math.abs(usdVal).toLocaleString('es-MX', {minimumFractionDigits:2, maximumFractionDigits:2})}`

          return `
            <div style="font-family:'Inter',system-ui,sans-serif;min-width:100px;padding:2px">
              <div style="font-size:11px;color:#999;margin-bottom:4px;font-weight:600">${xDate}</div>
              <div style="font-size:15px;font-weight:800;color:${C_DD_LINE};letter-spacing:-0.3px">${usdVal === 0 ? '$0.00' : displayVal}</div>
            </div>`
        },
        axisPointer: { lineStyle: { color: isDarkGlobal ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)', type: 'dashed' } }
      },
      xAxis: {
        type: 'value', min: 0, max: 1, splitNumber: 20, boundaryGap: false,
        axisLine: { onZero: false, lineStyle: { color: axisColor, width: 1 } },
        axisTick: { show: true, length: 4, lineStyle: { color: axisColor } },
        axisLabel: {
          color: textColor, fontSize: 11, margin: 10,
          formatter: (v) => {
            const match = xLabelsConf.find(l => Math.abs(l.v - v) < 0.01)
            return match ? match.t : ""
          }
        },
        splitLine: { show: false }
      },
      yAxis: {
        type: 'value', min: 0, max: 285,
        axisLine: { show: true, lineStyle: { color: axisColor, width: 1 } },
        axisTick: { show: false },
        axisLabel: { color: textColor, fontSize: 11, margin: 6, formatter: yLabelFormat, inside: false },
        splitLine: { show: false }
      },
      series: [{
        name: 'drawdown', type: 'line', data: seriesData, smooth: 0.4, showSymbol: false,
        lineStyle: { width: 2, color: C_DD_LINE, shadowBlur: 0 },
        itemStyle: { color: C_DD_LINE },
        areaStyle: {
          color: new window.echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(240,66,106,0.0)' },
            { offset: 1, color: 'rgba(240,66,106,0.30)' }
          ])
        },
        markLine: {
          silent: true, symbol: 'none',
          lineStyle: { type: 'dashed', width: 1 },
          label: { show: false },
          data: [
            { yAxis: T(0), lineStyle: { color: '#6b7280', type: 'dashed' } },
            { yAxis: T(-785), lineStyle: { color: gridLineColor } },
            { yAxis: T(-1000), lineStyle: { color: gridLineColor } },
            { yAxis: T(-2000), lineStyle: { color: gridLineColor } }
          ]
        }
      }]
    }, true)
  }

  // --- 3. RADAR CHART ---
  renderRadarChart() {
    if (!this.hasRadarChartTarget) return

    const container = this.radarChartTarget
    let existing = window.echarts.getInstanceByDom(container)
    if (existing) existing.dispose()

    const chart = window.echarts.init(container)
    this.charts.push(chart)

    const stats = this.statsValue || {}
    const statsWinRate = Number(stats.win_rate || 0)
    const statsProfitFactor = Number(stats.profit_factor || 0)
    const statsRrRatio = Number(stats.rr_ratio || 0)

    const safeWin = Math.min(Math.max(statsWinRate, 0), 100)
    const safePf = Math.min(Math.max(statsProfitFactor, 0), 5)
    const safeRr = Math.min(Math.max(statsRrRatio, 0), 5)

    const textColor = this.isDark ? "#9DA3B4" : "#475569"
    const borderColor = this.isDark ? "#23263A" : "#E2E8F0"

    chart.setOption({
      backgroundColor: 'transparent',
      radar: {
        indicator: [
          { name: 'Win %', max: 100 },
          { name: 'Profit factor', max: 5 },
          { name: 'Avg win/loss', max: 5 },
          { name: 'Recovery factor', max: 5 },
          { name: 'Max drawdown', max: 20 },
          { name: 'Consistency', max: 100 }
        ],
        shape: 'polygon', splitNumber: 4, radius: '55%', center: ['50%', '50%'],
        axisName: { color: textColor, fontSize: 10, padding: [-4, -4] },
        splitLine: { lineStyle: { color: borderColor } },
        splitArea: { show: false },
        axisLine: { lineStyle: { color: borderColor } }
      },
      series: [{
        type: 'radar',
        data: [{
          value: [safeWin, safePf, safeRr, 3.2, 12, 88],
          lineStyle: { color: '#8b5cf6', width: 2 },
          areaStyle: { color: 'rgba(139,92,246,0.35)' },
          itemStyle: { color: '#8b5cf6' }
        }]
      }]
    }, true)
  }

  // --- 4. TOP KPI SPARKLINES ---
  renderSparklines() {
    const stats = this.statsValue || {}
    const statsWinRate = Number(stats.win_rate || 0)
    const statsProfitFactor = Number(stats.profit_factor || 0)
    const statsAvgWin = Number(stats.avg_win || 0)
    const statsAvgLoss = Number(stats.avg_loss || 0)

    // Balance Sparkline
    if (this.hasSparkBalanceTarget) {
      let existing = window.echarts.getInstanceByDom(this.sparkBalanceTarget)
      if (existing) existing.dispose()
      const chart = window.echarts.init(this.sparkBalanceTarget)
      this.charts.push(chart)
      chart.setOption({
        backgroundColor: 'transparent',
        grid: { left: 0, right: 0, top: 5, bottom: 5 },
        xAxis: { type: 'category', show: false },
        yAxis: { type: 'value', show: false },
        series: [{
          type: 'line', data: [0, 100, 250, 180, 420, 600], smooth: true, symbol: 'none',
          lineStyle: { width: 2, color: '#009DFA' },
          areaStyle: {
            color: new window.echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(0,157,250,0.35)' },
              { offset: 1, color: 'rgba(0,157,250,0.0)' }
            ])
          }
        }]
      }, true)
    }

    // WinRate Sparkline (Half Donut Gauge)
    if (this.hasSparkWinRateTarget) {
      let existing = window.echarts.getInstanceByDom(this.sparkWinRateTarget)
      if (existing) existing.dispose()
      const chart = window.echarts.init(this.sparkWinRateTarget)
      this.charts.push(chart)
      const winVal = Math.min(Math.max(statsWinRate, 0), 100)
      const lossVal = Math.max(0, 100 - winVal - 3)
      chart.setOption({
        backgroundColor: 'transparent',
        series: [{
          type: 'pie', radius: ['65%', '95%'], center: ['50%', '75%'], startAngle: 180, endAngle: 0,
          avoidLabelOverlap: false, itemStyle: { borderRadius: 4 }, label: { show: false },
          data: [
            { value: winVal, itemStyle: { color: '#10b981' } },
            { value: 3, itemStyle: { color: '#6366f1' } },
            { value: Math.max(lossVal, 0), itemStyle: { color: '#f43f5e' } },
            { value: winVal + 3 + Math.max(lossVal, 0), itemStyle: { color: 'none' }, label: { show: false } }
          ]
        }]
      }, true)
    }

    // ProfitFactor Sparkline (Full Donut Ring Chart)
    if (this.hasSparkPfTarget) {
      let existing = window.echarts.getInstanceByDom(this.sparkPfTarget)
      if (existing) existing.dispose()
      const chart = window.echarts.init(this.sparkPfTarget)
      this.charts.push(chart)
      const pfVal = Math.min(Math.max(statsProfitFactor, 0), 20)
      const winRatio = pfVal > 0 ? (pfVal / (pfVal + 1)) * 100 : 50
      const lossRatio = 100 - winRatio
      chart.setOption({
        backgroundColor: 'transparent',
        series: [{
          type: 'pie', radius: ['60%', '90%'], center: ['50%', '50%'], avoidLabelOverlap: false,
          itemStyle: { borderRadius: 4 }, label: { show: false },
          data: [
            { value: Math.max(winRatio, 0), itemStyle: { color: '#10b981' } },
            { value: Math.max(lossRatio, 0), itemStyle: { color: '#f43f5e' } }
          ]
        }]
      }, true)
    }

    // Avg Win / Loss Sparkline (Horizontal Stacked Bar Chart)
    if (this.hasSparkAvgTarget) {
      let existing = window.echarts.getInstanceByDom(this.sparkAvgTarget)
      if (existing) existing.dispose()
      const chart = window.echarts.init(this.sparkAvgTarget)
      this.charts.push(chart)
      const winVal = Math.abs(statsAvgWin) || 100
      const lossVal = Math.abs(statsAvgLoss) || 50
      chart.setOption({
        backgroundColor: 'transparent',
        grid: { left: '0%', right: '0%', top: 'center', bottom: 'center', height: 18 },
        xAxis: { type: 'value', show: false },
        yAxis: { type: 'category', show: false, data: ['Avg'] },
        series: [
          { type: 'bar', stack: 'total', barWidth: 16, itemStyle: { color: '#10b981', borderRadius: [8, 0, 0, 8] }, data: [winVal] },
          { type: 'bar', stack: 'total', barWidth: 16, itemStyle: { color: '#ef4444', borderRadius: [0, 8, 8, 0] }, data: [lossVal] }
        ]
      }, true)
    }

  }

  // --- 5. DAILY PNL BAR CHART ---
  toggleDailyWindowMenu() {
    if (this.hasDailyWindowMenuTarget) {
      this.dailyWindowMenuTarget.classList.toggle("hidden")
    }
  }

  selectDailyWindow(event) {
    const val = event.currentTarget.dataset.value
    this.currentDailyWindow = val

    if (this.hasDailyWindowLabelTarget) {
      this.dailyWindowLabelTarget.innerText = val
    }

    if (this.hasDailyWindowMenuTarget) {
      this.dailyWindowMenuTarget.classList.add("hidden")
    }

    if (this.hasDailyWindowOptTargets) {
      this.dailyWindowOptTargets.forEach(li => {
        li.classList.remove('dark:bg-[#20244d]', 'bg-[#eef0ff]', 'dark:text-[#a5b4fc]', 'text-[#4f46e5]', 'font-[700]')
        li.classList.add('dark:text-[#e5e7eb]', 'text-[#1f2937]', 'font-[500]')
        const checkIcon = li.querySelector('.check-icon')
        if (checkIcon) checkIcon.classList.add('hidden')
      })

      event.currentTarget.classList.remove('dark:text-[#e5e7eb]', 'text-[#1f2937]', 'font-[500]')
      event.currentTarget.classList.add('dark:bg-[#20244d]', 'bg-[#eef0ff]', 'dark:text-[#a5b4fc]', 'text-[#4f46e5]', 'font-[700]')
      const currentCheck = event.currentTarget.querySelector('.check-icon')
      if (currentCheck) currentCheck.classList.remove('hidden')
    }

    this.renderDailyPnlBarChart()
  }

  renderDailyPnlBarChart() {
    const containers = []
    if (this.hasDailyPnlChartTarget) containers.push(this.dailyPnlChartTarget)
    const premiumEl = this.element.querySelector('#echarts-daily-pnl-premium')
    if (premiumEl && !containers.includes(premiumEl)) containers.push(premiumEl)

    if (containers.length === 0) return

    containers.forEach(container => {
      let existing = window.echarts.getInstanceByDom(container)
      if (existing) existing.dispose()

      const chart = window.echarts.init(container)
      this.charts.push(chart)

      const DAILY_PNL = [
        { n: 1, date: "2/24", pnl: -153 }, { n: 2, date: "2/25", pnl: -119 },
        { n: 3, date: "2/26", pnl: -211 }, { n: 4, date: "2/27", pnl: -976 },
        { n: 5, date: "3/2", pnl: -10 }, { n: 6, date: "3/3", pnl: 0 },
        { n: 7, date: "3/5", pnl: 170 }, { n: 8, date: "3/6", pnl: -115 },
        { n: 9, date: "3/9", pnl: 480 }, { n: 10, date: "3/10", pnl: 167 },
        { n: 11, date: "3/12", pnl: 265 }, { n: 12, date: "3/16", pnl: -7 },
        { n: 13, date: "3/18", pnl: 35 }, { n: 14, date: "3/19", pnl: 20 },
        { n: 15, date: "3/23", pnl: -125 }, { n: 16, date: "3/25", pnl: 224 },
        { n: 17, date: "3/27", pnl: 60 }, { n: 18, date: "3/31", pnl: -1 },
        { n: 19, date: "4/1", pnl: 670 }, { n: 20, date: "4/2", pnl: 130 },
        { n: 21, date: "4/7", pnl: 50 }, { n: 22, date: "4/8", pnl: 466 },
        { n: 23, date: "4/10", pnl: -133 }, { n: 24, date: "4/15", pnl: 364 },
        { n: 25, date: "4/20", pnl: -37 }, { n: 26, date: "4/22", pnl: -27 },
        { n: 27, date: "4/24", pnl: 102 }, { n: 28, date: "4/27", pnl: -71 },
        { n: 29, date: "4/29", pnl: 354 }, { n: 30, date: "4/30", pnl: 327 }
      ]

      const labels = DAILY_PNL.map(d => d.date)
      const values = DAILY_PNL.map(d => d.pnl)
      const nBarras = values.length || 1

      let maxAbs = Math.max(...values.map(Math.abs))
      let limit = Math.ceil(maxAbs / 500) * 500
      if (limit === 0) limit = 1000
      const interval = limit / 2

      const isDarkGlobal = this.isDark
      const cGreen = isDarkGlobal ? '#12a56f' : '#10a56d'
      const cRed = isDarkGlobal ? '#d93a58' : '#e5365c'
      const cAxisText = isDarkGlobal ? '#8b8fa3' : '#8b93a7'
      const cZeroLine = isDarkGlobal ? 'rgba(255,255,255,0.20)' : '#cfd4e0'
      const gridLineColor = isDarkGlobal ? 'rgba(255,255,255,0.08)' : 'rgba(15,23,42,0.08)'

      chart.setOption({
        backgroundColor: 'transparent',
        animationDuration: 600,
        grid: { left: 70, right: 28, top: 23, bottom: 42, containLabel: false },
        tooltip: {
          trigger: 'axis',
          axisPointer: { type: 'shadow', shadowStyle: { color: 'rgba(0,0,0,0.04)' } },
          backgroundColor: isDarkGlobal ? '#222222' : '#ffffff',
          borderColor: isDarkGlobal ? '#333333' : '#e3e6ee',
          borderWidth: 1, padding: [8, 10],
          textStyle: { color: isDarkGlobal ? '#ffffff' : '#111827', fontSize: 12 },
          extraCssText: isDarkGlobal ? 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.6)' : 'border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,0.08)',
          formatter: params => {
            if (!params || !params.length) return ''
            const p = params[0]
            const val = p.value
            const sign = val < 0 ? '-' : ''
            const color = val >= 0 ? cGreen : cRed
            return `
              <div style="font-family:'Outfit',system-ui,sans-serif;min-width:90px;padding:2px">
                <div style="font-size:11px;color:#999;margin-bottom:4px;font-weight:600">Día ${p.name}</div>
                <div style="font-size:15px;font-weight:800;color:${color}">${sign}$${Math.abs(val).toLocaleString('en-US', {minimumFractionDigits: 2})}</div>
              </div>`
          }
        },
        xAxis: {
          type: 'category', data: labels, axisLine: { show: false }, axisTick: { show: false },
          axisLabel: {
            color: cAxisText, fontSize: 11, margin: 20,
            interval: (idx) => {
              const step = Math.ceil(nBarras / 15) || 1
              return ((nBarras - 1) - idx) % step === 0
            }
          },
          splitLine: { show: false }
        },
        yAxis: {
          type: 'value', min: -limit, max: limit, interval: interval,
          axisLine: { show: false }, axisTick: { show: false },
          axisLabel: {
            color: cAxisText, fontSize: 11, margin: 12,
            formatter: v => v === 0 ? '$0' : (v > 0 ? `$${v}` : `$-${Math.abs(v)}`)
          },
          splitLine: { show: true, lineStyle: { color: gridLineColor, type: 'dashed' } }
        },
        series: [{
          type: 'bar', barCategoryGap: '19%', barMinHeight: 1,
          itemStyle: {
            borderRadius: 4,
            color: p => (p.value || 0) >= 0 ? cGreen : cRed
          },
          emphasis: { itemStyle: { opacity: 0.92 } },
          data: values.map(v => ({ value: v, itemStyle: { color: v >= 0 ? cGreen : cRed } })),
          markLine: {
            silent: true, symbol: 'none',
            lineStyle: { color: cZeroLine, type: 'solid', width: 1 },
            label: { show: false },
            data: [{ yAxis: 0 }]
          }
        }]
      }, true)
    })
  }

  // --- 6. SCATTER CHART ---
  renderScatterChart() {
    if (!this.hasScatterChartTarget) return

    const container = this.scatterChartTarget
    let existing = window.echarts.getInstanceByDom(container)
    if (existing) existing.dispose()

    const chart = window.echarts.init(container)
    this.charts.push(chart)

    const scData = this.durationsValue || []
    const wins = Array.isArray(scData) ? scData.filter(d => d && d.result === 'win').map(d => [Number(d.duration)||0, Number(d.pnl)||0]) : []
    const loss = Array.isArray(scData) ? scData.filter(d => d && d.result === 'loss').map(d => [Number(d.duration)||0, Number(d.pnl)||0]) : []

    const textColor = this.isDark ? "#9DA3B4" : "#475569"
    const borderColor = this.isDark ? "#23263A" : "#E2E8F0"
    const tooltipBg = this.isDark ? "#1a1a1f" : "#ffffff"
    const tooltipText = this.isDark ? "#e5e5e5" : "#0f172a"

    chart.setOption({
      tooltip: { trigger: 'item', formatter: (p) => (p.value[0]||0) + ' mins <br> P&L: $' + (p.value[1]||0), backgroundColor: tooltipBg, borderColor: borderColor, textStyle: { color: tooltipText } },
      grid: { left: '3%', right: '3%', bottom: '3%', top: '8%', containLabel: true },
      xAxis: { type: 'value', name: 'min', splitLine: { show: false }, axisLabel: { color: textColor, fontSize: 9 } },
      yAxis: { type: 'value', splitLine: { lineStyle: { color: borderColor, type: 'dashed' } }, axisLabel: { color: textColor, fontSize: 9 } },
      series: [
        { type: 'scatter', symbolSize: 7, itemStyle: { color: '#10B981' }, data: wins.length ? wins : [[0,0]] },
        { type: 'scatter', symbolSize: 7, itemStyle: { color: '#F43F5E' }, data: loss.length ? loss : [[0,0]] }
      ]
    }, true)
  }

  // --- 7. PORTFOLIO DONUT CHART ---
  renderPortfolioDonutChart() {
    if (!this.hasPortfolioChartTarget) return

    const container = this.portfolioChartTarget
    let existing = window.echarts.getInstanceByDom(container)
    if (existing) existing.dispose()

    const chart = window.echarts.init(container)
    this.charts.push(chart)

    const portData = this.portfolioValue || []
    const pColors = ['#8B5CF6', '#34D399', '#FB7185', '#FBBF24']
    const finalData = portData.map((d, i) => ({ value: d.value, name: d.name, itemStyle: { color: pColors[i] } }))

    if (finalData.length === 0) {
      finalData.push({ value: 1, name: 'Sin datos', itemStyle: { color: '#475569' } })
    }

    chart.setOption({
      tooltip: { show: false },
      series: [{
        type: 'pie', radius: ['65%', '80%'], center: ['50%', '50%'],
        avoidLabelOverlap: false, label: { show: false },
        itemStyle: { borderRadius: 14 }, data: finalData
      }]
    }, true)
  }
}
