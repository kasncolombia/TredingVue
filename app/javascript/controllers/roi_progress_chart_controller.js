import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "empty"]
  static values = { payload: Object }

  connect() {
    console.log("[ROI Chart] Conectando controlador con Hotwire...");
    this.chart = null;
    
    // Auto-cargamos Chart.js dinámicamente si no existe
    if (window.Chart) {
      console.log("[ROI Chart] Chart.js ya está cacheado, renderizando...");
      this.render();
    } else {
      console.log("[ROI Chart] Cargando Chart.js desde CDN...");
      const script = document.createElement("script");
      script.src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js";
      script.onload = () => {
        console.log("[ROI Chart] Chart.js cargado, renderizando gráfico...");
        this.render();
      };
      script.onerror = () => {
        console.error("[ROI Chart] ERROR crítico: No se pudo cargar Chart.js desde CDN.");
      }
      document.head.appendChild(script);
    }
  }

  disconnect() {
    this.chart?.destroy()
  }

  payloadValueChanged() {
    if (window.Chart) this.render();
  }

  render() {
    const data = this.payloadValue;
    console.log("[ROI Chart] Renderizando con datos:", data);

    const hasData = data && data.labels && data.labels.length > 0;
    
    if (this.hasEmptyTarget) this.emptyTarget.classList.toggle("hidden", hasData);
    if (this.hasCanvasTarget) this.canvasTarget.parentElement.classList.toggle("hidden", !hasData);
    
    if (!hasData) {
        console.log("[ROI Chart] Operación abortada: No hay datos en las labels.");
        return;
    }

    if (this.chart) {
      this.chart.destroy();
    }

    if (!this.hasCanvasTarget) {
      console.error("[ROI Chart] ERROR: Elemento DOM <canvas> no encontrado.");
      return;
    }

    const ctx = this.canvasTarget.getContext("2d");

    // Areas / Glow
    const gradRetorno = ctx.createLinearGradient(0, 0, 0, 400);
    gradRetorno.addColorStop(0, 'rgba(135,89,232,0.3)');
    gradRetorno.addColorStop(1, 'rgba(135,89,232,0)');

    const gradIngresos = ctx.createLinearGradient(0, 0, 0, 400);
    gradIngresos.addColorStop(0, 'rgba(25,211,162,0.15)');
    gradIngresos.addColorStop(1, 'rgba(25,211,162,0)');

    const gradGastos = ctx.createLinearGradient(0, 0, 0, 400);
    gradGastos.addColorStop(0, 'rgba(240,68,93,0.15)');
    gradGastos.addColorStop(1, 'rgba(240,68,93,0)');

    // Plugin para Crosshair Vertical Estilo Financiero
    const verticalLinePlugin = {
      id: 'verticalLinePlugin',
      afterDraw: (chart) => {
        if (chart.tooltip?._active && chart.tooltip._active.length) {
          const activePoint = chart.tooltip._active[0];
          const chartCtx = chart.ctx;
          const topY = chart.scales.y.top;
          const bottomY = chart.scales.y.bottom;
          const currentX = activePoint.element.x;

          chartCtx.save();
          chartCtx.beginPath();
          chartCtx.moveTo(currentX, topY);
          chartCtx.lineTo(currentX, bottomY);
          chartCtx.lineWidth = 1;
          chartCtx.strokeStyle = 'rgba(255,255,255,0.15)';
          chartCtx.setLineDash([4, 4]);
          chartCtx.stroke();
          chartCtx.restore();
        }
      }
    };

    const dsRetorno = data.retorno || data.roi || [];

    const config = {
      type: 'line',
      data: {
        labels: data.labels,
        datasets: [
          {
            label: 'Ingresos',
            data: data.ingresos,
            borderColor: '#19D3A2', // Verde/Turquesa exacto
            borderWidth: 2,
            tension: 0.4,
            fill: 'origin',
            backgroundColor: gradIngresos,
            pointBackgroundColor: '#19D3A2',
            pointBorderColor: '#19D3A2',
            pointRadius: 2,
            pointHoverRadius: 4,
            order: 1
          },
          {
            label: 'Gastos',
            data: data.gastos,
            borderColor: '#F0445D', // Rojo exacto
            borderWidth: 2,
            tension: 0.4,
            fill: 'origin',
            backgroundColor: gradGastos,
            pointBackgroundColor: '#F0445D',
            pointBorderColor: '#F0445D',
            pointRadius: 2,
            pointHoverRadius: 4,
            order: 2
          },
          {
            label: 'Retorno de inversión',
            data: dsRetorno,
            borderColor: '#8759E8', // Morado exacto
            borderWidth: 2.5,
            tension: 0.4,
            fill: 'origin',
            backgroundColor: gradRetorno,
            pointBackgroundColor: '#8759E8',
            pointBorderColor: '#8759E8',
            pointRadius: 3,
            pointHoverRadius: 6,
            pointHoverBorderColor: '#ffffff',
            pointHoverBorderWidth: 2,
            order: 3
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        animation: {
          duration: 800,
          easing: 'easeOutQuart'
        },
        layout: {
          padding: { left: 0, right: 10, top: 20, bottom: 0 }
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              usePointStyle: true,
              pointStyle: 'line',
              color: '#8B95AA',
              font: { size: 12, family: 'Inter, system-ui, sans-serif' },
              padding: 20
            }
          },
          tooltip: {
            backgroundColor: 'rgba(11,22,33,0.95)',
            borderColor: 'rgba(255,255,255,0.08)',
            borderWidth: 1,
            borderRadius: 8,
            padding: { top: 12, left: 12, right: 24, bottom: 12 },
            titleColor: '#ffffff',
            titleFont: { size: 13, weight: 'bold', family: 'Inter, system-ui, sans-serif' },
            titleMarginBottom: 10,
            bodySpacing: 6,
            callbacks: {
              title: function(context) {
                return context[0].label;
              },
              label: function(context) {
                const label = context.dataset.label || '';
                const value = context.parsed.y;
                return `${label}: $${(value || 0).toLocaleString('en-US')}`;
              },
              labelColor: function() {
                return { borderColor: 'transparent', backgroundColor: 'transparent' };
              },
              labelTextColor: function(context) {
                if (context.dataset.label === 'Ingresos') return '#19D3A2';
                if (context.dataset.label === 'Gastos') return '#F0445D';
                if (context.dataset.label === 'Retorno de inversión') return '#8759E8';
                return '#ffffff';
              }
            },
            usePointStyle: false,
            displayColors: false
          }
        },
        scales: {
          x: {
            type: 'category',
            grid: {
              color: 'rgba(255,255,255,0.04)',
              drawBorder: false
            },
            ticks: {
              color: '#6B7280',
              font: { size: 11, family: 'Inter, system-ui, sans-serif' },
              maxRotation: 45,
              minRotation: 0,
              padding: 6
            },
            border: { display: false }
          },
          y: {
            grid: {
              color: (ctx) => ctx.tick.value === 0 ? 'rgba(255,255,255,0.1)' : 'rgba(255,255,255,0.04)',
              drawBorder: false
            },
            ticks: {
              color: '#6B7280',
              font: { size: 11, family: 'Inter, system-ui, sans-serif' },
              padding: 10,
              callback: function(value) {
                if (value === 0) return '0';
                return (value > 0 ? '' : '-') + Math.abs(value).toLocaleString('en-US');
              }
            },
            border: { display: false }
          }
        }
      },
      plugins: [verticalLinePlugin]
    };

    console.log("[ROI Chart] Instanciando Chart...");
    this.chart = new window.Chart(ctx, config);

    // Initial tooltip display
    if (data.labels && data.labels.length > 7) {
      window.Chart.defaults.animation = false;
      try {
        this.chart.setActiveElements([
            {datasetIndex: 0, index: data.labels.length - 2},
            {datasetIndex: 1, index: data.labels.length - 2},
            {datasetIndex: 2, index: data.labels.length - 2}
        ]);
        this.chart.tooltip.setActiveElements([
            {datasetIndex: 0, index: data.labels.length - 2},
            {datasetIndex: 1, index: data.labels.length - 2},
            {datasetIndex: 2, index: data.labels.length - 2}
        ]);
        this.chart.update();
      } catch (e) { console.warn("[ROI Chart] Tooltip inicial falido", e) }
      window.Chart.defaults.animation = true;
    }
  }
}
