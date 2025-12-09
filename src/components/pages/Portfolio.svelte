<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import Chart from "chart.js/auto";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, ArrowUpRight, ArrowDownRight, Calendar } from "lucide-svelte";

  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart | null = null;
  let loading = true;
  let historyData: any[] = [];
  let timeRange = "24h"; // 24h, 7d, 30d, 1y, all, custom
  let customStartDate: string = "";
  let customEndDate: string = "";
  let showCustomDate = false;

  let currentValue = 0;
  let startValue = 0;
  let percentageChange = 0;

  // Reactively update current value from profile store
  $: if ($userProfile) {
      currentValue = $userProfile.price || 50;
  }

  const ranges = [
    { label: "24H", value: "24h" },
    { label: "7D", value: "7d" },
    { label: "30D", value: "30d" },
    { label: "1Y", value: "1y" },
    { label: "All", value: "all" },
    { label: "Custom", value: "custom" },
  ];

  async function fetchHistory() {
    if (!$userProfile) return;
    loading = true;

    let startDate = new Date();
    // Default start date logic
    if (timeRange === "24h") {
      startDate.setHours(startDate.getHours() - 24);
    } else if (timeRange === "7d") {
      startDate.setDate(startDate.getDate() - 7);
    } else if (timeRange === "30d") {
      startDate.setDate(startDate.getDate() - 30);
    } else if (timeRange === "1y") {
      startDate.setFullYear(startDate.getFullYear() - 1);
    } else if (timeRange === "all") {
      startDate = new Date(0); // Beginning of time
    } else if (timeRange === "custom") {
        if (customStartDate) {
            startDate = new Date(customStartDate);
        } else {
             startDate.setDate(startDate.getDate() - 30);
        }
    }

    let query = supabase
      .from("price_history")
      .select("price, created_at")
      .eq("user_id", $userProfile.id)
      .gte("created_at", startDate.toISOString())
      .order("created_at", { ascending: true });

    if (timeRange === "custom" && customEndDate) {
        const end = new Date(customEndDate);
        end.setHours(23, 59, 59);
        query = query.lte("created_at", end.toISOString());
    }

    const { data, error } = await query;

    if (error) {
      console.error("Error fetching history:", error);
      loading = false;
      return;
    }

    let fetchedData = data || [];
    console.log("Fetched History:", fetchedData);

    // If data is empty or sparse, generate fill data for a better chart visual
    // This is common in financial apps: if no trades, price is flat.
    // We will generate points from 'startDate' to 'now' based on the last known price.

    // 1. Get the starting price. Either the first point in range, or current profile price if nothing.
    // Actually, we need the price *before* the start date if possible, but we don't have it easily.
    // We'll assume the first available point's price, or current price.
    let basePrice = currentValue;
    if (fetchedData.length > 0) {
        basePrice = fetchedData[fetchedData.length - 1].price; // Use latest fetched price as anchor?
        // No, using current is safer.
        basePrice = currentValue;
    }

    // Logic: If no data in range, it means price has been flat at 'currentValue' (assuming no prior history lower/higher that we missed).
    // Or it means user is new.

    if (fetchedData.length < 2) {
        // Generate synthetic points for the chart range
        // e.g. Start point and End point
        const now = new Date();
        const startPoint = {
            price: basePrice,
            created_at: startDate.toISOString()
        };
        const endPoint = {
            price: basePrice,
            created_at: now.toISOString()
        };

        // If we have 1 point, keep it?
        if (fetchedData.length === 1) {
            // If that point is in the middle, we connect start -> point -> end
            // But usually we just want to show the trend.
            // Let's just overwrite with a nice flat line for stability if data is insufficient.
             historyData = [startPoint, ...fetchedData, endPoint];
             // Sort just in case
             historyData.sort((a,b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
        } else {
             historyData = [startPoint, endPoint];
        }
    } else {
        historyData = fetchedData;

        // Optional: Add a "now" point if the last point is old?
        const lastTime = new Date(historyData[historyData.length-1].created_at).getTime();
        const nowTime = new Date().getTime();
        if (nowTime - lastTime > 60000 * 5) { // If last point older than 5 mins
            historyData.push({
                price: currentValue,
                created_at: new Date().toISOString()
            });
        }
    }

    // Calculate change stats
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

    // Prepare Data
    const labels = historyData.map(d => {
        const date = new Date(d.created_at);
        if (timeRange === '24h') return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    });

    const dataPoints = historyData.map(d => d.price);

    // Styling based on positive/negative trend
    const isPositive = percentageChange >= 0;
    // Use slightly more vibrant/modern colors
    const lineColor = isPositive ? '#10B981' : '#EF4444'; // Emerald-500 or Red-500
    const fillColorStart = isPositive ? 'rgba(16, 185, 129, 0.2)' : 'rgba(239, 68, 68, 0.2)';
    const fillColorEnd = isPositive ? 'rgba(16, 185, 129, 0)' : 'rgba(239, 68, 68, 0)';

    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, fillColorStart);
    gradient.addColorStop(1, fillColorEnd);

    // Calculate nice Y axis bounds to avoid flat line looking weird
    const minPrice = Math.min(...dataPoints);
    const maxPrice = Math.max(...dataPoints);
    // Add 5% padding
    const padding = (maxPrice - minPrice) * 0.1 || (basePrice() * 0.1) || 5;
    const suggestedMin = minPrice - padding;
    const suggestedMax = maxPrice + padding;

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
            borderWidth: 3,
            pointRadius: 0,
            pointHoverRadius: 6,
            pointBackgroundColor: lineColor,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            fill: true,
            tension: 0.4, // Smooth curve
            spanGaps: true, // Connect lines if gaps
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
            duration: 1000,
            easing: 'easeOutQuart'
        },
        interaction: {
            mode: 'index',
            intersect: false,
        },
        plugins: {
          legend: {
            display: false,
          },
          tooltip: {
             backgroundColor: 'rgba(255, 255, 255, 0.95)',
             titleColor: '#1F2937',
             bodyColor: '#1F2937',
             borderColor: '#E5E7EB',
             borderWidth: 1,
             padding: 10,
             displayColors: false,
             titleFont: { weight: 'bold', size: 13 },
             bodyFont: { size: 13 },
             callbacks: {
                 label: function(context) {
                     return 'Price: ' + context.parsed.y;
                 }
             }
          }
        },
        scales: {
          x: {
            grid: {
              display: false,
              drawBorder: false,
            },
            ticks: {
                maxTicksLimit: 6,
                color: '#9CA3AF',
                font: { size: 11 }
            },
            border: { display: false }
          },
          y: {
            display: false, // Keep hidden for clean look
            suggestedMin: suggestedMin,
            suggestedMax: suggestedMax,
          },
        },
      },
    });
  }

  // Helper to get base price if everything is empty
  function basePrice() {
      return currentValue || 50;
  }

  function handleRangeChange(range: string) {
      timeRange = range;
      if (range === 'custom') {
          showCustomDate = true;
      } else {
          showCustomDate = false;
          fetchHistory();
      }
  }

  function applyCustomDate() {
      fetchHistory();
  }

  onMount(() => {
    if ($userProfile) {
        fetchHistory();
    }
    const unsubscribe = userProfile.subscribe(val => {
        if (val) {
             currentValue = val.price || 50;
             if (historyData.length === 0) fetchHistory();
        }
    });
    return unsubscribe;
  });

  onDestroy(() => {
      if (chartInstance) chartInstance.destroy();
  });
