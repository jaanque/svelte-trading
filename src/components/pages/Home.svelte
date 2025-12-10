<script lang="ts">
  import { onMount } from "svelte";
  import { TrendingUp, Users, DollarSign, Activity, ArrowUpRight, ArrowDownRight } from "lucide-svelte";

  // Placeholder data for the dashboard
  const stats = [
    { label: "Total Balance", value: "$12,450.00", change: "+2.5%", isPositive: true, icon: DollarSign },
    { label: "Active Markets", value: "24", change: "+4", isPositive: true, icon: TrendingUp },
    { label: "Open Positions", value: "7", change: "-1", isPositive: false, icon: Activity },
    { label: "Accionistas", value: "1.2k", change: "+12%", isPositive: true, icon: Users },
  ];

  const recentActivity = [
    { type: "Trade", description: "Bought 10 shares of AAPL", time: "2h ago", amount: "-$1,500.00" },
    { type: "Deposit", description: "Funds added to wallet", time: "5h ago", amount: "+$5,000.00" },
    { type: "Alert", description: "TSLA hit target price", time: "1d ago", amount: "" },
  ];
</script>

<div class="dashboard">
  <header class="page-header">
    <h1>Dashboard</h1>
    <p class="subtitle">Welcome back! Here's what's happening today.</p>
  </header>

  <section class="stats-grid">
    {#each stats as stat}
      <div class="stat-card">
        <div class="stat-icon">
          <svelte:component this={stat.icon} size={24} />
        </div>
        <div class="stat-content">
          <span class="stat-label">{stat.label}</span>
          <div class="stat-value-row">
            <span class="stat-value">{stat.value}</span>
            <span class="stat-change {stat.isPositive ? 'positive' : 'negative'}">
              {#if stat.isPositive}
                <ArrowUpRight size={14} />
              {:else}
                <ArrowDownRight size={14} />
              {/if}
              {stat.change}
            </span>
          </div>
        </div>
      </div>
    {/each}
  </section>

  <div class="main-grid">
    <section class="chart-section card">
      <h2>Market Overview</h2>
      <div class="placeholder-chart">
        <!-- Abstract chart visual -->
        <svg viewBox="0 0 500 150" preserveAspectRatio="none">
          <path d="M0,100 C50,100 50,50 100,50 C150,50 150,80 200,80 C250,80 250,20 300,20 C350,20 350,60 400,60 C450,60 450,40 500,40 V150 H0 Z" fill="rgba(29, 155, 240, 0.1)" stroke="none"/>
          <path d="M0,100 C50,100 50,50 100,50 C150,50 150,80 200,80 C250,80 250,20 300,20 C350,20 350,60 400,60 C450,60 450,40 500,40" fill="none" stroke="var(--primary-color)" stroke-width="3"/>
        </svg>
      </div>
    </section>

    <section class="activity-section card">
      <h2>Recent Activity</h2>
      <ul class="activity-list">
        {#each recentActivity as item}
          <li class="activity-item">
            <div class="activity-info">
              <span class="activity-type">{item.type}</span>
              <span class="activity-desc">{item.description}</span>
            </div>
            <div class="activity-meta">
              <span class="activity-amount {item.amount.startsWith('+') ? 'positive' : ''}">{item.amount}</span>
              <span class="activity-time">{item.time}</span>
            </div>
          </li>
        {/each}
      </ul>
    </section>
  </div>
</div>

<style>
  .dashboard {
    display: flex;
    flex-direction: column;
    gap: 24px;
  }

  .page-header h1 {
    margin-bottom: 4px;
  }

  .subtitle {
    color: var(--text-secondary);
    margin: 0;
    font-size: var(--font-size-md);
  }

  /* Stats Grid */
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
  }

  .stat-card {
    background: var(--bg-main);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 12px;
    transition: transform 0.2s, box-shadow 0.2s;
  }

  .stat-card:hover {
    transform: translateY(-2px);
    box-shadow: var(--shadow-sm);
    border-color: var(--primary-color);
  }

  .stat-icon {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: var(--bg-tertiary);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--primary-color);
  }

  .stat-label {
    font-size: var(--font-size-sm);
    color: var(--text-secondary);
    font-weight: 500;
  }

  .stat-value-row {
    display: flex;
    align-items: baseline;
    gap: 8px;
  }

  .stat-value {
    font-size: 24px;
    font-weight: 800;
    color: var(--text-main);
  }

  .stat-change {
    display: flex;
    align-items: center;
    font-size: 13px;
    font-weight: 600;
  }

  .stat-change.positive { color: var(--success-color); }
  .stat-change.negative { color: var(--danger-color); }

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
    border-radius: 16px;
    padding: 24px;
  }

  h2 {
    font-size: 20px;
    margin-bottom: 20px;
  }

  .placeholder-chart {
    width: 100%;
    height: 200px;
    background: linear-gradient(180deg, rgba(255,255,255,0) 0%, rgba(29,155,240,0.05) 100%);
    border-radius: 12px;
    overflow: hidden;
    display: flex;
    align-items: flex-end;
  }

  .placeholder-chart svg {
    width: 100%;
    height: 100%;
  }

  /* Activity List */
  .activity-list {
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .activity-item {
    display: flex;
    justify-content: space-between;
    padding: 12px 0;
    border-bottom: 1px solid var(--border-color);
  }

  .activity-item:last-child {
    border-bottom: none;
  }

  .activity-info {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .activity-type {
    font-size: 13px;
    font-weight: 700;
    color: var(--text-secondary);
  }

  .activity-desc {
    font-size: 15px;
    font-weight: 500;
  }

  .activity-meta {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 4px;
  }

  .activity-amount {
    font-weight: 700;
    font-size: 15px;
  }

  .activity-amount.positive {
    color: var(--success-color);
  }

  .activity-time {
    font-size: 12px;
    color: var(--text-tertiary);
  }
</style>
