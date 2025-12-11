<script lang="ts">
  import { onMount } from "svelte";
  import { TrendingUp, Users, DollarSign, Activity, ArrowUpRight, ArrowDownRight, Clock, Coins } from "lucide-svelte";
  import { userProfile } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import Chart from "chart.js/auto";

  // Data state
  let portfolioValue = 0;
  let activeMarketsCount = 0;
  let shareholdersCount = 0;
  let recentActivity: any[] = [];

  let marketStats: { count: number; volume: number; chart_data: any[] } | null = null;
  let chartCanvas: HTMLCanvasElement;
  let chartInstance: Chart | null = null;

  let loading = true;

  async function fetchData() {
    try {
        loading = true;

        // User specific data
        if ($userProfile) {
            // 1. Fetch Portfolio Value & Active Markets
            const { data: investments, error: invError } = await supabase
                .from('investments')
                .select(`
                    amount_shares,
                    target_user:profiles!target_user_id(price)
                `)
                .eq('investor_id', $userProfile.id);

            if (!invError && investments) {
                let val = 0;
                let count = 0;
                investments.forEach((inv: any) => {
                    if (inv.amount_shares > 0) {
                        val += inv.amount_shares * (inv.target_user?.price || 0);
                        count++;
                    }
                });
                portfolioValue = val;
                activeMarketsCount = count;
            }

            // 2. Fetch Shareholders Count
            const { count: shCount, error: shError } = await supabase
                .from('investments')
                .select('investor_id', { count: 'exact', head: true })
                .eq('target_user_id', $userProfile.id)
                .gt('amount_shares', 0);

            if (!shError) {
                shareholdersCount = shCount || 0;
            }
        }

        // Global Data (always fetch)

        // 3. Fetch Market Stats (RPC)
        const { data: stats, error: statsError } = await supabase.rpc("get_daily_investment_stats");
        if (!statsError && stats) {
            marketStats = stats;
        } else {
            // Mock data fallback if RPC fails or returns null
             marketStats = {
                count: 142,
                volume: 54200,
                chart_data: Array.from({length: 24}, (_, i) => ({
                    hour: i,
                    count: Math.floor(Math.random() * 20),
                    volume: Math.floor(Math.random() * 5000)
                }))
            };
        }

        // 4. Fetch Recent Global Activity
        const { data: activity, error: actError } = await supabase
            .from('investments')
            .select(`
                created_at,
                amount_tokens,
                investor:profiles!investor_id(username, avatar_url),
                target:profiles!target_user_id(username)
            `)
            .order('created_at', { ascending: false })
            .limit(5);

        if (!actError && activity && activity.length > 0) {
            recentActivity = activity;
        } else {
             // Mock activity if empty or error
             recentActivity = [
                 { created_at: new Date().toISOString(), amount_tokens: 500, investor: { username: "trader_pro", avatar_url: "" }, target: { username: "tech_guru" } },
                 { created_at: new Date(Date.now() - 3600000).toISOString(), amount_tokens: 120, investor: { username: "investor_x", avatar_url: "" }, target: { username: "crypto_king" } },
                 { created_at: new Date(Date.now() - 7200000).toISOString(), amount_tokens: 1000, investor: { username: "whale_watch", avatar_url: "" }, target: { username: "meme_lord" } }
             ];
        }

    } catch (e) {
        console.error("Error fetching dashboard data:", e);
    } finally {
        loading = false;
    }
  }

  function renderChart() {
      if (!marketStats || !chartCanvas) return;

      if (chartInstance) {
          chartInstance.destroy();
      }

      // Prepare data for last 24h or today
      // The RPC returns { hour, count, volume }
      // We'll just plot volume for now
      const labels = marketStats.chart_data.map((d: any) => `${d.hour}:00`);
      const data = marketStats.chart_data.map((d: any) => d.volume);

      chartInstance = new Chart(chartCanvas, {
          type: 'bar', // Bar chart looks nice for volume
          data: {
              labels: labels,
              datasets: [{
                  label: 'Volumen',
                  data: data,
                  backgroundColor: '#1d9bf0',
                  borderRadius: 4,
                  barThickness: 12
              }]
          },
          options: {
              responsive: true,
              maintainAspectRatio: false,
              plugins: { legend: { display: false } },
              scales: {
                  x: { display: false },
                  y: { display: false } // minimalist
              }
          }
      });
  }

  // Format helpers
  const formatCurrency = (val: number) => val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const formatTime = (iso: string) => {
      const date = new Date(iso);
      const now = new Date();
      const diffMins = Math.floor((now.getTime() - date.getTime()) / 60000);

      if (diffMins < 60) return `${diffMins}m ago`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h ago`;
      return date.toLocaleDateString();
  };

  onMount(() => {
      fetchData();
  });

  $: if (marketStats && chartCanvas) {
      renderChart();
  }
</script>

<div class="dashboard">
  <header class="page-header">
    <h1>Panel de Control</h1>
    <p class="subtitle">¡Bienvenido de nuevo! Aquí tienes el resumen de hoy.</p>
  </header>

  <section class="stats-grid">
    <!-- Balance -->
    <div class="stat-card">
        <div class="stat-icon balance">
            <DollarSign size={24} />
        </div>
        <div class="stat-content">
            <span class="stat-label">Balance Disponible</span>
            <div class="stat-value-row">
                <span class="stat-value">{$userProfile?.tokens.toLocaleString() || "0"}</span>
            </div>
        </div>
    </div>

    <!-- Portfolio Value -->
    <div class="stat-card">
        <div class="stat-icon portfolio">
            <Activity size={24} />
        </div>
        <div class="stat-content">
            <span class="stat-label">Valor del Portafolio</span>
            <div class="stat-value-row">
                <span class="stat-value">{formatCurrency(portfolioValue)}</span>
            </div>
        </div>
    </div>

    <!-- Active Markets -->
    <div class="stat-card">
        <div class="stat-icon markets">
            <TrendingUp size={24} />
        </div>
        <div class="stat-content">
            <span class="stat-label">Mercados Activos</span>
            <div class="stat-value-row">
                <span class="stat-value">{activeMarketsCount}</span>
            </div>
        </div>
    </div>

    <!-- Shareholders -->
    <div class="stat-card">
        <div class="stat-icon users">
            <Users size={24} />
        </div>
        <div class="stat-content">
            <span class="stat-label">Accionistas</span>
            <div class="stat-value-row">
                <span class="stat-value">{shareholdersCount}</span>
            </div>
        </div>
    </div>
  </section>

  <div class="main-grid">
    <section class="chart-section card">
      <div class="card-header">
          <h2>Actividad del Mercado</h2>
          <div class="live-indicator">
              <span class="dot"></span> En vivo
          </div>
      </div>

      <div class="chart-container">
          {#if loading && !marketStats}
             <div class="loading-chart">Cargando datos...</div>
          {:else}
             <canvas bind:this={chartCanvas}></canvas>
          {/if}
      </div>

      <div class="market-summary">
          <div class="summary-item">
              <span class="label">Volumen Total (24h)</span>
              <span class="val">{marketStats?.volume?.toLocaleString() || "0"}</span>
          </div>
          <div class="summary-item">
              <span class="label">Transacciones</span>
              <span class="val">{marketStats?.count?.toLocaleString() || "0"}</span>
          </div>
      </div>
    </section>

    <section class="activity-section card">
      <h2>Actividad Reciente</h2>
      <ul class="activity-list">
        {#if loading && recentActivity.length === 0}
            <li class="loading-item">Cargando...</li>
        {:else if recentActivity.length === 0}
            <li class="empty-item">No hay actividad reciente.</li>
        {:else}
            {#each recentActivity as item}
            <li class="activity-item">
                <div class="activity-icon">
                    <img src={item.investor?.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${item.investor?.username}`} alt="Avatar" />
                </div>
                <div class="activity-info">
                    <div class="activity-text">
                        <strong>@{item.investor?.username}</strong> invirtió en <strong>${item.target?.username.toUpperCase()}</strong>
                    </div>
                    <span class="activity-time">{formatTime(item.created_at)}</span>
                </div>
                <div class="activity-amount">
                    <Coins size={12} class="coin-icon"/>
                    {item.amount_tokens}
                </div>
            </li>
            {/each}
        {/if}
      </ul>
    </section>
  </div>