</script>

<div class="portfolio-container">
  <div class="header">
      <h1>My Portfolio</h1>

      <!-- Value Display -->
      <div class="value-card">
          <div class="current-value">
              {currentValue}
              <span class="currency-label">Credits</span>
          </div>
          <div class="change-indicator {percentageChange >= 0 ? 'positive' : 'negative'}">
              {#if percentageChange >= 0}
                 <ArrowUpRight size={20} />
              {:else}
                 <ArrowDownRight size={20} />
              {/if}
              <span>{Math.abs(percentageChange).toFixed(2)}% ({timeRange.toUpperCase()})</span>
          </div>
      </div>
  </div>

  <!-- Chart Section -->
  <div class="chart-section">
      <div class="chart-controls">
          {#each ranges as range}
             <button
                class="range-btn {timeRange === range.value ? 'active' : ''}"
                on:click={() => handleRangeChange(range.value)}
             >
                {range.label}
             </button>
          {/each}
      </div>

      {#if showCustomDate}
         <div class="custom-date-picker">
             <div class="date-input">
                 <label>Start</label>
                 <input type="date" bind:value={customStartDate} />
             </div>
             <div class="date-input">
                 <label>End</label>
                 <input type="date" bind:value={customEndDate} />
             </div>
             <button class="apply-btn" on:click={applyCustomDate}>Apply</button>
         </div>
      {/if}

      <div class="chart-wrapper">
          {#if loading}
             <div class="loading-overlay">
                 <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
             </div>
          {/if}
          <canvas bind:this={chartCanvas}></canvas>
      </div>
  </div>
</div>

<style>
  .portfolio-container {
      padding: 0;
      max-width: 100%;
      color: var(--text-main);
  }

  .header {
      margin-bottom: 24px;
  }

  h1 {
      margin-bottom: 12px;
      font-size: 24px;
      font-weight: 800;
  }

  .value-card {
      display: flex;
      flex-direction: column;
  }

  .current-value {
      font-size: 48px;
      font-weight: 900;
      color: var(--text-main);
      line-height: 1;
      margin-bottom: 8px;
      letter-spacing: -1px;
      display: flex;
      align-items: baseline;
      gap: 8px;
  }

  .currency-label {
      font-size: 16px;
      font-weight: 500;
      color: var(--text-secondary);
      letter-spacing: normal;
  }

  .change-indicator {
      display: flex;
      align-items: center;
      font-size: 15px;
      font-weight: 600;
      gap: 4px;
  }

  .change-indicator.positive {
      color: #10B981;
  }

  .change-indicator.negative {
      color: #EF4444;
  }

  /* Chart Section */
  .chart-section {
      background-color: var(--bg-main); /* or white if needed */
      border-radius: 24px;
      position: relative;
  }

  .chart-controls {
      display: flex;
      gap: 6px;
      margin-bottom: 24px;
      overflow-x: auto;
      padding-bottom: 4px;
      /* Scrollbar hiding */
      scrollbar-width: none;
  }
  .chart-controls::-webkit-scrollbar {
      display: none;
  }

  .range-btn {
      padding: 8px 16px;
      border-radius: 9999px;
      background: var(--bg-secondary);
      border: none;
      font-weight: 600;
      color: var(--text-secondary);
      font-size: 13px;
      cursor: pointer;
      transition: all 0.2s;
      white-space: nowrap;
  }

  .range-btn:hover {
      background-color: var(--bg-hover);
      color: var(--text-main);
  }

  .range-btn.active {
      background-color: var(--text-main); /* Dark active state like standard apps */
      color: var(--bg-main);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  }

  /* Custom Date */
  .custom-date-picker {
      display: flex;
      gap: 12px;
      align-items: flex-end;
      margin-bottom: 16px;
      background-color: var(--bg-secondary);
      padding: 16px;
      border-radius: 16px;
      flex-wrap: wrap;
  }

  .date-input {
      display: flex;
      flex-direction: column;
      gap: 6px;
  }

  .date-input label {
      font-size: 13px;
      color: var(--text-secondary);
      font-weight: 600;
  }

  .date-input input {
      padding: 10px;
      border-radius: 8px;
      border: 1px solid var(--border-color);
      font-family: inherit;
      background-color: var(--bg-main);
      color: var(--text-main);
  }

  .apply-btn {
      padding: 10px 20px;
      background-color: var(--primary-color);
      color: white;
      border-radius: 8px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      margin-top: auto;
  }

  .chart-wrapper {
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
      display: flex;
      align-items: center;
      justify-content: center;
      background-color: rgba(255,255,255,0.8);
      z-index: 2;
      border-radius: 24px;
      backdrop-filter: blur(4px);
  }
</style>
