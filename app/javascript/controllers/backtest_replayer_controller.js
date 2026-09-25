import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "chartContainer", "playBtn", "pauseBtn", "timeframeSelect", "speedSelect", 
    "legendTime", "legendO", "legendH", "legendL", "legendC", "legendV", 
    "headerTime", "headerSymbol", "headerTimeframe", "loadingOverlay",
    "balanceDisplay", "unrealizedPnlDisplay", "quantityInput", "slInput", "tpInput",
    "activePositionContainer", "tradesListContainer", "progressBar", "progressText",
    "rrDisplay", "metricsContainer"
  ]
  static values = {
    sessionId: String,
    initialState: String,
    speed: Number
  }

  // ==========================================
  // 1. STIMULUS LIFECYCLE
  // ==========================================
  connect() {
    this.isPlaying = this.initialStateValue === "playing"
    this.currentSpeedMultiplier = this.speedValue || 1
    this.pollTimeout = null
    this.bars = []
    this.currentBarIndex = 0
    this.markers = []
    this.showEma = false
    
    // Live Position & Balance state
    this.activePosition = null
    this.executedTrades = []
    this.initialBalance = this.hasBalanceDisplayTarget && this.balanceDisplayTarget.dataset.initialBalance ? parseFloat(this.balanceDisplayTarget.dataset.initialBalance) : 100000.00
    this.currentBalance = this.initialBalance

    this.handleFullscreenChange = () => {
      setTimeout(() => {
        // Reset scroll on all parent containers to prevent clipping
        const parentCanvas = this.element.closest('.content-canvas')
        if (parentCanvas) parentCanvas.scrollTop = 0

        const parentInner = this.element.closest('.content-inner')
        if (parentInner) parentInner.scrollTop = 0

        if (this.hasActivePositionContainerTarget && this.activePositionContainerTarget.parentElement) {
          const sidebar = this.activePositionContainerTarget.closest('.overflow-y-auto')
          if (sidebar) sidebar.scrollTop = 0
        }

        if (this.chartContainerTarget && this.chart) {
          const rect = this.chartContainerTarget.getBoundingClientRect()
          if (rect.width > 0 && rect.height > 0) {
            this.chart.applyOptions({ width: rect.width, height: rect.height })
          }
        }
        window.dispatchEvent(new Event('resize'))
      }, 100)
    }
    document.addEventListener("fullscreenchange", this.handleFullscreenChange)

    this.initChart()
    this.bindHotkeys()
    this.updateRrRatio()
    this.loadData()
  }

  disconnect() {
    if (this.handleFullscreenChange) document.removeEventListener("fullscreenchange", this.handleFullscreenChange)
    if (this.resizeObserver) this.resizeObserver.disconnect()
    if (this.pollTimeout) clearTimeout(this.pollTimeout)
    if (this.keyHandler) window.removeEventListener("keydown", this.keyHandler)
    if (this.chart) this.chart.remove()
  }

  bindHotkeys() {
    this.keyHandler = (e) => {
      // Don't trigger hotkeys when typing in inputs
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(e.target.tagName)) return

      if (e.code === 'Space') {
        e.preventDefault()
        this.togglePlay()
      } else if (e.code === 'ArrowRight') {
        e.preventDefault()
        this.stepForward()
      } else if (e.code === 'ArrowLeft') {
        e.preventDefault()
        this.stepBack()
      } else if (e.key === 'b' || e.key === 'B') {
        e.preventDefault()
        this.handleBuy()
      } else if (e.key === 's' || e.key === 'S') {
        e.preventDefault()
        this.handleSell()
      } else if (e.key === 'c' || e.key === 'C') {
        e.preventDefault()
        this.closeActivePosition()
      }
    }
    window.addEventListener("keydown", this.keyHandler)
  }

  // ==========================================
  // 2. CHART INITIALIZATION
  // ==========================================
  initChart() {
    const LW = window.LightweightCharts
    if (!LW) {
      console.error("LightweightCharts no está disponible en window.")
      this.showError("Error: Librería de gráficos no encontrada.")
      return
    }

    const container = this.chartContainerTarget
    const width = container.clientWidth || 800
    const height = container.clientHeight || 500

    this.chart = LW.createChart(container, {
      width: width,
      height: height,
      layout: {
        background: { type: 'solid', color: 'transparent' },
        textColor: '#94a3b8',
        fontFamily: "Inter, sans-serif"
      },
      grid: {
        vertLines: { color: 'rgba(255, 255, 255, 0.05)' },
        horzLines: { color: 'rgba(255, 255, 255, 0.05)' },
      },
      timeScale: {
        timeVisible: true,
        secondsVisible: false,
        borderVisible: false
      },
      crosshair: {
        mode: LW.CrosshairMode.Normal,
      }
    })

    this.candleSeries = this.chart.addCandlestickSeries({
      upColor: '#10B981',
      downColor: '#F43F5E',
      borderVisible: false,
      wickUpColor: '#10B981',
      wickDownColor: '#F43F5E',
      priceFormat: { type: 'price', precision: 2, minMove: 0.01 }
    })

    // Volume series
    this.volumeSeries = this.chart.addHistogramSeries({
      color: '#26a69a',
      priceFormat: { type: 'volume' },
      priceScaleId: '', 
      scaleMargins: { top: 0.8, bottom: 0 },
    })

    this.resizeObserver = new ResizeObserver(entries => {
      if (!entries.length || entries[0].target !== container) return
      const rect = entries[0].contentRect
      if (rect.width > 0 && rect.height > 0) {
        this.chart.applyOptions({ width: rect.width, height: rect.height })
      }
    })
    this.resizeObserver.observe(container)

    // Crosshair info sync
    this.chart.subscribeCrosshairMove((param) => {
      this.updateHeaderWithCrosshair(param)
    })
  }

  // ==========================================
  // 3. DATA LOADING & ANTI-LOOKAHEAD
  // ==========================================
  async loadData() {
    this.showLoading(true)
    try {
      const response = await fetch(`/backtesting/sessions/${this.sessionIdValue}/historical_data`)
      const data = await response.json()
      
      this.bars = data.bars || []
      this.currentBarIndex = data.cursor_index || 0

      if (this.bars.length === 0) {
        this.showError("No hay datos históricos disponibles para este símbolo.")
        return
      }

      this.renderVisibleBars()
      this.showLoading(false)

      if (this.isPlaying) {
        this.updateButtons()
        this.playEngine()
      }
    } catch (e) {
      console.error("Error cargando ventana histórica:", e)
      this.showError("No se pudieron cargar los datos de mercado.")
    }
  }

  renderVisibleBars() {
    const visibleBars = this.bars.slice(0, this.currentBarIndex + 1)
    if (visibleBars.length > 0) {
      this.candleSeries.setData(visibleBars)
      
      const volData = visibleBars.map(b => ({
        time: b.time,
        value: b.volume || 0,
        color: b.close >= b.open ? 'rgba(16, 185, 129, 0.4)' : 'rgba(244, 63, 94, 0.4)'
      }))
      this.volumeSeries.setData(volData)

      const lastBar = visibleBars[visibleBars.length - 1]
      this.updateDynamicHeader(lastBar)
      this.updateProgressScrubber()
      this.evaluateActivePosition(lastBar)
      if (this.showEma) this.renderEmaLines()
    }
  }

  updateProgressScrubber() {
    if (!this.bars || this.bars.length === 0) return
    const pct = Math.min(100, Math.max(0, ((this.currentBarIndex + 1) / this.bars.length) * 100))
    if (this.hasProgressBarTarget) this.progressBarTarget.style.width = `${pct.toFixed(1)}%`
    if (this.hasProgressTextTarget) this.progressTextTarget.innerText = `${pct.toFixed(0)}% (${this.currentBarIndex + 1}/${this.bars.length})`
  }

  // ==========================================
  // 4. REPLAY ENGINE & CONTROLS
  // ==========================================
  resetToStart(e) {
    if (e) e.preventDefault()
    if (this.isPlaying) this.togglePlay()
    
    this.currentBarIndex = 0
    this.markers = []
    this.candleSeries.setMarkers([])
    if (this.activePosition) this.clearActivePositionLines()
    this.activePosition = null
    this.updateActivePositionUI()
    this.renderVisibleBars()
    this.chart.timeScale().scrollToPosition(0, false)
  }

  async togglePlay(e) {
    if (e) e.preventDefault()
    
    if (!this.isPlaying) {
      this.isPlaying = true
      this.updateButtons()
      this.playEngine()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/play`, { method: 'POST', headers: this.headers() }).catch(()=>{})
    } else {
      this.isPlaying = false
      if (this.pollTimeout) clearTimeout(this.pollTimeout)
      this.updateButtons()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/pause`, { method: 'POST', headers: this.headers() }).catch(()=>{})
    }
  }

  stepForward(e) {
    if (e) e.preventDefault()
    if (this.isPlaying) this.togglePlay()
    
    if (this.currentBarIndex < this.bars.length - 1) {
      this.currentBarIndex++
      this.updateCurrentBar()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/next`, { method: 'POST', headers: this.headers() }).catch(()=>{})
    }
  }
  
  stepBack(e) {
    if (e) e.preventDefault()
    if (this.isPlaying) this.togglePlay()
    
    if (this.currentBarIndex > 0) {
      this.currentBarIndex--
      this.renderVisibleBars()
      this.candleSeries.setMarkers(this.markers.filter(m => m.time <= this.bars[this.currentBarIndex].time))
      fetch(`/backtesting/sessions/${this.sessionIdValue}/step_back`, { method: 'POST', headers: this.headers() }).catch(()=>{})
    }
  }

  playEngine() {
    if (!this.isPlaying) return

    if (this.currentBarIndex < this.bars.length - 1) {
      this.currentBarIndex++
      this.updateCurrentBar()
      
      let delay = 1000
      if (this.currentSpeedMultiplier == 5) delay = 200
      if (this.currentSpeedMultiplier == 20) delay = 50

      this.pollTimeout = setTimeout(() => this.playEngine(), delay)
    } else {
      this.isPlaying = false
      this.updateButtons()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/pause`, { method: 'POST', headers: this.headers() }).catch(()=>{})
    }
  }

  updateCurrentBar() {
    const bar = this.bars[this.currentBarIndex]
    this.candleSeries.update(bar)
    
    this.volumeSeries.update({
      time: bar.time,
      value: bar.volume || 0,
      color: bar.close >= bar.open ? 'rgba(16, 185, 129, 0.4)' : 'rgba(244, 63, 94, 0.4)'
    })
    
    this.updateDynamicHeader(bar)
    this.updateProgressScrubber()
    this.evaluateActivePosition(bar)
  }

  changeSpeed(e) {
    this.currentSpeedMultiplier = parseInt(e.target.value) || 1
  }

  changeTimeframe(e) {
    if (this.isPlaying) this.togglePlay()
    const newTf = e.target.value
    fetch(`/backtesting/sessions/${this.sessionIdValue}/change_timeframe`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({ timeframe: newTf })
    }).then(() => this.loadData())
  }

  // ==========================================
  // 5. LIVE TRADE EXECUTION & POSITION LOGIC
  // ==========================================
  handleBuy(e) {
    if (e) e.preventDefault()
    this.openPosition('BUY')
  }

  handleSell(e) {
    if (e) e.preventDefault()
    this.openPosition('SELL')
  }

  openPosition(type) {
    const currentBar = this.bars[this.currentBarIndex]
    if (!currentBar) return

    // Auto-close previous position if any
    if (this.activePosition) {
      this.closeActivePosition('Replaced')
    }

    const qtty = this.hasQuantityInputTarget ? parseFloat(this.quantityInputTarget.value) || 1 : 1
    const slPts = this.hasSlInputTarget ? parseFloat(this.slInputTarget.value) || 15 : 15
    const tpPts = this.hasTpInputTarget ? parseFloat(this.tpInputTarget.value) || 30 : 30

    const entryPrice = currentBar.close
    let slPrice = type === 'BUY' ? entryPrice - slPts : entryPrice + slPts
    let tpPrice = type === 'BUY' ? entryPrice + tpPts : entryPrice - tpPts

    const isBuy = type === 'BUY'
    const color = isBuy ? '#10B981' : '#F43F5E'

    // Price lines in Lightweight Charts
    const LW = window.LightweightCharts
    const entryLine = this.candleSeries.createPriceLine({
      price: entryPrice,
      color: '#3B82F6',
      lineWidth: 2,
      lineStyle: LW ? LW.LineStyle.Solid : 0,
      axisLabelVisible: true,
      title: `${type} @ ${entryPrice.toFixed(2)}`
    })

    const slLine = this.candleSeries.createPriceLine({
      price: slPrice,
      color: '#F43F5E',
      lineWidth: 1,
      lineStyle: LW ? LW.LineStyle.Dashed : 2,
      axisLabelVisible: true,
      title: `SL (${slPts} pts)`
    })

    const tpLine = this.candleSeries.createPriceLine({
      price: tpPrice,
      color: '#10B981',
      lineWidth: 1,
      lineStyle: LW ? LW.LineStyle.Dashed : 2,
      axisLabelVisible: true,
      title: `TP (${tpPts} pts)`
    })

    this.activePosition = {
      type: type,
      entryPrice: entryPrice,
      quantity: qtty,
      slPrice: slPrice,
      tpPrice: tpPrice,
      entryTime: currentBar.time,
      priceLines: { entryLine, slLine, tpLine }
    }

    // Add chart marker
    this.addMarker(type, color, isBuy ? 'arrowUp' : 'arrowDown', isBuy ? 'belowBar' : 'aboveBar')
    this.updateActivePositionUI()
  }

  evaluateActivePosition(currentBar) {
    if (!this.activePosition) return

    const pos = this.activePosition
    const high = currentBar.high
    const low = currentBar.low
    const close = currentBar.close

    let pnl = 0
    if (pos.type === 'BUY') {
      pnl = (close - pos.entryPrice) * pos.quantity * 50 // Multiplicador base (ej. Futuros 50/pt)
    } else {
      pnl = (pos.entryPrice - close) * pos.quantity * 50
    }

    // Update floating P&L display
    if (this.hasUnrealizedPnlDisplayTarget) {
      const isWin = pnl >= 0
      this.unrealizedPnlDisplayTarget.innerText = `${isWin ? '+' : ''}$${pnl.toFixed(2)}`
      this.unrealizedPnlDisplayTarget.className = `text-sm font-bold font-mono ${isWin ? 'text-emerald-500' : 'text-rose-500'}`
    }

    // Check SL / TP Trigger
    if (pos.type === 'BUY') {
      if (low <= pos.slPrice) {
        this.closeActivePosition('SL Hit', pos.slPrice)
      } else if (high >= pos.tpPrice) {
        this.closeActivePosition('TP Hit', pos.tpPrice)
      }
    } else if (pos.type === 'SELL') {
      if (high >= pos.slPrice) {
        this.closeActivePosition('SL Hit', pos.slPrice)
      } else if (low <= pos.tpPrice) {
        this.closeActivePosition('TP Hit', pos.tpPrice)
      }
    }

    if (this.activePosition) {
      this.updateActivePositionUI(pnl)
    }
  }

  closeActivePosition(reason = 'Manual', exitPriceOverride = null) {
    if (!this.activePosition) return

    const pos = this.activePosition
    const currentBar = this.bars[this.currentBarIndex]
    const exitPrice = exitPriceOverride || (currentBar ? currentBar.close : pos.entryPrice)

    let pnl = 0
    if (pos.type === 'BUY') {
      pnl = (exitPrice - pos.entryPrice) * pos.quantity * 50
    } else {
      pnl = (pos.entryPrice - exitPrice) * pos.quantity * 50
    }

    this.currentBalance += pnl

    // Record trade
    const tradeRecord = {
      type: pos.type,
      entryPrice: pos.entryPrice,
      exitPrice: exitPrice,
      quantity: pos.quantity,
      pnl: pnl,
      reason: reason,
      time: currentBar ? currentBar.time : pos.entryTime
    }
    this.executedTrades.unshift(tradeRecord)

    // Add Exit Marker
    const isWin = pnl >= 0
    this.addMarker(`${reason} ($${pnl >= 0 ? '+' : ''}${pnl.toFixed(0)})`, isWin ? '#10B981' : '#F43F5E', 'square', pos.type === 'BUY' ? 'aboveBar' : 'belowBar')

    // Clean lines
    this.clearActivePositionLines()
    this.activePosition = null

    // Update Balance UI
    if (this.hasBalanceDisplayTarget) {
      this.balanceDisplayTarget.innerText = `$${this.currentBalance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    }
    if (this.hasUnrealizedPnlDisplayTarget) {
      this.unrealizedPnlDisplayTarget.innerText = "$0.00"
      this.unrealizedPnlDisplayTarget.className = "text-sm font-bold font-mono text-slate-500"
    }

    this.updateActivePositionUI()
    this.updateTradesListUI()
    this.updateMetricsUI()
  }

  updateRrRatio() {
    if (!this.hasRrDisplayTarget) return
    const sl = this.hasSlInputTarget ? parseFloat(this.slInputTarget.value) || 15 : 15
    const tp = this.hasTpInputTarget ? parseFloat(this.tpInputTarget.value) || 30 : 30
    const ratio = sl > 0 ? (tp / sl).toFixed(2) : '0.00'
    this.rrDisplayTarget.innerText = `Ratio 1:${ratio}`
  }

  updateMetricsUI() {
    if (!this.hasMetricsContainerTarget) return
    const total = this.executedTrades.length
    if (total === 0) {
      this.metricsContainerTarget.innerHTML = `
        <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
          <span class="text-[9px] text-slate-400 font-bold block">WIN RATE</span>
          <span class="font-mono font-bold text-xs text-slate-700 dark:text-slate-200">—</span>
        </div>
        <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
          <span class="text-[9px] text-slate-400 font-bold block">PROFIT FACTOR</span>
          <span class="font-mono font-bold text-xs text-slate-700 dark:text-slate-200">—</span>
        </div>
        <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
          <span class="text-[9px] text-slate-400 font-bold block">TRADES</span>
          <span class="font-mono font-bold text-xs text-slate-700 dark:text-slate-200">0</span>
        </div>
      `
      return
    }

    const wins = this.executedTrades.filter(t => t.pnl > 0)
    const losses = this.executedTrades.filter(t => t.pnl < 0)
    const winRate = ((wins.length / total) * 100).toFixed(0)

    const grossProfit = wins.reduce((acc, t) => acc + t.pnl, 0)
    const grossLoss = Math.abs(losses.reduce((acc, t) => acc + t.pnl, 0))
    const profitFactor = grossLoss > 0 ? (grossProfit / grossLoss).toFixed(2) : (grossProfit > 0 ? '∞' : '0.00')

    this.metricsContainerTarget.innerHTML = `
      <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
        <span class="text-[9px] text-slate-400 font-bold block">WIN RATE</span>
        <span class="font-mono font-bold text-xs ${parseFloat(winRate) >= 50 ? 'text-emerald-500' : 'text-rose-500'}">${winRate}%</span>
      </div>
      <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
        <span class="text-[9px] text-slate-400 font-bold block">PROFIT FACTOR</span>
        <span class="font-mono font-bold text-xs text-brand">${profitFactor}</span>
      </div>
      <div class="bg-white/60 dark:bg-slate-800/40 p-1.5 rounded-lg border border-slate-200/60 dark:border-darkBorder">
        <span class="text-[9px] text-slate-400 font-bold block">TRADES</span>
        <span class="font-mono font-bold text-xs text-slate-700 dark:text-slate-200">${total}</span>
      </div>
    `
  }

  toggleEma(e) {
    if (e) e.preventDefault()
    this.showEma = !this.showEma
    const btn = e ? e.currentTarget : null

    if (this.showEma) {
      if (btn) btn.className = 'px-2 py-1 rounded-md text-[11px] font-extrabold border border-amber-500/40 bg-amber-500/10 text-amber-400 transition flex items-center gap-1'
      this.renderEmaLines()
    } else {
      if (btn) btn.className = 'px-2 py-1 rounded-md text-[11px] font-bold border border-slate-700 bg-slate-800 text-slate-300 hover:text-white transition flex items-center gap-1'
      if (this.ema9Series) this.chart.removeSeries(this.ema9Series)
      if (this.ema20Series) this.chart.removeSeries(this.ema20Series)
      this.ema9Series = null
      this.ema20Series = null
    }
  }

  renderEmaLines() {
    if (!this.chart || !this.bars || this.bars.length === 0) return
    const visibleBars = this.bars.slice(0, this.currentBarIndex + 1)
    if (visibleBars.length < 9) return

    const calcEma = (period) => {
      const k = 2 / (period + 1)
      let ema = visibleBars[0].close
      return visibleBars.map((bar, i) => {
        if (i === 0) {
          return { time: bar.time, value: ema }
        }
        ema = bar.close * k + ema * (1 - k)
        return { time: bar.time, value: ema }
      })
    }

    if (!this.ema9Series) {
      this.ema9Series = this.chart.addLineSeries({ color: '#F59E0B', lineWidth: 1.5, title: 'EMA 9' })
    }
    if (!this.ema20Series) {
      this.ema20Series = this.chart.addLineSeries({ color: '#3B82F6', lineWidth: 1.5, title: 'EMA 20' })
    }

    this.ema9Series.setData(calcEma(9))
    this.ema20Series.setData(calcEma(20))
  }

  clearActivePositionLines() {
    if (this.activePosition && this.activePosition.priceLines) {
      const { entryLine, slLine, tpLine } = this.activePosition.priceLines
      if (entryLine) this.candleSeries.removePriceLine(entryLine)
      if (slLine) this.candleSeries.removePriceLine(slLine)
      if (tpLine) this.candleSeries.removePriceLine(tpLine)
    }
  }

  updateActivePositionUI(currentFloatingPnl = 0) {
    if (!this.hasActivePositionContainerTarget) return

    if (!this.activePosition) {
      this.activePositionContainerTarget.innerHTML = `
        <div class="flex flex-col items-center justify-center text-center py-6 text-slate-400 space-y-2 border border-dashed border-slate-200 dark:border-darkBorder rounded-2xl">
          <span class="material-symbols-outlined text-3xl">inventory_2</span>
          <p class="text-xs font-medium">Sin posición activa.<br>Presiona BUY o SELL para simular.</p>
        </div>
      `
      return
    }

    const pos = this.activePosition
    const isBuy = pos.type === 'BUY'
    const isWin = currentFloatingPnl >= 0

    this.activePositionContainerTarget.innerHTML = `
      <div class="p-3.5 rounded-2xl border ${isBuy ? 'border-emerald-500/30 bg-emerald-500/5' : 'border-rose-500/30 bg-rose-500/5'} space-y-3 font-sans shadow-sm">
        <div class="flex items-center justify-between">
          <span class="px-2 py-0.5 rounded font-extrabold text-[10px] uppercase ${isBuy ? 'bg-emerald-500/20 text-emerald-500' : 'bg-rose-500/20 text-rose-500'}">
            ${pos.type} ${pos.quantity} Lote(s)
          </span>
          <span class="font-mono text-xs font-black ${isWin ? 'text-emerald-500' : 'text-rose-500'}">
            ${isWin ? '+' : ''}$${currentFloatingPnl.toFixed(2)}
          </span>
        </div>

        <div class="grid grid-cols-3 gap-1 text-[11px] font-mono text-center bg-white/50 dark:bg-slate-800/50 p-2 rounded-xl border border-slate-200/50 dark:border-darkBorder/50">
          <div>
            <span class="text-[9px] text-slate-400 font-bold block">ENTRADA</span>
            <span class="font-bold text-slate-700 dark:text-slate-200">${pos.entryPrice.toFixed(2)}</span>
          </div>
          <div>
            <span class="text-[9px] text-slate-400 font-bold block">SL</span>
            <span class="font-bold text-rose-500">${pos.slPrice.toFixed(2)}</span>
          </div>
          <div>
            <span class="text-[9px] text-slate-400 font-bold block">TP</span>
            <span class="font-bold text-emerald-500">${pos.tpPrice.toFixed(2)}</span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <button data-action="click->backtest-replayer#closePartialPosition" class="py-2 bg-amber-500/15 hover:bg-amber-500/25 border border-amber-500/30 text-amber-500 rounded-xl text-[11px] font-bold transition-all shadow-xs flex items-center justify-center gap-1 cursor-pointer">
            <span class="material-symbols-outlined text-[13px]">pie_chart</span> Parcial 50%
          </button>
          <button data-action="click->backtest-replayer#closeActivePosition" class="py-2 bg-slate-800 hover:bg-slate-700 dark:bg-slate-700 dark:hover:bg-slate-600 text-white rounded-xl text-[11px] font-bold transition-all shadow-xs flex items-center justify-center gap-1 cursor-pointer">
            <span class="material-symbols-outlined text-[13px]">close</span> Cerrar 100%
          </button>
        </div>
      </div>
    `
  }

  updateTradesListUI() {
    if (!this.hasTradesListContainerTarget) return

    if (this.executedTrades.length === 0) {
      this.tradesListContainerTarget.innerHTML = `<p class="text-slate-400 text-center text-[11px] py-4">No se han ejecutado trades en esta sesión.</p>`
      return
    }

    this.tradesListContainerTarget.innerHTML = this.executedTrades.map((t, idx) => {
      const isWin = t.pnl >= 0
      return `
        <div class="p-2.5 rounded-xl bg-slate-50 dark:bg-slate-800/40 border border-slate-200 dark:border-darkBorder flex items-center justify-between">
          <div>
            <div class="flex items-center gap-1.5">
              <span class="font-bold text-[10px] uppercase px-1.5 py-0.2 rounded ${t.type === 'BUY' ? 'bg-emerald-500/15 text-emerald-500' : 'bg-rose-500/15 text-rose-500'}">${t.type}</span>
              <span class="font-mono text-slate-400 font-medium text-[10px]">${t.reason}</span>
            </div>
            <p class="text-[10px] font-mono text-slate-500 mt-1">In: ${t.entryPrice.toFixed(2)} → Out: ${t.exitPrice.toFixed(2)}</p>
          </div>
          <div class="text-right">
            <span class="font-mono font-black text-xs ${isWin ? 'text-emerald-500' : 'text-rose-500'}">
              ${isWin ? '+' : ''}$${t.pnl.toFixed(2)}
            </span>
          </div>
        </div>
      `
    }).join('')
  }

  addMarker(text, color, shape, position) {
    if (!this.bars[this.currentBarIndex]) return
    const time = this.bars[this.currentBarIndex].time
    
    this.markers.push({
      time: time,
      position: position,
      color: color,
      shape: shape,
      text: text
    })
    
    this.candleSeries.setMarkers(this.markers.filter(m => m.time <= time))
  }

  // ==========================================
  // 6. UI HELPERS (HEADER, CROSSHAIR)
  // ==========================================
  updateHeaderWithCrosshair(param) {
    if (!param.time || param.point.x < 0 || param.point.y < 0) {
      if (this.bars[this.currentBarIndex]) this.updateDynamicHeader(this.bars[this.currentBarIndex]);
      return
    }

    const priceData = param.seriesData.get(this.candleSeries)
    const volData = param.seriesData.get(this.volumeSeries)

    if (priceData) {
      priceData.volume = volData ? volData.value : 0
      priceData.time = param.time
      this.updateDynamicHeader(priceData)
    }
  }

  updateDynamicHeader(bar) {
    if (!bar) return
    const d = new Date(bar.time * 1000)
    if (this.hasHeaderTimeTarget) {
      this.headerTimeTarget.innerText = d.toLocaleString('en-US', { month: 'short', day: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit' })
    }
    
    if (this.hasLegendOTarget) this.legendOTarget.innerText = bar.open.toFixed(2)
    if (this.hasLegendHTarget) this.legendHTarget.innerText = bar.high.toFixed(2)
    if (this.hasLegendLTarget) this.legendLTarget.innerText = bar.low.toFixed(2)
    if (this.hasLegendCTarget) {
      this.legendCTarget.innerText = bar.close.toFixed(2)
      this.legendCTarget.className = bar.close >= bar.open ? 'text-emerald-500 font-bold ml-1' : 'text-rose-500 font-bold ml-1'
    }
    if (this.hasLegendVTarget) this.legendVTarget.innerText = bar.volume ? (bar.volume).toFixed(0) : '0'
  }

  updateButtons() {
    if (this.hasPlayBtnTarget) this.playBtnTarget.classList.toggle("hidden", this.isPlaying)
    if (this.hasPauseBtnTarget) this.pauseBtnTarget.classList.toggle("hidden", !this.isPlaying)
  }

  showLoading(show) {
    if (this.hasLoadingOverlayTarget) this.loadingOverlayTarget.classList.toggle("hidden", !show)
  }

  showError(msg) {
    this.showLoading(false)
    this.chartContainerTarget.innerHTML = `<div class="absolute inset-0 z-10 flex flex-col items-center justify-center text-slate-400 p-6 text-center"><span class="material-symbols-outlined text-4xl mb-2 text-rose-500">error</span><p class="font-bold">${msg}</p></div>`
  }

  toggleFullscreen(e) {
    if (e) e.preventDefault()
    const elem = this.element

    if (!document.fullscreenElement) {
      if (elem.requestFullscreen) {
        elem.requestFullscreen()
      } else if (elem.webkitRequestFullscreen) {
        elem.webkitRequestFullscreen()
      }
    } else {
      if (document.exitFullscreen) {
        document.exitFullscreen()
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen()
      }
    }
  }

  takeSnapshot(e) {
    if (e) e.preventDefault()
    if (!this.chart) return

    try {
      const canvas = this.chart.takeScreenshot()
      const link = document.createElement('a')
      const symbol = this.hasHeaderSymbolTarget ? this.headerSymbolTarget.innerText : 'chart'
      link.download = `TradeTres_Backtest_${symbol}_${Date.now()}.png`
      link.href = canvas.toDataURL('image/png')
      link.click()
    } catch (err) {
      console.error("Error al exportar captura:", err)
      alert("No se pudo generar la captura. Inténtalo de nuevo.")
    }
  }

  closePartialPosition(e) {
    if (e) e.preventDefault()
    if (!this.activePosition || this.activePosition.quantity <= 0.1) return

    const pos = this.activePosition
    const partialQty = (pos.quantity / 2).toFixed(1)
    const currentBar = this.bars[this.currentBarIndex]
    const exitPrice = currentBar ? currentBar.close : pos.entryPrice

    let pnl = 0
    if (pos.type === 'BUY') {
      pnl = (exitPrice - pos.entryPrice) * partialQty * 50
    } else {
      pnl = (pos.entryPrice - exitPrice) * partialQty * 50
    }

    this.currentBalance += pnl
    pos.quantity = (pos.quantity - partialQty).toFixed(1)

    // Record trade
    const tradeRecord = {
      type: pos.type,
      entryPrice: pos.entryPrice,
      exitPrice: exitPrice,
      quantity: partialQty,
      pnl: pnl,
      reason: 'Parcial 50%',
      time: currentBar ? currentBar.time : pos.entryTime
    }
    this.executedTrades.unshift(tradeRecord)

    // Add Exit Marker
    const isWin = pnl >= 0
    this.addMarker(`Parcial 50% ($${pnl >= 0 ? '+' : ''}${pnl.toFixed(0)})`, isWin ? '#10B981' : '#F43F5E', 'square', pos.type === 'BUY' ? 'aboveBar' : 'belowBar')

    // Update Balance UI
    if (this.hasBalanceDisplayTarget) {
      this.balanceDisplayTarget.innerText = `$${this.currentBalance.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    }

    this.updateActivePositionUI()
    this.updateTradesListUI()
    this.updateMetricsUI()
  }

  headers() {
    return {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
}