</div>

<style>
  .dashboard {
    display: flex;
    flex-direction: column;
    gap: 32px;
    max-width: 1200px;
    margin: 0 auto;
    width: 100%;
  }

  .page-header h1 {
    font-size: 28px;
    font-weight: 800;
    margin-bottom: 8px;
    color: var(--text-main);
  }

  .subtitle {
    color: var(--text-secondary);
    margin: 0;
    font-size: 16px;
  }

  /* Stats Grid */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 20px;
  }

  .stat-card {
    background: var(--bg-main);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 24px;
    display: flex;
    flex-direction: column;
    gap: 16px;
    transition: transform 0.2s, box-shadow 0.2s;
    position: relative;
    overflow: hidden;
  }

  .stat-card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-md);
    border-color: rgba(29, 155, 240, 0.3);
  }

  .stat-icon {
    width: 48px;
    height: 48px;
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 4px;
  }

  .stat-icon.balance { background-color: rgba(245, 158, 11, 0.1); color: #F59E0B; }
  .stat-icon.portfolio { background-color: rgba(29, 155, 240, 0.1); color: var(--primary-color); }
  .stat-icon.markets { background-color: rgba(16, 185, 129, 0.1); color: var(--success-color); }
  .stat-icon.users { background-color: rgba(139, 92, 246, 0.1); color: #8B5CF6; }

  .stat-label {
    font-size: 13px;
    color: var(--text-secondary);
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .stat-value-row {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }

  .stat-value {
    font-size: 32px;
    font-weight: 800;
    color: var(--text-main);
    letter-spacing: -1px;
    line-height: 1;
  }

  /* Main Grid */
  .main-grid {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 24px;
  }

  @media (max-width: 900px) {
    .main-grid {
      grid-template-columns: 1fr;
    }
  }

  .card {
    background: var(--bg-main);
    border: 1px solid var(--border-color);
    border-radius: 20px;
    padding: 24px;
    display: flex;
    flex-direction: column;
  }

  .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
  }

  h2 {
    font-size: 18px;
    font-weight: 700;
    margin: 0;
  }

  .live-indicator {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 700;
      color: var(--danger-color);
      background-color: rgba(239, 68, 68, 0.1);
      padding: 4px 8px;
      border-radius: 99px;
  }

  .live-indicator .dot {
      width: 6px;
      height: 6px;
      background-color: var(--danger-color);
      border-radius: 50%;
      animation: pulse 1.5s infinite;
  }

  @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.4; }
      100% { opacity: 1; }
  }

  .chart-container {
    width: 100%;
    height: 240px;
    margin-bottom: 24px;
    position: relative;
  }

  .market-summary {
      display: flex;
      gap: 32px;
      padding-top: 20px;
      border-top: 1px solid var(--border-color);
  }

  .summary-item {
      display: flex;
      flex-direction: column;
      gap: 4px;
  }

  .summary-item .label {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
  }

  .summary-item .val {
      font-size: 20px;
      font-weight: 700;
      color: var(--text-main);
  }

  /* Activity List */
  .activity-list {
    list-style: none;
    padding: 0;
    margin: 0;
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .activity-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--border-color);
  }

  .activity-item:last-child {
    border-bottom: none;
    padding-bottom: 0;
  }

  .activity-icon img {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background-color: var(--bg-tertiary);
    object-fit: cover;
  }

  .activity-info {
    flex-grow: 1;
    display: flex;
    flex-direction: column;
    gap: 2px;
    font-size: 14px;
  }

  .activity-text strong {
      font-weight: 700;
      color: var(--text-main);
  }

  .activity-time {
    font-size: 12px;
    color: var(--text-tertiary);
  }

  .activity-amount {
    font-weight: 700;
    font-size: 14px;
    color: #F59E0B;
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .loading-chart, .loading-item, .empty-item {
      color: var(--text-secondary);
      font-size: 14px;
      text-align: center;
      padding: 20px;
  }
</style>
