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

  let transactions: any[] = [];
  let transactionsLoading = false;

  // Reactively update current value from profile store
  // NOTE: We don't want $userProfile.price anymore, we want Portfolio Value.
  // We will update currentValue when holdings change.

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

    // 1. Determine Time Range
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
      startDate = new Date(0); // Beginning of time
    } else if (timeRange === "custom") {
        if (customStartDate) {
            startDate = new Date(customStartDate);
        } else {
             startDate.setDate(startDate.getDate() - 30);
        }
    }

    // 2. Determine involved users (my holdings)
    // If we have no holdings, history is flat 0?
    if (holdings.length === 0) {
        historyData = [];
        currentValue = 0;
        startValue = 0;
        percentageChange = 0;
        loading = false;
        renderChart();
        return;
    }

    const targetUserIds = holdings.map(h => h.user.id);

    try {
        // 3. Get Baseline Prices (snapshot before startDate)
        const { data: startPricesData, error: startError } = await supabase.rpc(
            "get_snapshot_prices",
            { p_user_ids: targetUserIds, p_time: startDate }
        );

        if (startError) throw startError;

        // Initialize price map with baselines
        // If baseline missing, check if we have data later?
        // Fallback to holding.user.price if absolutely no history found later?
        // For now initialize with map.
        let currentPrices = new Map<string, number>();

        // Fill defaults from Current Prices (fallback)
        // This ensures if a user has no history at all, we assume price is constant
        holdings.forEach(h => {
             currentPrices.set(h.user.id, h.user.price);
        });

        // Override with baseline from DB if exists
        startPricesData?.forEach((row: any) => {
            currentPrices.set(row.user_id, row.price);
        });

        // 4. Get Price History Stream (changes in window)
        let query = supabase
          .from("price_history")
          .select("user_id, price, created_at")
          .in("user_id", targetUserIds)
          .gte("created_at", startDate.toISOString())
          .order("created_at", { ascending: true });

        if (timeRange === "custom" && customEndDate) {
            const end = new Date(customEndDate);
            end.setHours(23, 59, 59);
            query = query.lte("created_at", end.toISOString());
        }

        const { data: priceChanges, error: historyError } = await query;
        if (historyError) throw historyError;

        // 5. Reconstruct Portfolio Value Stream
        // We want a timeseries.
        // Events: priceChanges.
        // We can sample at intervals OR just record every change.
        // Recording every change is most accurate but might be jagged.
        // Let's record every change event as a datapoint.

        let timePoints: any[] = [];

        // Add Start Point
        let startTotal = 0;
        holdings.forEach(h => {
            const p = currentPrices.get(h.user.id) || 0;
            startTotal += h.totalShares * p;
        });

        timePoints.push({
            created_at: startDate.toISOString(),
            price: startTotal
        });

        // Process changes
        if (priceChanges && priceChanges.length > 0) {
            priceChanges.forEach((change: any) => {
                // Update price for this user
                currentPrices.set(change.user_id, change.price);

                // Recalculate Total
                let total = 0;
                holdings.forEach(h => {
                    const p = currentPrices.get(h.user.id) || 0;
                    total += h.totalShares * p;
                });

                timePoints.push({
                    created_at: change.created_at,
                    price: total
                });
            });
        }

        // Add End Point (Now)
        // Ensure we capture current state if not covered
        let endTotal = 0;
        holdings.forEach(h => {
             // currentPrices should now hold latest from history stream
             // BUT `price_history` might lag behind `profiles.price` slightly if realtime?
             // Let's use the actual current `holdings.user.price` for the "Now" point to be precise with UI.
             endTotal += h.totalShares * h.user.price;
        });

        const now = new Date();
        timePoints.push({
            created_at: now.toISOString(),
            price: endTotal
        });

        // Sort just in case
        timePoints.sort((a,b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

        historyData = timePoints;

        // Calculate Stats
        startValue = timePoints[0].price;
        let endVal = timePoints[timePoints.length - 1].price;
        let diff = endVal - startValue;
        percentageChange = startValue === 0 ? 0 : (diff / startValue) * 100;

        // Update display value to the latest calculated portfolio value
        currentValue = endVal;

    } catch (err) {
        console.error("Error reconstructing portfolio history:", err);
    } finally {
        renderChart();
        loading = false;
    }
  }

  async function fetchHoldings() {
    if (!$userProfile) return;
    holdingsLoading = true;

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

        // Initial current value based on holdings
        currentValue = holdings.reduce((sum, h) => sum + (h.totalShares * h.user.price), 0);

        // Now fetch history based on these holdings
        fetchHistory();
    }
    holdingsLoading = false;
  }

  async function fetchTransactions() {
    if (!$userProfile) return;
    transactionsLoading = true;

    const { data, error } = await supabase
        .from("investments")
        .select(`
            id,
            amount_shares,
            amount_tokens,
            created_at,
            target_user:profiles!target_user_id(id, username, full_name, avatar_url)
        `)
        .eq("investor_id", $userProfile.id)
        .order("created_at", { ascending: false })
        .limit(20); // Limit to recent 20 for now

    if (error) {
        console.error("Error fetching transactions:", error);
    } else {
        transactions = data;
    }
    transactionsLoading = false;
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
        return date;
    });

    const dataPoints = historyData.map(d => d.price);

    const isPositive = percentageChange >= 0;
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
            label: "Value",
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
            tension: 0.2, // Smoother but detailed
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
                 label: function(context) {
                     return 'Value: ' + context.parsed.y.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                 }
             }
          }
        },
        scales: {
          x: {
            display: true,
            ticks: {
                maxTicksLimit: 6,
                color: '#9CA3AF',
                font: { size: 11 },
                callback: function(val, index) {
                    // Just return empty string if we rely on Tooltip for detail, or format simply
                    return '';
                }
            },
            grid: {
              display: false,
              drawBorder: false,
            },
            border: { display: false }
          },
          y: {
            display: true, // Enable Y axis
            suggestedMin: suggestedMin,
            suggestedMax: suggestedMax,
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

    // Fix X labels
    chartInstance.data.labels = historyData.map(d => {
        const date = new Date(d.created_at);
        if (timeRange === '24h') return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
    });
    chartInstance.update();
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
        // We trigger holdings first, history will be triggered after holdings load
        fetchHoldings();
        fetchTransactions();
    }
    const unsubscribe = userProfile.subscribe(val => {
        if (val) {
             // If profile updates, refresh holdings (which refreshes history)
             if (holdings.length === 0) fetchHoldings();
             if (transactions.length === 0) fetchTransactions();
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
      <h1>VALOR DE CARTERA</h1>

      <!-- Value Display -->
      <div class="value-card">
          <div class="current-value">
              {currentValue.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}
              <span class="currency-label">Credits</span>
          </div>
          <div class="change-indicator {percentageChange >= 0 ? 'positive' : 'negative'}">
              {#if percentageChange >= 0}
                 <ArrowUpRight size={20} />
              {:else}
                 <ArrowDownRight size={20} />
              {/if}
              <span>{Math.abs(percentageChange).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}% ({timeRange.toUpperCase()})</span>
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
                                <span class="price-info">{item.user.price.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} / share</span>
                            </div>
                        </div>
                        <div class="shares-cell">
                            <span class="shares-amount">{item.totalShares.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 4})}</span>
                            <span class="shares-label">Shares</span>
                        </div>
                    </div>
                {/each}
            </div>
          {/if}
      </div>
  </div>

  <!-- Transaction History Section -->
  <div class="history-section">
      <h2>Transaction History</h2>
      {#if transactionsLoading}
        <div class="loading-history">
            <Loader2 class="animate-spin" size={24} color="var(--primary-color)" />
        </div>
      {:else if transactions.length === 0}
        <div class="empty-history">
            <p>No transactions found.</p>
        </div>
      {:else}
        <div class="transactions-list">
            {#each transactions as tx}
                <div class="tx-card">
                    <div class="tx-user-info" role="button" tabindex="0" on:click={() => handleUserClick(tx.target_user)}>
                        <img
                            src={tx.target_user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${tx.target_user.username}`}
                            alt={tx.target_user.username}
                            class="tx-avatar"
                        />
                        <div class="tx-details">
                            <span class="tx-username">${tx.target_user.username.toUpperCase()}</span>
                            <span class="tx-date">{new Date(tx.created_at).toLocaleDateString()}</span>
                        </div>
                    </div>
                    <div class="tx-financials">
                        <div class="tx-type {tx.amount_shares > 0 ? 'buy' : 'sell'}">
                            {tx.amount_shares > 0 ? 'BUY' : 'SELL'}
                        </div>
                        <div class="tx-amount">
                            <span class="tx-shares">{Math.abs(tx.amount_shares).toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 4})} Shares</span>
                            <span class="tx-price">@ {Math.abs(tx.amount_tokens / tx.amount_shares).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} / share</span>
                        </div>
                        <div class="tx-total">
                            {Math.abs(tx.amount_tokens).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})} Credits
                        </div>
                    </div>
                </div>
            {/each}
        </div>
      {/if}
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
      margin-bottom: 32px;
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

  /* Transaction History */
  .history-section {
      background-color: var(--bg-secondary);
      border-radius: 32px;
      padding: 32px;
  }

  .history-section h2 {
      font-size: 22px;
      margin-top: 0;
      margin-bottom: 24px;
      color: var(--text-main);
  }

  .loading-history {
      display: flex;
      justify-content: center;
      padding: 40px;
  }

  .empty-history {
      text-align: center;
      color: var(--text-secondary);
      padding: 40px 0;
  }

  .transactions-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
  }

  .tx-card {
      display: flex;
      justify-content: space-between;
      align-items: center;
      background-color: white;
      padding: 16px 20px;
      border-radius: 16px;
  }

  .tx-user-info {
      display: flex;
      align-items: center;
      gap: 12px;
      cursor: pointer;
  }

  .tx-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
      object-fit: cover;
  }

  .tx-details {
      display: flex;
      flex-direction: column;
  }

  .tx-username {
      font-weight: 700;
      font-size: 14px;
      color: var(--text-main);
  }

  .tx-date {
      font-size: 12px;
      color: var(--text-secondary);
  }

  .tx-financials {
      display: flex;
      align-items: center;
      gap: 24px;
      text-align: right;
  }

  .tx-type {
      font-weight: 800;
      font-size: 13px;
      padding: 4px 8px;
      border-radius: 6px;
      text-transform: uppercase;
  }
  .tx-type.buy {
      background-color: rgba(119, 221, 119, 0.2);
      color: var(--success-color);
  }
  .tx-type.sell {
      background-color: rgba(255, 105, 97, 0.2);
      color: var(--danger-color);
  }

  .tx-amount {
      display: flex;
      flex-direction: column;
  }

  .tx-shares {
      font-weight: 700;
      font-size: 14px;
  }

  .tx-price {
      font-size: 12px;
      color: var(--text-secondary);
  }

  .tx-total {
      font-weight: 800;
      font-size: 15px;
      color: var(--text-main);
      min-width: 80px;
  }

  @media (max-width: 600px) {
      .tx-card {
          flex-direction: column;
          align-items: flex-start;
          gap: 16px;
      }
      .tx-financials {
          width: 100%;
          justify-content: space-between;
      }
  }
</style>
