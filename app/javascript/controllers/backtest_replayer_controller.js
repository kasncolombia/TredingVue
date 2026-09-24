import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "chartContainer", "playBtn", "pauseBtn", "timeframeSelect", "speedSelect", "legendTime", "legendO", "legendH", "legendL", "legendC", "legendV", "headerTime", "headerSymbol", "headerTimeframe", "loadingOverlay" ]
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

    this.initChart()
    this.loadData()
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
    if (this.pollTimeout) clearTimeout(this.pollTimeout)
    if (this.chart) this.chart.remove()
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
      },
      grid: {
        vertLines: { color: 'rgba(255, 255, 255, 0.05)' },
        horzLines: { color: 'rgba(255, 255, 255, 0.05)' },
      },
      timeScale: {
        timeVisible: true,
        secondsVisible: false,
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
      wickDownColor: '#F43F5E'
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
        this.showError("No hay datos históricos disponibles para este símbolo y período.")
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
    // ANTI-LOOKAHEAD: Solo pasamos al chart hasta el índice actual
    const visibleBars = this.bars.slice(0, this.currentBarIndex + 1)
    if (visibleBars.length > 0) {
      this.candleSeries.setData(visibleBars)
      
      // Mapear el color de volumen basado en el close/open
      const volData = visibleBars.map(b => ({
        time: b.time,
        value: b.volume || 0,
        color: b.close >= b.open ? 'rgba(16, 185, 129, 0.4)' : 'rgba(244, 63, 94, 0.4)'
      }))
      this.volumeSeries.setData(volData)

      // Actualizar el header estático (cuando el mouse no está encima)
      this.updateDynamicHeader(visibleBars[visibleBars.length - 1])
    }
  }

  // ==========================================
  // 4. REPLAY CONTROLS
  // ==========================================
  async togglePlay(e) {
    if (e) e.preventDefault()
    
    if (!this.isPlaying) {
      this.isPlaying = true
      this.updateButtons()
      this.playEngine()
      // Optional: send state to backend asynchronously so it resumes on reload
      fetch(`/backtesting/sessions/${this.sessionIdValue}/play`, { method: 'POST', headers: this.headers() })
    } else {
      this.isPlaying = false
      if (this.pollTimeout) clearTimeout(this.pollTimeout)
      this.updateButtons()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/pause`, { method: 'POST', headers: this.headers() })
    }
  }

  stepForward(e) {
    if (e) e.preventDefault()
    if (this.isPlaying) this.togglePlay()
    
    if (this.currentBarIndex < this.bars.length - 1) {
      this.currentBarIndex++
      this.updateCurrentBar()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/next`, { method: 'POST', headers: this.headers() })
    }
  }
  
  stepBack(e) {
    if (e) e.preventDefault()
    if (this.isPlaying) this.togglePlay()
    
    if (this.currentBarIndex > 0) {
      this.currentBarIndex--
      // Para Retroceder en LW Charts sin mirar el futuro usamos setData con slice
      this.renderVisibleBars()
      // Re-apply markers if they exist
      this.candleSeries.setMarkers(this.markers.filter(m => m.time <= this.bars[this.currentBarIndex].time))
      fetch(`/backtesting/sessions/${this.sessionIdValue}/step_back`, { method: 'POST', headers: this.headers() })
    }
  }

  playEngine() {
    if (!this.isPlaying) return

    if (this.currentBarIndex < this.bars.length - 1) {
      this.currentBarIndex++
      this.updateCurrentBar()
      
      // Sincronizar el backend asíncronamente (evita delay visual)
      // fetch(`/backtesting/sessions/${this.sessionIdValue}/next`, { method: 'POST', headers: this.headers() }).catch(()=>{})

      let delay = 1000 // 1x
      if (this.currentSpeedMultiplier == 5) delay = 200
      if (this.currentSpeedMultiplier == 20) delay = 50

      this.pollTimeout = setTimeout(() => this.playEngine(), delay)
    } else {
      this.isPlaying = false
      this.updateButtons()
      fetch(`/backtesting/sessions/${this.sessionIdValue}/pause`, { method: 'POST', headers: this.headers() })
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
    // Here we can trigger sync sidebar with currentPrice = bar.close
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
  // 5. TRADING (BUY/SELL MARKERS)
  // ==========================================
  handleBuy(e) {
    if (e) e.preventDefault()
    this.addMarker('BUY', '#10B981', 'arrowUp', 'belowBar')
  }

  handleSell(e) {
    if (e) e.preventDefault()
    this.addMarker('SELL', '#F43F5E', 'arrowDown', 'aboveBar')
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
      // Revertir a la última vela si está fuera del chart
      if (this.bars[this.currentBarIndex]) this.updateDynamicHeader(this.bars[this.currentBarIndex]);
      return
    }

    const priceData = param.seriesData.get(this.candleSeries)
    const volData = param.seriesData.get(this.volumeSeries)

    if (priceData) {
      priceData.volume = volData ? volData.value : 0
      priceData.time = param.time // timestamp real
      this.updateDynamicHeader(priceData)
    }
  }

  updateDynamicHeader(bar) {
    if (!bar) return
    const d = new Date(bar.time * 1000)
    // Set Header
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

  headers() {
    return {
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    }
  }
}
