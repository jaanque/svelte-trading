<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import Chart from "chart.js/auto";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, ArrowUpRight, ArrowDownRight, Calendar } from "lucide-svelte";
  import UserCard from "../general/UserCard.svelte";

  export let onNavigate: (path: string) => void = (path) => { window.location.href = path; };

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

  let holdings: any[] = [];
  let holdingsLoading = false;

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

    let basePrice = currentValue;
    if (fetchedData.length > 0) {
        basePrice = currentValue;
    }

    if (fetchedData.length < 2) {
        const now = new Date();
        const startPoint = {
            price: basePrice,
            created_at: startDate.toISOString()
        };
        const endPoint = {
            price: basePrice,
            created_at: now.toISOString()
        };

        if (fetchedData.length === 1) {
             historyData = [startPoint, ...fetchedData, endPoint];
             historyData.sort((a,b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
        } else {
             historyData = [startPoint, endPoint];
        }
    } else {
        historyData = fetchedData;
        const lastTime = new Date(historyData[historyData.length-1].created_at).getTime();
        const nowTime = new Date().getTime();
        if (nowTime - lastTime > 60000 * 5) {
            historyData.push({
                price: currentValue,
                created_at: new Date().toISOString()
            });
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

  async function fetchHoldings() {
    if (!$userProfile) return;
    holdingsLoading = true;

    // Fetch investments made by the user
    // We want to group by target_user_id and sum shares.
    // However, Supabase doesn't support grouping directly in client SDK easily for this structure without a view or rpc.
    // We'll fetch all and aggregate client-side for now (assuming not huge volume yet),
    // OR fetch distinct target users and then shares.

    // Better approach: fetch raw investments, then group by user.
    const { data, error } = await supabase
        .from("investments")
        .select(`
            amount_shares,
            target_user:profiles!target_user_id(id, username, full_name, avatar_url, price)
        `)
        .eq("investor_id", $userProfile.id);

    if (error) {
        console.error("Error fetching holdings:", error);
    } else {
        const aggregated = new Map();

        data.forEach((inv: any) => {
            const user = inv.target_user;
            if (!aggregated.has(user.id)) {
                aggregated.set(user.id, {
                    user: user,
                    totalShares: 0
                });
            }
            aggregated.get(user.id).totalShares += parseFloat(inv.amount_shares);
        });

        holdings = Array.from(aggregated.values());
    }
    holdingsLoading = false;
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

    const isPositive = percentageChange >= 0;
    // Updated to use pastel colors directly or from computed style if feasible, but hardcoding hex is safer for canvas
    // Pastel Green: #77DD77, Pastel Red: #FF6961
    const lineColor = isPositive ? '#77DD77' : '#FF6961';
    const fillColorStart = isPositive ? 'rgba(119, 221, 119, 0.2)' : 'rgba(255, 105, 97, 0.2)';
    const fillColorEnd = isPositive ? 'rgba(119, 221, 119, 0)' : 'rgba(255, 105, 97, 0)';

    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, fillColorStart);
    gradient.addColorStop(1, fillColorEnd);

    const minPrice = Math.min(...dataPoints);
    const maxPrice = Math.max(...dataPoints);
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
            tension: 0.4,
            spanGaps: true,
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
            display: false,
            suggestedMin: suggestedMin,
            suggestedMax: suggestedMax,
          },
        },
      },
    });
  }

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

  function handleUserClick(user: any) {
      if (onNavigate) {
          onNavigate(`/profile?u=${user.username}`);
      }
  }

  onMount(() => {
    if ($userProfile) {
        fetchHistory();
        fetchHoldings();
    }
    const unsubscribe = userProfile.subscribe(val => {
        if (val) {
             currentValue = val.price || 50;
             if (historyData.length === 0) fetchHistory();
             if (holdings.length === 0) fetchHoldings();
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
      <h1>VALOR DE ${$userProfile?.username ? $userProfile.username.toUpperCase() : 'USUARIO'}</h1>

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

  <div class="content-grid">
      <!-- Left Column: Chart -->
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

      <!-- Right Column: Holdings Table -->
      <div class="holdings-section">
          <h2>Holdings</h2>
          {#if holdingsLoading}
            <div class="loading-holdings">
                <Loader2 class="animate-spin" size={24} color="var(--primary-color)" />
            </div>
          {:else if holdings.length === 0}
            <div class="empty-holdings">
                <p>You haven't invested in anyone yet.</p>
                <a href="/markets" class="btn-explore" on:click|preventDefault={() => onNavigate('/markets')}>Explore Markets</a>
            </div>
          {:else}
            <div class="holdings-list">
                {#each holdings as item}
                    <!-- svelte-ignore a11y-click-events-have-key-events -->
                    <div class="holding-card" role="button" tabindex="0" on:click={() => handleUserClick(item.user)}>
                        <div class="user-cell">
                            <img
                                src={item.user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${item.user.username}`}
                                alt={item.user.username}
                                class="avatar"
                            />
                            <div class="user-meta">
                                <span class="username">${item.user.username.toUpperCase()}</span>
                                <span class="price-info">{item.user.price.toFixed(2)} / share</span>
                            </div>
                        </div>
                        <div class="shares-cell">
                            <span class="shares-amount">{item.totalShares.toFixed(4)}</span>
                            <span class="shares-label">Shares</span>
                        </div>
                    </div>
                {/each}
            </div>
          {/if}
      </div>
  </div>
</div>

<style>
  .portfolio-container {
      padding: 24px;
      max-width: 100%;
      color: var(--text-main);
  }

  .header {
      margin-bottom: 32px;
  }

  h1 {
      margin-bottom: 16px;
      font-size: 28px;
      font-weight: 800;
      color: var(--text-main);
  }

  .value-card {
      display: flex;
      flex-direction: column;
  }

  .current-value {
      font-size: 56px;
      font-weight: 900;
      color: var(--text-main);
      line-height: 1;
      margin-bottom: 12px;
      letter-spacing: -1.5px;
      display: flex;
      align-items: baseline;
      gap: 12px;
  }

  .currency-label {
      font-size: 18px;
      font-weight: 600;
      color: var(--text-secondary);
      letter-spacing: normal;
  }

  .change-indicator {
      display: flex;
      align-items: center;
      font-size: 16px;
      font-weight: 700;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 9999px;
      width: fit-content;
  }

  .change-indicator.positive {
      color: var(--success-color); /* Pastel Green */
      background-color: rgba(119, 221, 119, 0.1);
  }

  .change-indicator.negative {
      color: var(--danger-color); /* Pastel Red */
      background-color: rgba(255, 105, 97, 0.1);
  }

  /* Layout Grid */
  .content-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 32px;
  }

  @media (max-width: 900px) {
      .content-grid {
          grid-template-columns: 1fr;
      }
  }

  /* Chart Section */
  .chart-section {
      background-color: var(--bg-main);
      border-radius: 24px;
      position: relative;
      /* removed box-shadow to be cleaner */
  }

  .chart-controls {
      display: flex;
      gap: 12px; /* Increased gap */
      margin-bottom: 24px;
      overflow-x: auto;
      padding: 8px 12px; /* Added padding to container */
      scrollbar-width: none;
      background-color: var(--bg-secondary); /* Background for the control bar */
      border-radius: 16px; /* Rounded pill shape for the bar */
      width: fit-content;
  }
  .chart-controls::-webkit-scrollbar {
      display: none;
  }

  .range-btn {
      padding: 8px 16px;
      border-radius: 12px; /* Slightly softer radius */
      background: transparent;
      border: none;
      font-weight: 600;
      color: var(--text-secondary);
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s ease;
      white-space: nowrap;
  }

  .range-btn:hover {
      color: var(--primary-color);
      background-color: rgba(255, 255, 255, 0.5);
  }

  .range-btn.active {
      background-color: var(--primary-color); /* Pastel Blue */
      color: white;
      box-shadow: 0 4px 10px rgba(119, 158, 203, 0.3);
  }

  .custom-date-picker {
      display: flex;
      gap: 12px;
      align-items: flex-end;
      margin-bottom: 24px;
      background-color: var(--bg-secondary);
      padding: 20px;
      border-radius: 20px;
      flex-wrap: wrap;
  }

  .date-input {
      display: flex;
      flex-direction: column;
      gap: 8px;
  }

  .date-input label {
      font-size: 13px;
      color: var(--text-secondary);
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
  }

  .date-input input {
      padding: 12px;
      border-radius: 12px;
      border: 1px solid transparent;
      font-family: inherit;
      background-color: white;
      color: var(--text-main);
      box-shadow: 0 2px 5px rgba(0,0,0,0.05);
      transition: border-color 0.2s;
  }

  .date-input input:focus {
      outline: none;
      border-color: var(--primary-color);
  }

  .apply-btn {
      padding: 12px 24px;
      background-color: var(--primary-color);
      color: white;
      border-radius: 12px;
      font-weight: 700;
      border: none;
      cursor: pointer;
      margin-top: auto;
      box-shadow: 0 4px 10px rgba(119, 158, 203, 0.3);
      transition: transform 0.1s;
  }

  .apply-btn:active {
      transform: scale(0.98);
  }

  .chart-wrapper {
      position: relative;
      height: 400px; /* Increased height */
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
      background-color: rgba(255,255,255,0.6);
      z-index: 2;
      border-radius: 24px;
      backdrop-filter: blur(4px);
  }

  /* Holdings Section */
  .holdings-section {
      background-color: var(--bg-secondary);
      border-radius: 32px; /* More rounded */
      padding: 32px;
      display: flex;
      flex-direction: column;
      max-height: 600px; /* Taller */
      overflow-y: auto;
  }

  .holdings-section h2 {
      font-size: 22px;
      margin-top: 0;
      margin-bottom: 24px;
      color: var(--text-main);
      letter-spacing: -0.5px;
  }

  .loading-holdings {
      display: flex;
      justify-content: center;
      padding: 40px;
  }

  .empty-holdings {
      text-align: center;
      color: var(--text-secondary);
      padding: 40px 0;
  }

  .btn-explore {
      display: inline-block;
      margin-top: 16px;
      color: var(--primary-color);
      font-weight: 700;
      text-decoration: none;
  }

  .holdings-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
  }

  .holding-card {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background-color: white; /* Card on secondary bg */
      padding: 16px 20px;
      border-radius: 20px;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      border: 1px solid transparent;
      box-shadow: 0 2px 4px rgba(0,0,0,0.02);
  }

  .holding-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 20px rgba(0,0,0,0.05);
      border-color: var(--primary-color);
  }

  .user-cell {
      display: flex;
      align-items: center;
      gap: 16px;
  }

  .avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      object-fit: cover;
      background-color: var(--bg-tertiary);
      border: 2px solid white;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }

  .user-meta {
      display: flex;
      flex-direction: column;
      gap: 2px;
  }

  .username {
      font-weight: 800;
      font-size: 15px;
      color: var(--text-main);
  }

  .price-info {
      font-size: 13px;
      color: var(--text-secondary);
      font-weight: 500;
  }

  .shares-cell {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 2px;
  }

  .shares-amount {
      font-weight: 800;
      font-size: 16px;
      color: var(--text-main);
  }

  .shares-label {
      font-size: 12px;
      color: var(--text-tertiary);
      font-weight: 600;
      text-transform: uppercase;
  }
</style>
