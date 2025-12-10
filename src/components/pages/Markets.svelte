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

<div class="explore-container">
  <div class="main-column">
      <!-- Search Bar Header -->
      <div class="search-header">
        <div class="search-bar">
          <div class="search-icon">
            <Search size={20} color="var(--text-secondary)" />
          </div>
          <input
            type="text"
            placeholder="Search for users..."
            bind:value={searchQuery}
            on:input={handleInput}
          />
        </div>
      </div>

      <!-- Mobile Market Highlights -->
      <div class="mobile-market-highlights">
          {#if dailyStats}
              <div class="highlight-card">
                  <div class="highlight-item">
                      <span class="label">24h Vol</span>
                      <span class="value">{dailyStats.volume.toLocaleString()}</span>
                  </div>
                  <div class="highlight-divider"></div>
                  <div class="highlight-item">
                      <span class="label">Trades</span>
                      <span class="value">{dailyStats.count}</span>
                  </div>
              </div>
          {/if}
      </div>

      <!-- Content -->
      <div class="results-container">
    {#if isLoading}
      <div class="loading-state">
        <div class="spinner"></div>
      </div>
    {:else if searchQuery.trim() === ""}

      <!-- History View -->
      {#if searchHistory.length > 0}
        <div class="history-section">
            <div class="section-header">
            <h2>
                <Clock size={20} class="icon-inline" />
                Recent Searches
            </h2>
            </div>
            <div class="history-grid">
                {#each searchHistory as user (user.id)}
                    <div role="button" tabindex="0" class="card-wrapper">
                        <UserCard
                            {user}
                            onClick={() => handleProfileClick(user)}
                        />
                    </div>
                {/each}
            </div>
        </div>
      {/if}

      <!-- Top Movers Section -->
      <div class="movers-section">
         <div class="tabs-header">
             <button
               class="tab-btn {activeTab === 'gainers' ? 'active' : ''}"
               on:click={() => activeTab = 'gainers'}
             >
                 <TrendingUp size={18} />
                 Top Gainers
             </button>
             <button
               class="tab-btn {activeTab === 'losers' ? 'active' : ''}"
               on:click={() => activeTab = 'losers'}
             >
                 <TrendingDown size={18} />
                 Top Losers
             </button>
         </div>

         {#if moversLoading}
             <div class="loading-state-mini">
                 <div class="spinner-small"></div>
             </div>
         {:else}
             {#if activeTab === 'gainers'}
                 {#if topGainers.length > 0}
                    <div class="history-grid">
                        {#each topGainers as user (user.id)}
                            <div role="button" tabindex="0" class="card-wrapper">
                                <UserCard
                                    {user}
                                    onClick={() => handleProfileClick(user)}
                                >
                                    <div class="price-info">
                                        <span class="current-price">{formatPrice(user.current_price || 0)}</span>
                                        <div class="trend-badge positive">
                                            +{user.change_pct.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}%
                                        </div>
                                    </div>
                                </UserCard>
                            </div>
                        {/each}
                    </div>
                 {:else}
                    <div class="empty-list-state">
                        <p>No gainers in the last 24h</p>
                    </div>
                 {/if}
             {:else}
                 {#if topLosers.length > 0}
                    <div class="history-grid">
                        {#each topLosers as user (user.id)}
                            <div role="button" tabindex="0" class="card-wrapper">
                                <UserCard
                                    {user}
                                    onClick={() => handleProfileClick(user)}
                                >
                                    <div class="price-info">
                                        <span class="current-price">{formatPrice(user.current_price || 0)}</span>
                                        <div class="trend-badge negative">
                                            {user.change_pct.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}%
                                        </div>
                                    </div>
                                </UserCard>
                            </div>
                        {/each}
                    </div>
                 {:else}
                    <div class="empty-list-state">
                        <p>No losers in the last 24h</p>
                    </div>
                 {/if}
             {/if}
         {/if}
      </div>

    {:else if searchResults.length === 0}
      <div class="no-results">
        <p>No results for "{searchQuery}"</p>
      </div>
    {:else}
      <!-- Search Results List -->
      <div class="users-list">
        {#each searchResults as user}
          <a href={`/profile?u=${user.username}`} class="user-list-item" on:click|preventDefault={() => handleProfileClick(user)}>
            <div class="avatar">
              <img
                src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`}
                alt={user.username}
              />
            </div>
            <div class="user-info">
              <span class="fullname">{user.full_name || "Unknown"}</span>
              <span class="username">${user.username.toUpperCase()}</span>
            </div>
            {#if user.price}
                <div class="list-price">
                    {formatPrice(user.price)}
                </div>
            {/if}
          </a>
        {/each}
      </div>
    {/if}
      </div>
  </div>

  <!-- Right Sidebar -->
  <div class="right-sidebar">
      <div class="stats-card">
          <div class="stats-header">
              <h2>Market Overview</h2>
              <span class="live-badge">Live</span>
          </div>

          {#if statsLoading}
              <div class="loading-state-mini">
                  <div class="spinner-small"></div>
              </div>
          {:else if dailyStats}
              <div class="stats-grid">
                  <div class="stat-item">
                      <div class="stat-icon">
                          <Activity size={18} color="#1d9bf0" />
                      </div>
                      <div class="stat-info">
                          <span class="stat-label">Transactions Today</span>
                          <span class="stat-value">{dailyStats.count}</span>
                      </div>
                  </div>
                  <div class="stat-item">
                      <div class="stat-icon">
                          <DollarSign size={18} color="#10B981" />
                      </div>
                      <div class="stat-info">
                          <span class="stat-label">Volume Today</span>
                          <span class="stat-value">{dailyStats.volume.toLocaleString()} Tokens</span>
                      </div>
                  </div>
              </div>

              <div class="chart-container">
                  <canvas bind:this={chartCanvas}></canvas>
              </div>
          {:else}
              <div class="empty-list-state">
                  <p>No market data available</p>
              </div>
          {/if}
      </div>
  </div>
</div>

<style>
  .explore-container {
    display: flex;
    width: 100%;
    gap: 40px;
    padding: 24px 40px;
    box-sizing: border-box;
    max-width: 1600px;
    margin: 0 auto;
  }

  .main-column {
      flex: 1;
      min-width: 0;
  }

  .right-sidebar {
      width: 350px;
      flex-shrink: 0;
      display: none;
      padding-top: 0px;
  }

  @media (min-width: 1024px) {
      .right-sidebar {
          display: block;
      }
      .mobile-market-highlights {
          display: none;
      }
  }

  @media (max-width: 1024px) {
      .explore-container {
          padding: 24px;
          gap: 24px;
      }
  }

  @media (max-width: 640px) {
      .explore-container {
          padding: 16px;
      }
  }

  /* Mobile Highlights */
  .mobile-market-highlights {
      margin-bottom: 24px;
  }
  .highlight-card {
      display: flex;
      justify-content: space-around;
      align-items: center;
      background-color: var(--bg-secondary);
      border-radius: 12px;
      padding: 16px;
      border: 1px solid var(--border-color);
  }
  .highlight-item {
      display: flex;
      flex-direction: column;
      align-items: center;
  }
  .highlight-item .label {
      font-size: 12px;
      color: var(--text-secondary);
      text-transform: uppercase;
      font-weight: 600;
  }
  .highlight-item .value {
      font-size: 18px;
      font-weight: 800;
      color: var(--text-main);
  }
  .highlight-divider {
      width: 1px;
      height: 30px;
      background-color: var(--border-color);
  }

  /* Right Sidebar Stats */
  .stats-card {
      background-color: var(--bg-secondary);
      border-radius: 16px;
      padding: 20px;
      position: sticky;
      top: 20px;
  }

  .stats-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
  }

  .stats-header h2 {
      font-size: 18px;
      font-weight: 800;
      margin: 0;
      color: var(--text-main);
  }

  .live-badge {
      background-color: var(--danger-color, #EF4444);
      color: white;
      font-size: 11px;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 4px;
      text-transform: uppercase;
      animation: pulse 2s infinite;
  }

  @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.6; }
      100% { opacity: 1; }
  }

  .stats-grid {
      display: flex;
      flex-direction: column;
      gap: 16px;
      margin-bottom: 24px;
  }

  .stat-item {
      display: flex;
      align-items: center;
  }

  .stat-icon {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background-color: var(--bg-main);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-right: 12px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  }

  .stat-info {
      display: flex;
      flex-direction: column;
  }

  .stat-label {
      font-size: 13px;
      color: var(--text-secondary);
  }

  .stat-value {
      font-size: 16px;
      font-weight: 700;
      color: var(--text-main);
  }

  .chart-container {
      height: 120px;
      width: 100%;
      background-color: var(--bg-main);
      border-radius: 12px;
      padding: 8px;
      box-sizing: border-box;
  }

  .search-header {
    margin-bottom: 32px;
    position: relative;
    z-index: 10;
  }

  .search-bar {
    display: flex;
    align-items: center;
    background-color: var(--bg-secondary, #eff3f4);
    border-radius: 9999px;
    padding: 0 12px;
    height: 44px;
    border: 1px solid transparent;
    transition: background-color 0.2s, border-color 0.2s, box-shadow 0.2s;
  }

  .search-bar:focus-within {
    background-color: var(--bg-main, #ffffff);
    border-color: var(--primary-color, #1d9bf0);
    box-shadow: 0 0 0 1px var(--primary-color, #1d9bf0);
  }

  .search-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 12px;
  }

  .search-bar input {
    flex-grow: 1;
    background: transparent;
    border: none;
    outline: none;
    font-size: 15px;
    color: var(--text-main, #0f1419);
    height: 100%;
  }

  .search-bar input::placeholder {
    color: var(--text-secondary, #536471);
  }

  .results-container {
    min-height: 200px;
  }

  .empty-state, .no-results {
    padding: 40px 20px;
    text-align: center;
    color: var(--text-secondary, #536471);
    font-size: 15px;
  }

  .history-section, .movers-section {
    margin-bottom: 32px;
  }

  .section-header {
    margin-bottom: 16px;
    padding: 0 4px;
  }

  .section-header h2 {
    font-size: 20px;
    font-weight: 800;
    color: var(--text-main, #0f1419);
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 0;
  }

  .tabs-header {
      display: flex;
      gap: 12px;
      margin-bottom: 20px;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 12px;
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

  :global(.icon-inline) {
      margin-bottom: -2px;
  }

  .history-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 16px;
    padding-bottom: 20px;
  }

  .card-wrapper {
      height: 100%;
      cursor: pointer;
  }

  .price-info {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      margin-top: 8px;
  }

  .current-price {
      font-size: 15px;
      font-weight: 800;
      color: var(--text-main);
  }

  .trend-badge {
      font-size: 13px;
      font-weight: 700;
      padding: 4px 8px;
      border-radius: 999px;
      display: inline-block;
  }

  .trend-badge.positive {
      color: var(--success-color, #10B981);
      background-color: rgba(16, 185, 129, 0.1);
  }

  .trend-badge.negative {
      color: var(--danger-color, #EF4444);
      background-color: rgba(239, 68, 68, 0.1);
  }

  .users-list {
    display: flex;
    flex-direction: column;
  }

  .user-list-item {
    display: flex;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color, #eff3f4);
    text-decoration: none;
    transition: background-color 0.2s;
    cursor: pointer;
  }

  .user-list-item:hover {
    background-color: var(--bg-hover, #f7f9f9);
  }

  .avatar {
    margin-right: 12px;
    width: 48px;
    height: 48px;
    flex-shrink: 0;
  }

  .avatar img {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    background-color: var(--bg-tertiary, #cfd9de);
  }

  .user-info {
    display: flex;
    flex-direction: column;
    justify-content: center;
    flex-grow: 1;
  }

  .list-price {
      font-weight: 700;
      color: var(--text-main);
  }

  .fullname {
    font-weight: 700;
    font-size: 15px;
    color: var(--text-main, #0f1419);
  }

  .username {
    font-size: 14px;
    color: var(--text-secondary, #536471);
  }

  .loading-state {
    display: flex;
    justify-content: center;
    padding: 40px;
  }

  .spinner {
    border: 3px solid var(--bg-tertiary, #cfd9de);
    border-top: 3px solid var(--primary-color, #1d9bf0);
    border-radius: 50%;
    width: 24px;
    height: 24px;
    animation: spin 1s linear infinite;
  }

  .loading-state-mini {
      display: flex;
      justify-content: center;
      padding: 20px;
  }

  .spinner-small {
      border: 2px solid var(--bg-tertiary, #cfd9de);
      border-top: 2px solid var(--primary-color, #1d9bf0);
      border-radius: 50%;
      width: 18px;
      height: 18px;
      animation: spin 1s linear infinite;
  }

  .empty-list-state {
      padding: 20px;
      text-align: center;
      color: var(--text-secondary);
      background-color: var(--bg-secondary);
      border-radius: 12px;
      font-size: 14px;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style>
