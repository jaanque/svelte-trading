<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import Chart from "chart.js/auto";
  import { supabase } from "../../lib/supabase";
  import { Loader2, ArrowUpRight, ArrowDownRight } from "lucide-svelte";

  export let userId: string;
  export let currentPrice: number;

  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart | null = null;
  let loading = true;
  let historyData: any[] = [];
  let timeRange = "24h"; // 24h, 7d, 30d, 1y, all
  let startValue = 0;
  let percentageChange = 0;

  const ranges = [
    { label: "24H", value: "24h" },
    { label: "7D", value: "7d" },
    { label: "30D", value: "30d" },
    { label: "1Y", value: "1y" },
    { label: "All", value: "all" },
  ];

  async function fetchHistory() {
    if (!userId) return;
    loading = true;

    let startDate = new Date();
    if (timeRange === "24h") {
      startDate.setHours(startDate.getHours() - 24);
    } else if (timeRange === "7d") {
      startDate.setDate(startDate.getDate() - 7);
    } else if (timeRange === "30d") {
      startDate.setDate(startDate.getDate() - 30);
    } else if (timeRange === "1y") {
      startDate.setFullYear(startDate.getFullYear() - 1);
    } else if (timeRange === "all") {
      startDate = new Date(0);
    }

    const { data, error } = await supabase
      .from("price_history")
      .select("price, created_at")
      .eq("user_id", userId)
      .gte("created_at", startDate.toISOString())
      .order("created_at", { ascending: true });

    if (error) {
      console.error("Error fetching history:", error);
      loading = false;
      return;
    }

    let fetchedData = data || [];

    if (fetchedData.length === 0) {
        historyData = [
            { created_at: startDate.toISOString(), price: currentPrice },
            { created_at: new Date().toISOString(), price: currentPrice }
        ];
    } else {
        historyData = [...fetchedData];
        const lastPt = historyData[historyData.length-1];
        if (new Date().getTime() - new Date(lastPt.created_at).getTime() > 60000) {
             historyData.push({ created_at: new Date().toISOString(), price: currentPrice });
        }
    }

    if (historyData.length > 0) {
        startValue = historyData[0].price;
        const endVal = historyData[historyData.length - 1].price;
        const diff = endVal - startValue;
        percentageChange = startValue === 0 ? 0 : (diff / startValue) * 100;
    }

    renderChart();
    loading = false;
  }

  function renderChart() {
    if (!chartCanvas) return;

    const ctx = chartCanvas.getContext("2d");
    if (!ctx) return;

    if (chartInstance) {
      chartInstance.destroy();
    }

    const labels = historyData.map(d => {
        const date = new Date(d.created_at);
        return date; // Pass date objects for callback formatting
    });

    const dataPoints = historyData.map(d => d.price);

    const isPositive = percentageChange >= 0;
    const lineColor = isPositive ? '#77DD77' : '#FF6961';
    const fillColorStart = isPositive ? 'rgba(119, 221, 119, 0.2)' : 'rgba(255, 105, 97, 0.2)';
    const fillColorEnd = isPositive ? 'rgba(119, 221, 119, 0)' : 'rgba(255, 105, 97, 0)';

    const gradient = ctx.createLinearGradient(0, 0, 0, 300);
    gradient.addColorStop(0, fillColorStart);
    gradient.addColorStop(1, fillColorEnd);

    const minPrice = Math.min(...dataPoints);
    const maxPrice = Math.max(...dataPoints);
    const padding = (maxPrice - minPrice) * 0.1 || (currentPrice * 0.1) || 5;

    chartInstance = new Chart(chartCanvas, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Price",
            data: dataPoints,
            borderColor: lineColor,
            backgroundColor: gradient,
            borderWidth: 2,
            pointRadius: 0,
            pointHoverRadius: 6,
            pointBackgroundColor: lineColor,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            fill: true,
            tension: 0.1, // Less smoothing for detail
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
            mode: 'index',
            intersect: false,
        },
        plugins: {
          legend: { display: false },
          tooltip: {
             backgroundColor: 'rgba(255, 255, 255, 0.95)',
             titleColor: '#1F2937',
             bodyColor: '#1F2937',
             borderColor: '#E5E7EB',
             borderWidth: 1,
             padding: 12,
             displayColors: false,
             titleFont: { weight: 'bold', size: 14 },
             bodyFont: { size: 13 },
             callbacks: {
                 title: (context) => {
                     const date = new Date(context[0].label);
                     return date.toLocaleDateString(undefined, {
                         month: 'short', day: 'numeric', year: 'numeric',
                         hour: '2-digit', minute: '2-digit'
                     });
                 },
                 label: (context) => 'Price: ' + parseFloat(context.parsed.y).toFixed(2)
             }
          }
        },
        scales: {
          x: {
              display: true,
              type: 'category', // Chart.js 3+ might auto-detect time if adapter used, but we passed string/date objects.
              // Since we passed Date objects in labels map, Chart.js standard might need strings for category axis unless time scale is used.
              // Let's rely on formatted strings for labels to be safe without time adapter.
              ticks: {
                  maxTicksLimit: 6,
                  color: '#8899A6',
                  font: { size: 10 },
                  callback: function(val, index) {
                      // Labels are available via this.getLabelForValue(val)
                      const label = this.getLabelForValue(val as number);
                      // label is the Date object .toString() usually? No, we mapped to Date objects.
                      // Actually, let's map labels to strings for the X axis to avoid adapter dependency if not installed.
                      return ''; // We will override labels generation in data mapping
                  }
              },
              grid: { display: false }
          },
          y: {
            display: true,
            suggestedMin: minPrice - padding,
            suggestedMax: maxPrice + padding,
            grid: {
                color: 'rgba(0,0,0,0.05)'
            },
            ticks: {
                font: { size: 11 },
                color: '#8899A6'
            }
          },
        },
      },
    });

    // Fix X-axis labels to be strings for stability
    chartInstance.data.labels = historyData.map(d => {
        const date = new Date(d.created_at);
        if (timeRange === '24h') return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    });
    chartInstance.update();
  }

  function handleRangeChange(range: string) {
      timeRange = range;
      fetchHistory();
  }

  $: if (userId) {
      fetchHistory();
  }

  onDestroy(() => {
      if (chartInstance) chartInstance.destroy();
  });
