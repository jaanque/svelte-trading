<script lang="ts">
  import { onMount } from "svelte";
  import { TrendingUp, TrendingDown, Users, DollarSign, Activity, ArrowUpRight, ArrowDownRight, Clock, Coins, MessageCircle, Heart, Share2, Image as ImageIcon, BarChart2, Smile, Gift, ThumbsUp, ThumbsDown, UserPlus, Plus } from "lucide-svelte";
  import { userProfile } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import Chart from "chart.js/auto";
  import CreatePostModal from "../../components/general/CreatePostModal.svelte";
  import InvestModal from "../../components/general/InvestModal.svelte";

  // Data state
  let portfolioValue = 0;
  let activeMarketsCount = 0;
  let shareholdersCount = 0;
  let feedItems: any[] = [];
  let trendingUsers: any[] = [];

  let marketStats: { count: number; volume: number; chart_data: any[] } | null = null;

  // New unique feature state
  let sentimentRatio = 50; // 50% bullish
  let dailyRewardClaimed = false;
  let suggestedUsers: any[] = [];

  let loading = true;
  let showPostModal = false;
  let showInvestModal = false;
  let selectedUser: any = null;
  let postCreatedTrigger = 0; // Trigger to force re-render/fetch

  // For the inline post input
  export let onNavigate: (path: string) => void = (path) => {
      window.history.pushState({}, "", path);
      window.dispatchEvent(new PopStateEvent('popstate'));
  };

  let postInputContent = "";

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

        // Global Data

        // 3. Fetch Market Stats (RPC)
        const { data: stats, error: statsError } = await supabase.rpc("get_daily_investment_stats");
        if (!statsError && stats) {
            marketStats = stats;
        } else {
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

        // 4. Fetch Feed (Posts ONLY)
        let posts: any[] = [];
        const { data: postsData, error: postsError } = await supabase
            .from('posts')
            .select(`
                id,
                created_at,
                content,
                likes_count,
                user:profiles!user_id(username, avatar_url, full_name)
            `)
            .order('created_at', { ascending: false })
            .limit(20);

        if (!postsError && postsData && postsData.length > 0) {
            posts = postsData.map((p: any) => ({ ...p, type: 'post' }));
        }

        // Set feed items directly to posts, no investments
        feedItems = posts;

        // 5. Fetch Suggested Users (Unique to Home)
        suggestedUsers = [
            { username: "new_star", full_name: "Rising Star", avatar_url: "" },
            { username: "quant_fund", full_name: "Quant Fund", avatar_url: "" },
            { username: "social_cap", full_name: "Social Capital", avatar_url: "" }
        ];

        // 6. Calculate Sentiment (Mock logic based on volume for now)
        if (marketStats) {
            sentimentRatio = 55 + Math.floor(Math.random() * 20) - 10;
        }

    } catch (e) {
        console.error("Error fetching dashboard data:", e);
    } finally {
        loading = false;
    }
  }

  // Format helpers
  const formatCurrency = (val: number) => val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const formatTime = (iso: string) => {
      const date = new Date(iso);
      const now = new Date();
      const diffMins = Math.floor((now.getTime() - date.getTime()) / 60000);
      if (diffMins < 60) return `${diffMins}m`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h`;
      return date.toLocaleDateString();
  };

  // Mock price change for feed users (since we don't have it in the posts query yet)
  function getMockPriceChange() {
      const change = (Math.random() * 10) - 4; // -4% to +6%
      return change;
  }

  function openPostModal() {
      showPostModal = true;
  }

  function handlePostCreated() {
    showPostModal = false;
    postCreatedTrigger++;
    fetchData(); // Reload data
  }

  function claimReward() {
      if (dailyRewardClaimed) return;
      dailyRewardClaimed = true;
      // In real app, call RPC to add tokens

      const toast = document.createElement('div');
      toast.className = 'reward-toast';
      toast.innerText = '+50 Tokens Reclamados!';
      document.body.appendChild(toast);
      setTimeout(() => toast.remove(), 3000);
  }

  onMount(() => {
      fetchData();
      window.addEventListener('post-created', fetchData);
      return () => window.removeEventListener('post-created', fetchData);
  });
</script>

<div class="home-container">

  <!-- Left Sidebar (Desktop Only) -->
  <div class="left-sidebar">
      {#if $userProfile}
          <div class="mini-profile-card">
              <div class="mini-profile-bg"></div>
              <div class="mini-profile-content">
                  <img src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`} alt="" class="mini-avatar"/>
                  <div class="mini-names">
                      <span class="mini-fullname">{$userProfile.full_name}</span>
                      <span class="mini-username">@{$userProfile.username}</span>
                  </div>
                  <div class="mini-stats-row">
                      <div class="mini-stat">
                          <span class="val">{activeMarketsCount}</span>
                          <span class="lbl">Mercados</span>
                      </div>
                      <div class="mini-stat">
                          <span class="val">{shareholdersCount}</span>
                          <span class="lbl">Accionistas</span>
                      </div>
                  </div>
              </div>
          </div>
      {/if}
  </div>

  <!-- Main Feed Column -->
  <div class="feed-column">
      <!-- Dashboard Header (Mobile/Desktop Unified for "Intuitive" feel) -->
      <div class="dashboard-header">
          <div class="dh-item">
              <span class="dh-label">Portafolio</span>
              <span class="dh-value">{formatCurrency(portfolioValue)} <span class="currency">TKN</span></span>
          </div>
          <div class="dh-divider"></div>
          <div class="dh-item">
               <span class="dh-label">Mercado</span>
               <div class="dh-sentiment">
                   <span class="{sentimentRatio > 50 ? 'positive' : 'negative'}">
                       {sentimentRatio > 50 ? 'Alcista' : 'Bajista'}
                   </span>
                   <Activity size={14} class={sentimentRatio > 50 ? 'positive-icon' : 'negative-icon'} />
               </div>
          </div>
      </div>

      <!-- Create Post Box -->
      <div class="compose-box">
          <div class="compose-avatar">
              {#if $userProfile}
                <img src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`} alt=""/>
              {:else}
                <div class="placeholder-avatar"></div>
              {/if}
          </div>
          <div
            class="compose-input-wrapper"
            on:click={openPostModal}
            on:keydown={(e) => (e.key === 'Enter' || e.key === ' ') && openPostModal()}
            role="button"
            tabindex="0"
          >
              <input type="text" placeholder="¿Qué estás pensando sobre el mercado?" readonly />
              <div class="compose-actions">
                  <ImageIcon size={20} color="var(--primary-color)" />
                  <BarChart2 size={20} color="var(--primary-color)" transform="rotate(90)"/>
                  <Smile size={20} color="var(--primary-color)" />
              </div>
          </div>
      </div>

      <!-- Mobile Unique Features (Visible only on <768px) -->
      <div class="mobile-unique-features">
          <!-- Daily Reward (Mobile) -->
          <div class="mobile-feature-card">
             <div class="m-reward-header">
                 <Gift size={24} color="#F59E0B" />
                 <span class="m-title">Recompensa Diaria</span>
             </div>
             <button class="m-claim-btn {dailyRewardClaimed ? 'claimed' : ''}" on:click={claimReward}>
                 {dailyRewardClaimed ? '¡Reclamado!' : 'Reclamar 50 Tokens'}
             </button>
          </div>
      </div>

      <!-- Feed -->
      <div class="feed-list">
          {#if loading}
              <div class="feed-skeleton">
                  {#each Array(3) as _}
                      <div class="skeleton-item">
                          <div class="skeleton-avatar"></div>
                          <div class="skeleton-content">
                              <div class="skeleton-line short"></div>
                              <div class="skeleton-line long"></div>
                              <div class="skeleton-line medium"></div>
                          </div>
                      </div>
                  {/each}
              </div>
          {:else if feedItems.length === 0}
              <div class="empty-feed">
                  <div class="empty-icon">
                      <MessageCircle size={48} color="var(--text-secondary)" />
                  </div>
                  <h3>No hay actividad reciente</h3>
                  <p>¡Sé el primero en publicar algo para iniciar la conversación!</p>
                  <button class="create-first-post-btn" on:click={openPostModal}>Crear Publicación</button>
              </div>
          {:else}
              {#each feedItems as item}
                  <!-- Only render posts -->
                  <div
                    class="feed-item post"
                    on:click={() => onNavigate(`/post/details?id=${item.id}`)}
                    on:keydown={(e) => e.key === 'Enter' && onNavigate(`/post/details?id=${item.id}`)}
                    role="button"
                    tabindex="0"
                  >
                      <div class="item-avatar">
                          <img src={item.user?.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${item.user?.username || 'unknown'}`} alt="avatar"/>
                      </div>
                      <div class="item-content">
                          <div class="item-header">
                              <div class="header-left">
                                  <span class="name">{item.user?.full_name || 'Usuario desconocido'}</span>
                                  <span class="handle">@{item.user?.username || 'unknown'}</span>
                                  <span class="dot">·</span>
                                  <span class="time">{formatTime(item.created_at)}</span>
                              </div>
                              <!-- Visual cue for trading context -->
                              {#if item.user}
                                  <div class="price-badge {Math.random() > 0.5 ? 'positive' : 'negative'}">
                                      {#if Math.random() > 0.5}
                                          <TrendingUp size={12} />
                                      {:else}
                                          <TrendingDown size={12} />
                                      {/if}
                                      <span>${(50 + Math.random()*10).toFixed(0)}</span>
                                  </div>
                              {/if}
                          </div>
                          <div class="post-text">{item.content}</div>
                          <div class="post-actions">
                              <button class="action-btn" aria-label="Comment" on:click|stopPropagation={() => {}}><MessageCircle size={18} /> <span>{item.replies_count || 0}</span></button>
                              <button class="action-btn" aria-label="Share" on:click|stopPropagation={() => {}}><Share2 size={18} /></button>
                              <button class="action-btn" aria-label="Like" on:click|stopPropagation={() => {}}><Heart size={18} /> <span>{item.likes_count}</span></button>
                              <button class="invest-btn-small" on:click|stopPropagation={() => { selectedUser = item.user; showInvestModal = true; }}>
                                  Invertir
                              </button>
                          </div>
                      </div>
                  </div>
              {/each}
          {/if}
      </div>
  </div>

  <!-- Right Sidebar (Desktop) -->
  <div class="right-sidebar">
      <!-- Market Sentiment (Unique) -->
      <div class="sidebar-card">
          <h3>Sentimiento del Mercado</h3>
          <div class="sentiment-container">
              <div class="sentiment-bar">
                  <div class="bar-fill buy" style="width: {sentimentRatio}%"></div>
                  <div class="bar-fill sell" style="width: {100 - sentimentRatio}%"></div>
              </div>
              <div class="sentiment-labels">
                  <span class="s-label buy"><ThumbsUp size={14} /> {sentimentRatio}% Compra</span>
                  <span class="s-label sell"><ThumbsDown size={14} /> {100 - sentimentRatio}% Venta</span>
              </div>
          </div>
      </div>

      <!-- Daily Reward (Unique) -->
      <div class="sidebar-card reward-card">
          <h3>Recompensa Diaria</h3>
          <div class="reward-content">
              <div class="reward-icon">
                  <Gift size={32} color="#F59E0B" />
              </div>
              <div class="reward-info">
                  <span class="r-title">¡Reclama tus tokens!</span>
                  <span class="r-desc">Vuelve cada día para ganar más.</span>
              </div>
          </div>
          <button class="claim-btn {dailyRewardClaimed ? 'claimed' : ''}" on:click={claimReward}>
              {dailyRewardClaimed ? '¡Reclamado!' : 'Reclamar 50 Tokens'}
          </button>
      </div>

      <!-- Who to Follow (Unique) -->
      <div class="sidebar-card">
          <h3>A quién seguir</h3>
          <div class="suggested-list">
              {#each suggestedUsers as user}
                  <div class="suggested-item">
                      <img src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`} alt="" class="s-avatar"/>
                      <div class="s-info">
                          <span class="s-name">{user.full_name}</span>
                          <span class="s-handle">@{user.username}</span>
                      </div>
                      <button class="follow-btn"><UserPlus size={16} /></button>
                  </div>
              {/each}
          </div>
      </div>

      <!-- My Stats (Desktop overlap) -->
      {#if $userProfile}
      <div class="sidebar-card stats-mini">
          <h3>Mi Portafolio</h3>
          <div class="p-row">
              <span>Valor</span>
              <span class="highlight">{formatCurrency(portfolioValue)}</span>
          </div>
          <div class="p-row">
              <span>Balance</span>
              <span>{($userProfile.tokens || 0).toLocaleString()}</span>
          </div>
      </div>
      {/if}
  </div>

</div>

{#if showPostModal}
  <CreatePostModal onClose={() => showPostModal = false} />
{/if}

{#if showInvestModal && selectedUser}
  <InvestModal targetUser={selectedUser} onClose={() => showInvestModal = false} />
{/if}

<style>
  :global(.reward-toast) {
      position: fixed;
      bottom: 80px;
      left: 50%;
      transform: translateX(-50%);
      background: var(--success-color);
      color: white;
      padding: 12px 24px;
      border-radius: 99px;
      font-weight: 700;
      box-shadow: 0 4px 12px rgba(0,0,0,0.2);
      z-index: 2000;
      animation: fadeInOut 3s ease-in-out;
  }
  @keyframes fadeInOut {
      0% { opacity: 0; transform: translate(-50%, 20px); }
      10% { opacity: 1; transform: translate(-50%, 0); }
      90% { opacity: 1; transform: translate(-50%, 0); }
      100% { opacity: 0; transform: translate(-50%, -20px); }
  }

  .home-container {
      display: grid;
      grid-template-columns: 240px 1fr 300px;
      gap: 24px;
      max-width: 1200px;
      margin: 0 auto;
      padding-top: 20px;
      align-items: start;
  }

  @media (max-width: 1000px) {
      .home-container {
          grid-template-columns: 1fr 300px;
      }
      .left-sidebar {
          display: none;
      }
  }

  @media (max-width: 768px) {
      .home-container {
          grid-template-columns: 1fr;
      }
      .right-sidebar {
          display: none;
      }
  }

  /* Left Sidebar */
  .mini-profile-card {
      background: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      overflow: hidden;
      text-align: center;
  }

  .mini-profile-bg {
      height: 60px;
      background-color: var(--bg-tertiary);
  }

  .mini-profile-content {
      padding: 0 16px 16px;
      margin-top: -30px;
  }

  .mini-avatar {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      border: 4px solid var(--bg-main);
      background-color: var(--bg-main);
  }

  .mini-names {
      margin-top: 8px;
  }

  .mini-fullname {
      display: block;
      font-weight: 700;
      color: var(--text-main);
  }

  .mini-username {
      display: block;
      color: var(--text-secondary);
      font-size: 14px;
  }

  .mini-stats-row {
      display: flex;
      justify-content: space-around;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--border-color);
  }

  .mini-stat {
      display: flex;
      flex-direction: column;
  }

  .mini-stat .val {
      font-weight: 700;
      color: var(--text-main);
  }

  .mini-stat .lbl {
      font-size: 12px;
      color: var(--text-secondary);
  }

  /* Feed Column */
  .feed-column {
      border: 1px solid var(--border-color);
      border-radius: 16px;
      background: var(--bg-main);
      min-height: 80vh;
  }

  .compose-box {
      display: flex;
      gap: 12px;
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
  }

  .compose-avatar img, .placeholder-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
  }

  .compose-input-wrapper {
      flex-grow: 1;
      display: flex;
      flex-direction: column;
      gap: 12px;
  }

  .compose-input-wrapper input {
      border: none;
      background: none;
      font-size: 18px;
      outline: none;
      color: var(--text-main);
      cursor: text;
  }

  .compose-actions {
      display: flex;
      gap: 16px;
      padding-top: 8px;
      border-top: 1px solid transparent;
  }

  /* Mobile Unique Features */
  .mobile-unique-features {
      display: none; /* hidden by default */
  }

  @media (max-width: 768px) {
      .mobile-unique-features {
          display: flex;
          flex-direction: column;
          gap: 12px;
          padding: 16px;
          border-bottom: 1px solid var(--border-color);
          background: var(--bg-hover);
      }
  }

  .mobile-feature-card {
      background: var(--bg-main);
      border-radius: 12px;
      padding: 12px;
      border: 1px solid var(--border-color);
      display: flex;
      flex-direction: column;
      gap: 8px;
  }

  .m-reward-header {
      display: flex;
      align-items: center;
      gap: 8px;
  }

  .m-title {
      font-weight: 700;
      font-size: 14px;
  }

  .m-claim-btn {
      background-color: var(--primary-color);
      color: white;
      border: none;
      padding: 8px;
      border-radius: 8px;
      font-weight: 700;
      font-size: 13px;
      width: 100%;
  }

  .m-claim-btn.claimed {
      background-color: var(--bg-tertiary);
      color: var(--text-secondary);
  }

  .feed-list {
      display: flex;
      flex-direction: column;
  }

  .feed-item {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      gap: 12px;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .feed-item:hover {
      background-color: var(--bg-hover);
  }

  .item-avatar img {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      object-fit: cover;
  }

  .item-content {
      flex-grow: 1;
  }

  .item-header {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 15px;
      margin-bottom: 4px;
  }

  .item-header .name { font-weight: 700; color: var(--text-main); }
  .item-header .handle { color: var(--text-secondary); }
  .item-header .dot { color: var(--text-secondary); }
  .item-header .time { color: var(--text-secondary); }

  .post-text {
      font-size: 15px;
      color: var(--text-main);
      line-height: 1.4;
      white-space: pre-wrap;
  }

  .post-actions {
      display: flex;
      justify-content: space-between;
      max-width: 300px;
      margin-top: 12px;
  }

  .action-btn {
      display: flex;
      align-items: center;
      gap: 6px;
      background: none;
      border: none;
      color: var(--text-secondary);
      font-size: 13px;
      cursor: pointer;
      transition: color 0.2s;
  }

  .action-btn:hover { color: var(--primary-color); }

  .empty-feed {
      padding: 60px 20px;
      text-align: center;
      color: var(--text-secondary);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 20px;
      background: var(--bg-main);
  }

  .empty-icon {
      width: 80px;
      height: 80px;
      background: var(--bg-tertiary);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 8px;
  }

  .empty-feed h3 {
      font-size: 20px;
      font-weight: 700;
      color: var(--text-main);
      margin: 0;
  }

  .empty-feed p {
      font-size: 15px;
      max-width: 300px;
      margin: 0 auto;
  }

  /* Right Sidebar */
  .right-sidebar {
      display: flex;
      flex-direction: column;
      gap: 16px;
  }

  .sidebar-card {
      background: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 16px;
  }

  .sidebar-card h3 {
      font-size: 18px;
      font-weight: 800;
      margin-bottom: 12px;
  }

  /* Market Sentiment */
  .sentiment-container {
      margin-top: 8px;
  }

  .sentiment-bar {
      height: 8px;
      border-radius: 99px;
      background-color: var(--bg-tertiary);
      display: flex;
      overflow: hidden;
      margin-bottom: 8px;
  }

  .bar-fill.buy { background-color: var(--success-color); }
  .bar-fill.sell { background-color: var(--danger-color); }

  .sentiment-labels {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      font-weight: 600;
  }

  .s-label { display: flex; align-items: center; gap: 4px; }
  .s-label.buy { color: var(--success-color); }
  .s-label.sell { color: var(--danger-color); }

  /* Daily Reward */
  .reward-content {
      display: flex;
      gap: 12px;
      align-items: center;
      margin-bottom: 12px;
  }

  .reward-icon {
      width: 48px;
      height: 48px;
      background-color: rgba(245, 158, 11, 0.1);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
  }

  .reward-info {
      display: flex;
      flex-direction: column;
  }

  .r-title { font-weight: 700; font-size: 15px; }
  .r-desc { font-size: 13px; color: var(--text-secondary); }

  .claim-btn {
      width: 100%;
      padding: 10px;
      background-color: var(--primary-color);
      color: white;
      border: none;
      border-radius: 99px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
  }

  .claim-btn:hover { opacity: 0.9; }
  .claim-btn.claimed {
      background-color: var(--bg-tertiary);
      color: var(--text-secondary);
      cursor: default;
  }

  /* Suggested Users */
  .suggested-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
  }

  .suggested-item {
      display: flex;
      align-items: center;
      gap: 10px;
  }

  .s-avatar {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
  }

  .s-info {
      flex: 1;
      display: flex;
      flex-direction: column;
  }

  .s-name { font-weight: 700; font-size: 14px; }
  .s-handle { font-size: 12px; color: var(--text-secondary); }

  .follow-btn {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
      border: none;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .follow-btn:hover {
      background-color: var(--bg-hover);
      color: var(--primary-color);
  }

  .p-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
      font-size: 14px;
  }

  .highlight { color: var(--primary-color); font-weight: 700; }

  /* Skeleton Loading */
  .feed-skeleton {
      display: flex;
      flex-direction: column;
  }

  .skeleton-item {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      gap: 12px;
  }

  .skeleton-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: var(--bg-tertiary);
      animation: shimmer 1.5s infinite linear;
  }

  .skeleton-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 8px;
  }

  .skeleton-line {
      height: 12px;
      background: var(--bg-tertiary);
      border-radius: 6px;
      animation: shimmer 1.5s infinite linear;
  }

  .skeleton-line.short { width: 30%; }
  .skeleton-line.long { width: 90%; }
  .skeleton-line.medium { width: 60%; }

  @keyframes shimmer {
      0% { opacity: 0.5; }
      50% { opacity: 1; }
      100% { opacity: 0.5; }
  }

  .create-first-post-btn {
      margin-top: 8px;
      background-color: var(--primary-color);
      color: white;
      border: none;
      border-radius: 99px;
      padding: 10px 24px;
      font-weight: 700;
      cursor: pointer;
      transition: opacity 0.2s;
  }

  .create-first-post-btn:hover {
      opacity: 0.9;
  }

  /* Dashboard Header */
  .dashboard-header {
      display: flex;
      align-items: center;
      justify-content: space-around;
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
      background: var(--bg-secondary);
  }

  .dh-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
  }

  .dh-label {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
      text-transform: uppercase;
  }

  .dh-value {
      font-size: 18px;
      font-weight: 800;
      color: var(--text-main);
  }

  .dh-value .currency {
      font-size: 12px;
      color: var(--text-secondary);
      font-weight: 600;
  }

  .dh-divider {
      width: 1px;
      height: 32px;
      background-color: var(--border-color);
  }

  .dh-sentiment {
      display: flex;
      align-items: center;
      gap: 6px;
      font-weight: 700;
      font-size: 16px;
  }

  .positive { color: var(--success-color); }
  .negative { color: var(--danger-color); }
  :global(.positive-icon) { color: var(--success-color); }
  :global(.negative-icon) { color: var(--danger-color); }

  .header-left {
      display: flex;
      align-items: center;
      gap: 4px;
      flex-wrap: wrap;
  }

  .price-badge {
      display: flex;
      align-items: center;
      gap: 2px;
      font-size: 12px;
      font-weight: 700;
      padding: 2px 6px;
      border-radius: 4px;
      margin-left: auto;
  }

  .price-badge.positive {
      color: var(--success-color);
      background-color: rgba(16, 185, 129, 0.1);
  }

  .price-badge.negative {
      color: var(--danger-color);
      background-color: rgba(239, 68, 68, 0.1);
  }

  .invest-btn-small {
      margin-left: auto;
      background-color: transparent;
      border: 1px solid var(--primary-color);
      color: var(--primary-color);
      padding: 4px 12px;
      border-radius: 99px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
  }

  .invest-btn-small:hover {
      background-color: rgba(29, 155, 240, 0.1);
  }
</style>
