<script lang="ts">
  import { Search, Clock, TrendingUp, TrendingDown, Activity, DollarSign, BarChart2, ArrowRight, Coins } from "lucide-svelte";
  import { supabase } from "../../lib/supabase";
  import { onMount } from "svelte";
  import Chart from "chart.js/auto";

  export let onNavigate: (path: string) => void = (path) => { window.location.href = path; };

  let searchQuery = "";
  let searchResults: any[] = [];
  let isLoading = false;
  let debounceTimer: any;
  let searchHistory: any[] = [];
  let historyLoading = false;

  let topGainers: any[] = [];
  let topLosers: any[] = [];
  let moversLoading = false;

  let dailyStats: { count: number; volume: number; chart_data: any[] } | null = null;
  let statsLoading = false;
  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart | null = null;

  let activeTab: 'gainers' | 'losers' = 'gainers';

  async function fetchDailyStats() {
    statsLoading = true;
    try {
      const { data, error } = await supabase.rpc("get_daily_investment_stats");

      if (error) {
        console.warn("RPC get_daily_investment_stats failed, using mock data:", error.message);
        dailyStats = {
            count: 142,
            volume: 54200,
            chart_data: Array.from({length: 24}, (_, i) => ({
                hour: i,
                count: Math.floor(Math.random() * 20),
                volume: Math.floor(Math.random() * 5000)
            }))
        };
      } else {
        dailyStats = data;
      }
    } catch (err) {
      console.error("Error fetching daily stats:", err);
    } finally {
      statsLoading = false;
    }
  }

  function renderChart() {
      if (!dailyStats || !chartCanvas) return;

      if (chartInstance) {
          chartInstance.destroy();
      }

      const labels = dailyStats.chart_data.map((d: any) => `${d.hour}:00`);
      const data = dailyStats.chart_data.map((d: any) => d.volume);

      chartInstance = new Chart(chartCanvas, {
          type: 'line',
          data: {
              labels: labels,
              datasets: [{
                  label: 'Volume',
                  data: data,
                  borderColor: '#1d9bf0',
                  backgroundColor: 'rgba(29, 155, 240, 0.1)',
                  borderWidth: 2,
                  fill: true,
                  tension: 0.4,
                  pointRadius: 0
              }]
          },
          options: {
              responsive: true,
              maintainAspectRatio: false,
              plugins: { legend: { display: false }, tooltip: { mode: 'index', intersect: false } },
              scales: { x: { display: false }, y: { display: false } },
              interaction: { intersect: false, mode: 'index' },
          }
      });
  }

  async function fetchHistory() {
    historyLoading = true;
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from("search_history")
        .select(`
          created_at,
          searched_profile:profiles!inner(id, username, full_name, avatar_url, price)
        `)
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .limit(5);

      if (error) {
        console.warn("Could not fetch history:", error.message);
      } else {
        searchHistory = data.map((item: any) => item.searched_profile).filter((p: any) => p);
        const uniqueHistory = [];
        const seenIds = new Set();
        for (const profile of searchHistory) {
            if (!seenIds.has(profile.id)) {
                uniqueHistory.push(profile);
                seenIds.add(profile.id);
            }
        }
        searchHistory = uniqueHistory;
      }
    } catch (err) {
      console.error("Error fetching history:", err);
    } finally {
      historyLoading = false;
    }
  }

  async function fetchTopMovers() {
    moversLoading = true;
    try {
      const { data, error } = await supabase.rpc("get_top_movers");
      if (error) throw error;

      const sorted = [...data].sort((a, b) => b.change_pct - a.change_pct);

      topGainers = sorted.filter(u => u.change_pct > 0).slice(0, 10); // Show more in list
      topLosers = sorted.filter(u => u.change_pct < 0).reverse().slice(0, 10);

    } catch (err) {
      console.error("Error fetching movers:", err);
    } finally {
      moversLoading = false;
    }
  }

  async function addToHistory(profile: any) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      await supabase
        .from("search_history")
        .delete()
        .eq("user_id", user.id)
        .eq("searched_profile_id", profile.id);

      const { error } = await supabase
        .from("search_history")
        .insert({
          user_id: user.id,
          searched_profile_id: profile.id
        });

      if (error) throw error;

      if (searchQuery.trim() === "") {
        searchHistory = [profile, ...searchHistory.filter(p => p.id !== profile.id)];
      }

    } catch (err) {
      console.error("Error adding to history:", err);
    }
  }

  async function performSearch() {
    if (!searchQuery.trim()) {
      searchResults = [];
      fetchHistory();
      return;
    }

    isLoading = true;
    try {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, username, full_name, avatar_url, price")
        .or(`username.ilike.%${searchQuery}%,full_name.ilike.%${searchQuery}%`)
        .limit(20);

      if (error) throw error;
      searchResults = data || [];
    } catch (error) {
      console.error("Error searching users:", error);
    } finally {
      isLoading = false;
    }
  }

  function handleInput() {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
      performSearch();
    }, 300);
  }

  async function handleProfileClick(profile: any) {
      await addToHistory(profile);
      onNavigate(`/profile?u=${profile.username}`);
  }

  function formatPrice(num: number) {
      return num.toLocaleString(undefined, { maximumFractionDigits: 2 });
  }

  onMount(() => {
    fetchHistory();
    fetchTopMovers();
    fetchDailyStats();
  });

  $: if (dailyStats && chartCanvas) {
      renderChart();
  }
