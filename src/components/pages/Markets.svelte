<script lang="ts">
  import { Search, Clock, TrendingUp, TrendingDown, Activity, DollarSign, BarChart2 } from "lucide-svelte";
  import { supabase } from "../../lib/supabase";
  import { onMount } from "svelte";
  import UserCard from "../../components/general/UserCard.svelte";
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
                  label: 'Volume (Tokens)',
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
              plugins: {
                  legend: { display: false },
                  tooltip: {
                      mode: 'index',
                      intersect: false,
                  }
              },
              scales: {
                  x: { display: false },
                  y: { display: false }
              },
              interaction: {
                  intersect: false,
                  mode: 'index',
              },
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
        .limit(10);

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

      topGainers = sorted.filter(u => u.change_pct > 0).slice(0, 5);
      topLosers = sorted.filter(u => u.change_pct < 0).reverse().slice(0, 5);

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
      return num.toLocaleString(undefined, { maximumFractionDigits: 0 });
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
  <div class="markets-grid">
      <!-- Main Column: Search & Discovery -->
      <div class="main-column">
          <div class="search-header">
              <h1>Explore Markets</h1>
              <div class="search-bar">
                  <div class="search-icon">
                      <Search size={20} color="var(--text-secondary)" />
                  </div>
                  <input
                      type="text"
                      placeholder="Search for traders, stocks..."
                      bind:value={searchQuery}
                      on:input={handleInput}
                  />
              </div>
          </div>

          <div class="content-area">
              {#if isLoading}
                  <div class="loading-state"><div class="spinner"></div></div>
              {:else if searchQuery.trim() === ""}

                  <!-- Recent Searches -->
                  {#if searchHistory.length > 0}
                      <section class="market-section">
                          <h2 class="section-title"><Clock size={18} /> Recent Searches</h2>
                          <div class="cards-grid">
                              {#each searchHistory as user (user.id)}
                                  <div class="card-item">
                                      <UserCard {user} onClick={() => handleProfileClick(user)} />
                                  </div>
                              {/each}
                          </div>
                      </section>
                  {/if}

                  <!-- Top Movers -->
                  <section class="market-section">
                      <div class="tabs-header">
                          <button class="tab-btn {activeTab === 'gainers' ? 'active' : ''}" on:click={() => activeTab = 'gainers'}>
                              <TrendingUp size={18} /> Top Gainers
                          </button>
                          <button class="tab-btn {activeTab === 'losers' ? 'active' : ''}" on:click={() => activeTab = 'losers'}>
                              <TrendingDown size={18} /> Top Losers
                          </button>
                      </div>

                      {#if moversLoading}
                          <div class="loading-mini"><div class="spinner-small"></div></div>
                      {:else}
                          <div class="cards-grid">
                              {#if activeTab === 'gainers'}
                                  {#each topGainers as user}
                                      <div class="card-item">
                                          <UserCard {user} onClick={() => handleProfileClick(user)}>
                                              <div class="price-row">
                                                  <span class="price">{formatPrice(user.current_price || 0)}</span>
                                                  <span class="badge positive">+{user.change_pct.toFixed(2)}%</span>
                                              </div>
                                          </UserCard>
                                      </div>
                                  {/each}
                              {:else}
                                  {#each topLosers as user}
                                      <div class="card-item">
                                          <UserCard {user} onClick={() => handleProfileClick(user)}>
                                              <div class="price-row">
                                                  <span class="price">{formatPrice(user.current_price || 0)}</span>
                                                  <span class="badge negative">{user.change_pct.toFixed(2)}%</span>
                                              </div>
                                          </UserCard>
                                      </div>
                                  {/each}
                              {/if}
                          </div>
                      {/if}
                  </section>

              {:else if searchResults.length === 0}
                  <div class="no-results">
                      <p>No results found for "{searchQuery}"</p>
                  </div>
              {:else}
                  <div class="search-results-list">
                      {#each searchResults as user}
                          <a href={`/profile?u=${user.username}`} class="result-item" on:click|preventDefault={() => handleProfileClick(user)}>
                              <img src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`} alt="" class="result-avatar"/>
                              <div class="result-info">
                                  <span class="name">{user.full_name || user.username}</span>
                                  <span class="handle">${user.username.toUpperCase()}</span>
                              </div>
                              <span class="result-price">{formatPrice(user.price)}</span>
                          </a>
                      {/each}
                  </div>
              {/if}
          </div>
      </div>

      <!-- Right Sidebar: Stats -->
      <div class="sidebar-column">
          <div class="stats-card">
              <div class="stats-header">
                  <h2>Market Overview</h2>
                  <span class="live-badge">LIVE</span>
              </div>

              {#if statsLoading}
                  <div class="loading-mini"><div class="spinner-small"></div></div>
              {:else if dailyStats}
                  <div class="stats-rows">
                      <div class="stat-row">
                          <div class="icon-bg blue"><Activity size={18} /></div>
                          <div class="stat-data">
                              <span class="label">Transactions</span>
                              <span class="value">{dailyStats.count}</span>
                          </div>
                      </div>
                      <div class="stat-row">
                          <div class="icon-bg green"><DollarSign size={18} /></div>
                          <div class="stat-data">
                              <span class="label">Volume (24h)</span>
                              <span class="value">{dailyStats.volume.toLocaleString()}</span>
                          </div>
                      </div>
                  </div>
                  <div class="chart-wrapper">
                      <canvas bind:this={chartCanvas}></canvas>
                  </div>
              {:else}
                  <div class="empty-text">No data available</div>
              {/if}
          </div>
      </div>
  </div>
</div>

<style>
  .markets-page {
      padding: 32px 40px;
      max-width: 100%;
      box-sizing: border-box;
      min-height: 100vh;
  }

  .markets-grid {
      display: grid;
      grid-template-columns: 2fr 1fr;
      gap: 40px;
      max-width: 1400px;
      margin: 0 auto;
  }

  @media (max-width: 1024px) {
      .markets-grid {
          grid-template-columns: 1fr;
      }
      .sidebar-column {
          display: none;
      }
  }

  @media (max-width: 640px) {
      .markets-page {
          padding: 16px;
      }
  }

  /* Main Column */
  .search-header {
      margin-bottom: 32px;
  }

  .search-header h1 {
      font-size: 28px;
      font-weight: 800;
      margin-bottom: 16px;
      color: var(--text-main);
  }

  .search-bar {
      display: flex;
      align-items: center;
      background-color: var(--bg-secondary);
      border-radius: 16px;
      padding: 12px 16px;
      transition: all 0.2s;
      border: 1px solid transparent;
  }

  .search-bar:focus-within {
      background-color: var(--bg-main);
      box-shadow: 0 0 0 2px var(--primary-color);
  }

  .search-icon {
      margin-right: 12px;
      display: flex;
      align-items: center;
  }

  .search-bar input {
      border: none;
      background: transparent;
      outline: none;
      font-size: 16px;
      width: 100%;
      color: var(--text-main);
  }

  /* Content */
  .market-section {
      margin-bottom: 40px;
  }

  .section-title {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 16px;
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--text-main);
  }

  .cards-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
      gap: 16px;
  }

  /* Tabs */
  .tabs-header {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 8px;
  }

  .tab-btn {
      background: none;
      border: none;
      font-size: 16px;
      font-weight: 600;
      color: var(--text-secondary);
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 8px 12px;
      border-radius: 8px;
      transition: all 0.2s;
  }

  .tab-btn:hover {
      background-color: var(--bg-secondary);
      color: var(--text-main);
  }

  .tab-btn.active {
      color: var(--text-main);
      background-color: var(--bg-secondary);
  }

  /* Card Extras */
  .price-row {
      margin-top: 8px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      width: 100%;
  }

  .price {
      font-weight: 700;
      font-size: 14px;
      color: var(--text-main);
  }

  .badge {
      font-size: 12px;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 999px;
  }
  .badge.positive { background-color: rgba(16,185,129,0.1); color: var(--success-color); }
  .badge.negative { background-color: rgba(239,68,68,0.1); color: var(--danger-color); }

  /* Search Results List */
  .search-results-list {
      display: flex;
      flex-direction: column;
      gap: 8px;
  }

  .result-item {
      display: flex;
      align-items: center;
      padding: 12px;
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      text-decoration: none;
      transition: background-color 0.2s;
  }

  .result-item:hover {
      background-color: var(--bg-hover);
  }

  .result-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      margin-right: 12px;
      background-color: var(--bg-tertiary);
  }

  .result-info {
      flex: 1;
      display: flex;
      flex-direction: column;
  }

  .name {
      font-weight: 700;
      color: var(--text-main);
  }

  .handle {
      font-size: 13px;
      color: var(--text-secondary);
  }

  .result-price {
      font-weight: 700;
      color: var(--text-main);
  }

  /* Sidebar Stats */
  .stats-card {
      background-color: var(--bg-secondary);
      border-radius: 24px;
      padding: 24px;
      position: sticky;
      top: 24px;
  }

  .stats-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
  }

  .stats-header h2 {
      margin: 0;
      font-size: 18px;
      font-weight: 800;
  }

  .live-badge {
      background-color: #ef4444;
      color: white;
      font-size: 10px;
      font-weight: 800;
      padding: 2px 6px;
      border-radius: 4px;
      animation: pulse 2s infinite;
  }

  .stats-rows {
      display: flex;
      flex-direction: column;
      gap: 20px;
      margin-bottom: 24px;
  }

  .stat-row {
      display: flex;
      align-items: center;
      gap: 16px;
  }

  .icon-bg {
      width: 40px;
      height: 40px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
  }
  .icon-bg.blue { background-color: #3b82f6; }
  .icon-bg.green { background-color: #10b981; }

  .stat-data {
      display: flex;
      flex-direction: column;
  }

  .stat-data .label {
      font-size: 12px;
      color: var(--text-secondary);
      text-transform: uppercase;
      font-weight: 600;
  }

  .stat-data .value {
      font-size: 18px;
      font-weight: 800;
      color: var(--text-main);
  }

  .chart-wrapper {
      height: 150px;
      width: 100%;
  }

  /* Loading */
  .loading-state, .loading-mini {
      display: flex;
      justify-content: center;
      padding: 20px;
  }
  .spinner, .spinner-small {
      border: 3px solid var(--bg-tertiary);
      border-top-color: var(--primary-color);
      border-radius: 50%;
      animation: spin 1s linear infinite;
  }
  .spinner { width: 32px; height: 32px; }
  .spinner-small { width: 20px; height: 20px; border-width: 2px; }

  .no-results {
      text-align: center;
      padding: 40px;
      color: var(--text-secondary);
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