</script>

<div class="chart-container">
  <div class="chart-header">
      <div class="stats">
          <div class="current-price">
              {currentPrice.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}
              <span class="currency">Tokens</span>
          </div>
          <div class="change {percentageChange >= 0 ? 'positive' : 'negative'}">
              {#if percentageChange >= 0}
                 <ArrowUpRight size={18} />
              {:else}
                 <ArrowDownRight size={18} />
              {/if}
              {Math.abs(percentageChange).toFixed(2)}% ({timeRange.toUpperCase()})
          </div>
      </div>

      <div class="controls">
          {#each ranges as range}
             <button
                class="range-btn {timeRange === range.value ? 'active' : ''}"
                on:click={() => handleRangeChange(range.value)}
             >
                {range.label}
             </button>
          {/each}
      </div>
  </div>

  <div class="canvas-wrapper">
      {#if loading}
         <div class="loading-overlay">
             <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
         </div>
      {/if}
      <canvas bind:this={chartCanvas}></canvas>
  </div>
</div>

<style>
  .chart-container {
      background-color: white;
      border-radius: 16px;
      padding: 24px;
      border: 1px solid var(--border-color);
      margin-top: 16px;
  }

  .chart-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 16px;
  }

  .current-price {
      font-size: 32px;
      font-weight: 800;
      color: var(--text-main);
      display: flex;
      align-items: baseline;
      gap: 8px;
  }

  .currency {
      font-size: 16px;
      font-weight: 500;
      color: var(--text-secondary);
  }

  .change {
      display: flex;
      align-items: center;
      font-weight: 700;
      font-size: 15px;
      margin-top: 4px;
  }
  .change.positive { color: var(--success-color); }
  .change.negative { color: var(--danger-color); }

  .controls {
      display: flex;
      background-color: var(--bg-secondary);
      border-radius: 12px;
      padding: 4px;
      gap: 2px;
  }

  .range-btn {
      padding: 6px 12px;
      border-radius: 8px;
      border: none;
      background: transparent;
      color: var(--text-secondary);
      font-weight: 600;
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
  }

  .range-btn:hover {
      background-color: rgba(255,255,255,0.5);
      color: var(--primary-color);
  }

  .range-btn.active {
      background-color: white;
      color: var(--text-main);
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  }

  .canvas-wrapper {
      position: relative;
      height: 350px;
      width: 100%;
  }

  .loading-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(255,255,255,0.8);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 10;
  }

  @media (max-width: 600px) {
      .chart-header {
          flex-direction: column;
          align-items: flex-start;
      }
      .controls {
          width: 100%;
          justify-content: space-between;
          overflow-x: auto;
      }
  }
</style>