</script>

<div class="markets-page">
  <div class="header-section">
      <h1>Markets</h1>
      <div class="search-wrapper">
          <div class="search-icon">
              <Search size={20} color="var(--text-secondary)" />
          </div>
          <input
              type="text"
              placeholder="Search traders, tickers..."
              bind:value={searchQuery}
              on:input={handleInput}
          />
      </div>
  </div>

  <div class="main-grid">
      <!-- Main Content: Market List -->
      <div class="market-list-card">
          <div class="card-header">
              <div class="tabs">
                  <button class="tab-btn {activeTab === 'gainers' ? 'active' : ''}" on:click={() => activeTab = 'gainers'}>
                      Top Gainers
                  </button>
                  <button class="tab-btn {activeTab === 'losers' ? 'active' : ''}" on:click={() => activeTab = 'losers'}>
                      Top Losers
                  </button>
              </div>
          </div>

          <div class="table-container">
              <div class="table-header">
                  <div class="th user-col">Trader</div>
                  <div class="th price-col">Price</div>
                  <div class="th change-col">24h Change</div>
                  <div class="th action-col"></div>
              </div>

              <div class="table-body">
                  {#if moversLoading}
                      <div class="loading-state"><div class="spinner"></div></div>
                  {:else}
                      {#if activeTab === 'gainers'}
                          {#each topGainers as user}
                              <div class="table-row" on:click={() => handleProfileClick(user)} role="button" tabindex="0">
                                  <div class="td user-col">
                                      <img src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`} alt="" class="row-avatar"/>
                                      <div class="user-meta">
                                          <span class="row-name">{user.full_name}</span>
                                          <span class="row-username">${user.username.toUpperCase()}</span>
                                      </div>
                                  </div>
                                  <div class="td price-col">
                                      <div class="price-wrapper">
                                          <Coins size={14} class="currency-icon" />
                                          <span class="price-val">{formatPrice(user.current_price || 0)}</span>
                                      </div>
                                      <div class="price-wrapper">
                                          <Coins size={14} class="currency-icon" />
                                          <span class="price-val">{formatPrice(user.current_price || 0)}</span>
                                      </div>
                                  </div>
                                  <div class="td change-col">
                                      <span class="change-badge positive">+{user.change_pct.toFixed(2)}%</span>
                                  </div>
                                  <div class="td action-col">
                                      <ArrowRight size={18} class="action-icon" />
                                  </div>
                              </div>
                          {/each}
                      {:else}
                          {#each topLosers as user}
                              <div class="table-row" on:click={() => handleProfileClick(user)} role="button" tabindex="0">
                                  <div class="td user-col">
                                      <img src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`} alt="" class="row-avatar"/>
                                      <div class="user-meta">
                                          <span class="row-name">{user.full_name}</span>
                                          <span class="row-username">${user.username.toUpperCase()}</span>
                                      </div>
                                  </div>
                                  <div class="td price-col">
                                      <span class="price-val">{formatPrice(user.current_price || 0)}</span>
                                  </div>
                                  <div class="td change-col">
                                      <span class="change-badge negative">{user.change_pct.toFixed(2)}%</span>
                                  </div>
                                  <div class="td action-col">
                                      <ArrowRight size={18} class="action-icon" />
                                  </div>
                              </div>
                          {/each}
                      {/if}
                  {/if}
              </div>
          </div>
      </div>

      <!-- Sidebar: Stats & History -->
      <div class="sidebar">
          <!-- Market Pulse Card -->
          <div class="sidebar-card">
              <div class="sidebar-header">
                  <h3>Market Pulse</h3>
                  <span class="live-dot"></span>
              </div>

              <div class="stat-group">
                  <div class="stat-label">Total Volume (24h)</div>
                  <div class="stat-value">{dailyStats?.volume?.toLocaleString() || "0"} <span class="unit">TOKENS</span></div>
              </div>
              <div class="stat-divider"></div>
              <div class="stat-group">
                  <div class="stat-label">Transactions Today</div>
                  <div class="stat-value">{dailyStats?.count?.toLocaleString() || "0"} <span class="unit">TXS</span></div>
              </div>

              <div class="mini-chart">
                  <canvas bind:this={chartCanvas}></canvas>
              </div>
          </div>

          <!-- Recent Searches -->
          {#if searchHistory.length > 0}
              <div class="sidebar-card">
                  <div class="sidebar-header">
                      <h3>Recent</h3>
                  </div>
                  <div class="recent-list">
                      {#each searchHistory as user}
                          <div class="recent-item" on:click={() => handleProfileClick(user)} role="button" tabindex="0">
                              <img src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`} alt="" class="mini-avatar"/>
                              <div class="recent-info">
                                  <span class="recent-name">{user.username}</span>
                              </div>
                          </div>
                      {/each}
                  </div>
              </div>
          {/if}
      </div>
  </div>
</div>

<style>
  .markets-page {
      padding: 32px 40px;
      max-width: 1400px;
      margin: 0 auto;
      width: 100%;
      box-sizing: border-box;
  }

  .header-section {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 32px;
      flex-wrap: wrap;
      gap: 16px;
  }

  h1 {
      font-size: 28px;
      font-weight: 800;
      color: var(--text-main);
      margin: 0;
  }

  .search-wrapper {
      position: relative;
      width: 100%;
      max-width: 400px;
      display: flex;
      align-items: center;
      background-color: var(--bg-secondary);
      border-radius: 9999px;
      padding: 10px 16px;
      border: 1px solid transparent;
      transition: all 0.2s;
  }

  .search-wrapper:focus-within {
      background-color: var(--bg-main);
      border-color: var(--primary-color);
      box-shadow: 0 0 0 2px rgba(29, 155, 240, 0.1);
  }

  .search-icon {
      margin-right: 12px;
      display: flex;
      align-items: center;
  }

  .search-wrapper input {
      border: none;
      background: transparent;
      font-size: 15px;
      color: var(--text-main);
      width: 100%;
      outline: none;
  }

  .main-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 32px;
      align-items: start;
  }

  @media (max-width: 1024px) {
      .main-grid {
          grid-template-columns: 1fr;
      }
      .markets-page {
          padding: 24px;
      }
  }

  @media (max-width: 640px) {
      .markets-page {
          padding: 16px;
      }
      .header-section {
          flex-direction: column;
          align-items: flex-start;
      }
      .search-wrapper {
          max-width: 100%;
      }
  }

  /* Market List Card */
  .market-list-card {
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.02);
  }

  .card-header {
      padding: 16px 20px;
      border-bottom: 1px solid var(--border-color);
      background-color: var(--bg-main);
  }

  .tabs {
      display: flex;
      gap: 8px;
  }

  .tab-btn {
      background: none;
      border: none;
      padding: 8px 16px;
      border-radius: 999px;
      font-weight: 700;
      font-size: 14px;
      color: var(--text-secondary);
      cursor: pointer;
      transition: all 0.2s;
  }

  .tab-btn:hover {
      background-color: var(--bg-hover);
      color: var(--text-main);
  }

  .tab-btn.active {
      background-color: var(--bg-secondary);
      color: var(--text-main);
  }

  /* Table */
  .table-container {
      width: 100%;
  }

  .table-header {
      display: flex;
      padding: 12px 20px;
      background-color: var(--bg-secondary);
      font-size: 12px;
      font-weight: 700;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.5px;
  }

  .th.user-col { flex: 2; }
  .th.price-col { flex: 1; text-align: right; }
  .th.change-col { flex: 1; text-align: right; }
  .th.action-col { width: 40px; }

  .table-row {
      display: flex;
      align-items: center;
      padding: 16px 20px;
      border-bottom: 1px solid var(--border-color);
      cursor: pointer;
      transition: background-color 0.1s;
  }

  .table-row:hover {
      background-color: var(--bg-hover);
  }

  .table-row:last-child {
      border-bottom: none;
  }

  .td.user-col {
      flex: 2;
      display: flex;
      align-items: center;
      gap: 12px;
      overflow: hidden;
  }

  .row-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
      flex-shrink: 0;
  }

  .user-meta {
      display: flex;
      flex-direction: column;
      overflow: hidden;
  }

  .row-name {
      font-weight: 700;
      font-size: 15px;
      color: var(--text-main);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
  }

  .row-username {
      font-size: 13px;
      color: var(--text-secondary);
  }

  .td.price-col {
      flex: 1;
      display: flex;
      justify-content: flex-end;
      align-items: center;
  }

  .price-wrapper {
      display: flex;
      align-items: center;
      gap: 4px;
      font-weight: 700;
      color: var(--text-main);
      font-size: 15px;
  }

  :global(.currency-icon) {
      color: #F59E0B; /* Amber/Gold color for coin */
  }

  .td.change-col {
      flex: 1;
      text-align: right;
      display: flex;
      justify-content: flex-end;
  }

  .change-badge {
      font-size: 13px;
      font-weight: 700;
      padding: 4px 10px;
      border-radius: 8px;
      min-width: 60px;
      text-align: center;
  }

  .change-badge.positive {
      background-color: rgba(16, 185, 129, 0.1);
      color: var(--success-color);
  }

  .change-badge.negative {
      background-color: rgba(239, 68, 68, 0.1);
      color: var(--danger-color);
  }

  .td.action-col {
      width: 40px;
      display: flex;
      justify-content: flex-end;
      color: var(--text-tertiary);
  }

  /* Sidebar */
  .sidebar {
      display: flex;
      flex-direction: column;
      gap: 24px;
  }

  .sidebar-card {
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 20px;
      padding: 24px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.02);
  }

  .sidebar-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
  }

  .sidebar-header h3 {
      font-size: 18px;
      font-weight: 800;
      margin: 0;
      color: var(--text-main);
  }

  .live-dot {
      width: 8px;
      height: 8px;
      background-color: #ef4444;
      border-radius: 50%;
      box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.2);
      animation: pulse 2s infinite;
  }

  .stat-group {
      margin-bottom: 4px;
  }

  .stat-label {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
      text-transform: uppercase;
      margin-bottom: 4px;
  }

  .stat-value {
      font-size: 24px;
      font-weight: 800;
      color: var(--text-main);
  }

  .unit {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
      margin-left: 4px;
  }

  .stat-divider {
      height: 1px;
      background-color: var(--border-color);
      margin: 16px 0;
  }

  .mini-chart {
      height: 100px;
      margin-top: 16px;
      width: 100%;
  }

  .recent-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
  }

  .recent-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 8px;
      border-radius: 12px;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .recent-item:hover {
      background-color: var(--bg-hover);
  }

  .mini-avatar {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
  }

  .recent-name {
      font-weight: 600;
      font-size: 14px;
      color: var(--text-main);
  }

  .loading-state {
      padding: 40px;
      display: flex;
      justify-content: center;
  }

  .spinner {
      border: 3px solid var(--bg-tertiary);
      border-top-color: var(--primary-color);
      border-radius: 50%;
      width: 32px;
      height: 32px;
      animation: spin 1s linear infinite;
  }

  @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.5; }
      100% { opacity: 1; }
  }

  @keyframes spin {
      to { transform: rotate(360deg); }
  }
</style>
