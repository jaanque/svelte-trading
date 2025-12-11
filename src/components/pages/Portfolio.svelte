<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  import Chart from "chart.js/auto";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, ArrowUpRight, ArrowDownRight, Wallet, History, PieChart } from "lucide-svelte";

  export let onNavigate: (path: string) => void = (path) => { window.location.href = path; };

  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart | null = null;
  let loading = true;
  let historyData: any[] = [];
  let timeRange = "24h";
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

  let activeTab: 'holdings' | 'history' = 'holdings';

  const ranges = [
    { label: "24H", value: "24h" },
    { label: "7D", value: "7d" },
    { label: "30D", value: "30d" },
    { label: "1Y", value: "1y" },
    { label: "All", value: "all" },
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
      startDate = new Date(0);
    }

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
        const { data: startPricesData, error: startError } = await supabase.rpc(
            "get_snapshot_prices",
            { p_user_ids: targetUserIds, p_time: startDate }
        );

        if (startError) throw startError;

        let currentPrices = new Map<string, number>();

        holdings.forEach(h => {
             currentPrices.set(h.user.id, h.user.price);
        });

        startPricesData?.forEach((row: any) => {
            currentPrices.set(row.user_id, row.price);
        });

        let query = supabase
          .from("price_history")
          .select("user_id, price, created_at")
          .in("user_id", targetUserIds)
          .gte("created_at", startDate.toISOString())
          .order("created_at", { ascending: true });

        const { data: priceChanges, error: historyError } = await query;
        if (historyError) throw historyError;

        let timePoints: any[] = [];

        let startTotal = 0;
        holdings.forEach(h => {
            const p = currentPrices.get(h.user.id) || 0;
            startTotal += h.totalShares * p;
        });

        timePoints.push({
            created_at: startDate.toISOString(),
            price: startTotal
        });

        if (priceChanges && priceChanges.length > 0) {
            priceChanges.forEach((change: any) => {
                currentPrices.set(change.user_id, change.price);

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

        let endTotal = 0;
        holdings.forEach(h => {
             endTotal += h.totalShares * h.user.price;
        });

        const now = new Date();
        timePoints.push({
            created_at: now.toISOString(),
            price: endTotal
        });

        timePoints.sort((a,b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());

        historyData = timePoints;

        startValue = timePoints[0].price;
        let endVal = timePoints[timePoints.length - 1].price;
        let diff = endVal - startValue;
        percentageChange = startValue === 0 ? 0 : (diff / startValue) * 100;

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

        holdings = Array.from(aggregated.values()).filter((h: any) => h.totalShares > 0);
        currentValue = holdings.reduce((sum, h) => sum + (h.totalShares * h.user.price), 0);
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
        .limit(20);

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

    const labels = historyData.map(d => {
        const date = new Date(d.created_at);
        return date;
    });

    const dataPoints = historyData.map(d => d.price);
    const isPositive = percentageChange >= 0;
    const lineColor = isPositive ? '#10B981' : '#EF4444'; // Stronger colors
    const fillColorStart = isPositive ? 'rgba(16, 185, 129, 0.2)' : 'rgba(239, 68, 68, 0.2)';
    const fillColorEnd = isPositive ? 'rgba(16, 185, 129, 0)' : 'rgba(239, 68, 68, 0)';

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
            borderWidth: 2,
            pointRadius: 0,
            pointHoverRadius: 6,
            pointBackgroundColor: lineColor,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            fill: true,
            tension: 0.3,
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
                         month: 'short', day: 'numeric',
                         hour: '2-digit', minute: '2-digit'
                     });
                 },
                 label: function(context: any) {
                     return 'Value: ' + (context.parsed.y || 0).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
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
                    return '';
                }
            },
            grid: { display: false },
            border: { display: false }
          },
          y: {
            display: true,
            suggestedMin: suggestedMin,
            suggestedMax: suggestedMax,
            grid: {
                color: 'rgba(0,0,0,0.05)'
            },
            ticks: {
                display: false // Cleaner look without Y axis labels on the chart itself if we show big number
            },
            border: { display: false }
          },
        },
      },
    });

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
      fetchHistory();
  }

  function handleUserClick(user: any) {
      if (onNavigate) {
          onNavigate(`/profile?u=${user.username}`);
      }
  }

  onMount(() => {
    if ($userProfile) {
        fetchHoldings();
        fetchTransactions();
    }
    const unsubscribe = userProfile.subscribe(val => {
        if (val) {
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

<div class="portfolio-page">
  <div class="header-summary">
      <div class="summary-card total-value">
          <div class="label">Portfolio Value</div>
          <div class="value">
              {currentValue.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}
              <span class="unit">Credits</span>
          </div>
          <div class="change-badge {percentageChange >= 0 ? 'positive' : 'negative'}">
              {#if percentageChange >= 0}
                 <ArrowUpRight size={16} />
              {:else}
                 <ArrowDownRight size={16} />
              {/if}
              <span>{Math.abs(percentageChange).toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}% ({timeRange.toUpperCase()})</span>
          </div>
      </div>

      <div class="summary-card cash-balance">
          <div class="label">Cash Balance</div>
          <div class="value">
              {$userProfile?.tokens.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2}) || "0.00"}
              <span class="unit">Credits</span>
          </div>
          <div class="action-hint">Available to invest</div>
      </div>
  </div>

  <div class="main-layout">
      <!-- Chart Column -->
      <div class="left-column">
          <div class="chart-card">
              <div class="chart-header">
                  <h3>Performance</h3>
                  <div class="time-controls">
                      {#each ranges as range}
                         <button
                            class="time-btn {timeRange === range.value ? 'active' : ''}"
                            on:click={() => handleRangeChange(range.value)}
                         >
                            {range.label}
                         </button>
                      {/each}
                  </div>
              </div>
              <div class="chart-container">
                  {#if loading}
                     <div class="loader-overlay">
                         <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
                     </div>
                  {/if}
                  <canvas bind:this={chartCanvas}></canvas>
              </div>
          </div>
      </div>

      <!-- Detail Column -->
      <div class="right-column">
          <div class="detail-card">
              <div class="tabs">
                  <button
                    class="tab-btn {activeTab === 'holdings' ? 'active' : ''}"
                    on:click={() => activeTab = 'holdings'}
                  >
                      <PieChart size={18} />
                      Holdings
                  </button>
                  <button
                    class="tab-btn {activeTab === 'history' ? 'active' : ''}"
                    on:click={() => activeTab = 'history'}
                  >
                      <History size={18} />
                      History
                  </button>
              </div>

              <div class="tab-content">
                  {#if activeTab === 'holdings'}
                      {#if holdingsLoading}
                        <div class="loading-state"><Loader2 class="animate-spin" /></div>
                      {:else if holdings.length === 0}
                        <div class="empty-state">
                            <p>No investments yet.</p>
                            <a href="/markets" class="btn-link" on:click|preventDefault={() => onNavigate('/markets')}>Find Traders</a>
                        </div>
                      {:else}
                        <div class="list-container">
                            {#each holdings as item}
                                <div
                                    class="list-item"
                                    role="button"
                                    tabindex="0"
                                    on:click={() => handleUserClick(item.user)}
                                    on:keydown={(e) => (e.key === 'Enter' || e.key === ' ') && handleUserClick(item.user)}
                                >
                                    <img src={item.user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${item.user.username}`} alt="" class="item-avatar"/>
                                    <div class="item-info">
                                        <div class="item-top">
                                            <span class="item-name">{item.user.full_name || item.user.username}</span>
                                            <span class="item-value">{(item.totalShares * item.user.price).toLocaleString(undefined, {maximumFractionDigits: 0})}</span>
                                        </div>
                                        <div class="item-bottom">
                                            <span class="item-sub">${item.user.username.toUpperCase()}</span>
                                            <span class="item-sub">{item.totalShares.toLocaleString(undefined, {maximumFractionDigits: 2})} shares</span>
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        </div>
                      {/if}
                  {:else}
                      <!-- History Tab -->
                      {#if transactionsLoading}
                        <div class="loading-state"><Loader2 class="animate-spin" /></div>
                      {:else if transactions.length === 0}
                        <div class="empty-state">
                            <p>No transactions found.</p>
                        </div>
                      {:else}
                        <div class="list-container">
                            {#each transactions as tx}
                                <div class="list-item tx-item">
                                    <div class="tx-icon {tx.amount_shares > 0 ? 'buy' : 'sell'}">
                                        {#if tx.amount_shares > 0}<ArrowDownRight size={16}/>{:else}<ArrowUpRight size={16}/>{/if}
                                    </div>
                                    <div class="item-info">
                                        <div class="item-top">
                                            <span class="item-name">{tx.amount_shares > 0 ? 'Bought' : 'Sold'} ${tx.target_user.username.toUpperCase()}</span>
                                            <span class="item-value {tx.amount_shares > 0 ? 'negative-text' : 'positive-text'}">
                                                {tx.amount_shares > 0 ? '-' : '+'}{Math.abs(tx.amount_tokens).toLocaleString(undefined, {maximumFractionDigits: 0})}
                                            </span>
                                        </div>
                                        <div class="item-bottom">
                                            <span class="item-sub">{new Date(tx.created_at).toLocaleDateString()}</span>
                                            <span class="item-sub">{Math.abs(tx.amount_shares).toFixed(2)} shares @ {Math.abs(tx.amount_tokens / tx.amount_shares).toFixed(2)}</span>
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        </div>
                      {/if}
                  {/if}
              </div>
          </div>
      </div>
  </div>
</div>

<style>
  .portfolio-page {
      padding: 24px 40px; /* More horizontal padding */
      max-width: 100%; /* Allow full width */
      margin: 0;
      width: 100%;
      box-sizing: border-box;
  }

  /* Header Summary */
  .header-summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 32px;
  }

  .summary-card {
      background-color: var(--bg-secondary);
      border-radius: 20px;
      padding: 24px;
      display: flex;
      flex-direction: column;
      gap: 8px;
  }

  .summary-card .label {
      font-size: 14px;
      color: var(--text-secondary);
      font-weight: 600;
      text-transform: uppercase;
  }

  .summary-card .value {
      font-size: 32px;
      font-weight: 800;
      color: var(--text-main);
      display: flex;
      align-items: baseline;
      gap: 8px;
  }

  .summary-card .unit {
      font-size: 16px;
      color: var(--text-secondary);
      font-weight: 600;
  }

  .change-badge {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      padding: 4px 10px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
      width: fit-content;
  }
  .change-badge.positive {
      background-color: rgba(16, 185, 129, 0.1);
      color: var(--success-color);
  }
  .change-badge.negative {
      background-color: rgba(239, 68, 68, 0.1);
      color: var(--danger-color);
  }

  .action-hint {
      font-size: 13px;
      color: var(--primary-color);
      font-weight: 600;
  }

  /* Main Layout */
  .main-layout {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 24px;
      min-height: 500px;
  }

  @media (max-width: 900px) {
      .main-layout {
          grid-template-columns: 1fr;
      }
      .portfolio-page {
          padding: 16px;
      }
  }

  /* Chart Card */
  .chart-card {
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      padding: 24px;
      height: 100%;
      display: flex;
      flex-direction: column;
  }

  .chart-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
      flex-wrap: wrap;
      gap: 12px;
  }

  .chart-header h3 {
      margin: 0;
      font-size: 18px;
      font-weight: 700;
  }

  .time-controls {
      display: flex;
      background-color: var(--bg-secondary);
      padding: 4px;
      border-radius: 12px;
      gap: 4px;
  }

  .time-btn {
      padding: 6px 12px;
      border-radius: 8px;
      border: none;
      background: none;
      font-size: 13px;
      font-weight: 600;
      color: var(--text-secondary);
      cursor: pointer;
      transition: all 0.2s;
  }

  .time-btn:hover {
      color: var(--text-main);
  }

  .time-btn.active {
      background-color: var(--bg-main);
      color: var(--text-main);
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  }

  .chart-container {
      flex: 1;
      position: relative;
      min-height: 300px;
  }

  .loader-overlay {
      position: absolute;
      inset: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      background: rgba(255,255,255,0.8);
      z-index: 10;
  }

  /* Detail Card (Holdings/History) */
  .detail-card {
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      display: flex;
      flex-direction: column;
      overflow: hidden;
      height: 100%;
      max-height: 600px;
  }

  .tabs {
      display: flex;
      border-bottom: 1px solid var(--border-color);
  }

  .tab-btn {
      flex: 1;
      padding: 16px;
      background: none;
      border: none;
      font-size: 14px;
      font-weight: 600;
      color: var(--text-secondary);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: all 0.2s;
      border-bottom: 2px solid transparent;
  }

  .tab-btn:hover {
      background-color: var(--bg-hover);
      color: var(--text-main);
  }

  .tab-btn.active {
      color: var(--primary-color);
      border-bottom-color: var(--primary-color);
  }

  .tab-content {
      flex: 1;
      overflow-y: auto;
      padding: 0;
  }

  .loading-state, .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 40px;
      color: var(--text-secondary);
      text-align: center;
  }

  .btn-link {
      color: var(--primary-color);
      text-decoration: none;
      font-weight: 700;
      margin-top: 8px;
  }

  .list-container {
      display: flex;
      flex-direction: column;
  }

  .list-item {
      display: flex;
      align-items: center;
      padding: 12px 16px;
      border-bottom: 1px solid var(--border-color);
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .list-item:hover {
      background-color: var(--bg-hover);
  }

  .item-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      margin-right: 12px;
      background-color: var(--bg-tertiary);
  }

  .item-info {
      flex: 1;
      display: flex;
      flex-direction: column;
  }

  .item-top {
      display: flex;
      justify-content: space-between;
      margin-bottom: 2px;
  }

  .item-name {
      font-weight: 700;
      font-size: 14px;
      color: var(--text-main);
  }

  .item-value {
      font-weight: 700;
      font-size: 14px;
      color: var(--text-main);
  }

  .item-bottom {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-secondary);
  }

  /* Transaction Items Specifics */
  .tx-item {
      cursor: default;
  }
  .tx-item:hover {
      background-color: transparent;
  }

  .tx-icon {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 12px;
  }
  .tx-icon.buy {
      background-color: rgba(16, 185, 129, 0.1);
      color: var(--success-color);
  }
  .tx-icon.sell {
      background-color: rgba(239, 68, 68, 0.1);
      color: var(--danger-color);
  }

  .negative-text { color: var(--text-main); }
  .positive-text { color: var(--success-color); }
</style>
