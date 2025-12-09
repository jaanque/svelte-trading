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
    const now = new Date();

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
             // Default custom to 30d if not set? Or wait?
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
        // Add end date filter for custom
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

    // If no history, maybe fake it for demo or show just current point?
    // If we just inserted the user, they might have 0 history or just 1 point.
    // Let's ensure we have at least the current point if needed.

    // Normalize data
    historyData = data || [];

    // If we have less than 2 points, chart looks weird.
    // We can add the current price as the "latest" point if the last history point is old?
    // Or just rely on what we have.

    // Ensure we have data points
    if (historyData.length === 0 && $userProfile) {
        // Fake a starting point if absolutely empty
        historyData = [
             { price: 50, created_at: new Date(Date.now() - 86400000).toISOString() }, // yesterday
             { price: $userProfile.price || 50, created_at: new Date().toISOString() }
        ];
    } else if (historyData.length === 1) {
        // If only 1 point, duplicate it to show a line
         historyData.unshift({
             price: historyData[0].price,
             created_at: new Date(new Date(historyData[0].created_at).getTime() - 3600000).toISOString()
         });
    }

    // Calculate change
    if (historyData.length > 0) {
        startValue = historyData[0].price;
        const endVal = historyData[historyData.length - 1].price;
        // Or should we use current profile price as end val? Usually yes.
        // Let's use the data we plotted.

        const diff = endVal - startValue;
        percentageChange = (diff / startValue) * 100;

        // Update current value display to match chart end for consistency?
        // Or keep live value. Let's keep live value $userProfile.price usually.
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
        // Format based on range
        if (timeRange === '24h') return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    });

    const dataPoints = historyData.map(d => d.price);

    // Gradient
    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    // Green or Red based on trend?
    const isPositive = percentageChange >= 0;
    const color = isPositive ? '#77DD77' : '#FF6961'; // Pastel Green or Red

    gradient.addColorStop(0, isPositive ? 'rgba(119, 221, 119, 0.5)' : 'rgba(255, 105, 97, 0.5)');
    gradient.addColorStop(1, isPositive ? 'rgba(119, 221, 119, 0.0)' : 'rgba(255, 105, 97, 0.0)');

    chartInstance = new Chart(chartCanvas, {
      type: "line",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Price",
            data: dataPoints,
            borderColor: color,
            backgroundColor: gradient,
            borderWidth: 2,
            pointRadius: 0, // Hide points for cleaner look
            pointHoverRadius: 4,
            fill: true,
            tension: 0.4, // Smooth curve
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
          legend: {
            display: false,
          },
          tooltip: {
             backgroundColor: 'rgba(255, 255, 255, 0.9)',
             titleColor: '#000',
             bodyColor: '#000',
             borderColor: '#E1E8ED',
             borderWidth: 1,
             displayColors: false,
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
            },
            ticks: {
                maxTicksLimit: 6,
                color: '#8899A6'
            }
          },
          y: {
            display: false, // Hide Y axis for cleaner look? Or minimal?
            // Let's hide it like many stock apps, or show on right.
            // keeping it hidden for "currada" look, rely on tooltip
          },
        },
      },
    });
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
    // Check if user is logged in
    // If not, maybe redirect? Or show empty?
    // Assuming protected route logic exists or we just show blank.
    if ($userProfile) {
        fetchHistory();
    }
    // Watch for profile load
    const unsubscribe = userProfile.subscribe(val => {
        if (val) {
             currentValue = val.price || 50;
             // Only fetch if not already loading or empty
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
              <span class="currency-symbol"></span>{currentValue}
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
          {#if loading && historyData.length === 0}
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
  }

  .header {
      margin-bottom: 24px;
  }

  h1 {
      margin-bottom: 12px;
  }

  .value-card {
      display: flex;
      flex-direction: column;
  }

  .current-value {
      font-size: 42px;
      font-weight: 800;
      color: var(--text-main);
      line-height: 1;
      margin-bottom: 8px;
      font-family: var(--font-family-main);
  }

  .change-indicator {
      display: flex;
      align-items: center;
      font-size: 16px;
      font-weight: 600;
      gap: 4px;
  }

  .change-indicator.positive {
      color: var(--success-color);
  }

  .change-indicator.negative {
      color: var(--danger-color);
  }

  /* Chart Section */
  .chart-section {
      background-color: var(--bg-main);
      border-radius: 24px;
      /* padding: 24px; */
      /* Clean look, maybe no padding or minimal */
  }

  .chart-controls {
      display: flex;
      gap: 8px;
      margin-bottom: 16px;
      overflow-x: auto;
      padding-bottom: 4px;
  }

  .range-btn {
      padding: 6px 12px;
      border-radius: 8px;
      background: transparent;
      border: 1px solid transparent; /* var(--border-color); */
      font-weight: 600;
      color: var(--text-secondary);
      font-size: 14px;
      transition: all 0.2s;
  }

  .range-btn:hover {
      background-color: var(--bg-hover);
      color: var(--text-main);
  }

  .range-btn.active {
      background-color: var(--bg-secondary);
      color: var(--text-main);
      /* border-color: var(--border-strong); */
      box-shadow: var(--shadow-sm);
  }

  /* Custom Date */
  .custom-date-picker {
      display: flex;
      gap: 12px;
      align-items: flex-end;
      margin-bottom: 16px;
      background-color: var(--bg-secondary);
      padding: 12px;
      border-radius: 12px;
  }

  .date-input {
      display: flex;
      flex-direction: column;
      gap: 4px;
  }

  .date-input label {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
  }

  .date-input input {
      padding: 8px;
      border-radius: 8px;
      border: 1px solid var(--border-color);
      font-family: inherit;
  }

  .apply-btn {
      padding: 8px 16px;
      background-color: var(--primary-color);
      color: white;
      border-radius: 8px;
      font-weight: 700;
      height: 38px;
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
      background-color: rgba(255,255,255,0.5);
      z-index: 1;
  }
</style>
