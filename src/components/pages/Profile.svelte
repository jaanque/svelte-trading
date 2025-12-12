<script lang="ts">
  import { onMount } from "svelte";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, Calendar, Link as LinkIcon, MapPin, ArrowLeft, MoreHorizontal, MessageSquare, LogOut, Share2, TrendingUp, Users, Heart, MessageCircle, Camera } from "lucide-svelte";
  import InvestModal from "../../components/general/InvestModal.svelte";
  import SellModal from "../../components/general/SellModal.svelte";
  import PriceChart from "../../components/general/PriceChart.svelte";

  export let currentPath = "";

  let loading = true;
  let profileData: any = null;
  let error: string | null = null;
  let isOwnProfile = false;
  let urlUsername: string | null = null;
  let showInvestModal = false;
  let showSellModal = false;
  let showMoreMenu = false;
  let userShares = 0;
  let shareholdersCount = 0;
  let postsCount = 0;
  let profilePosts: any[] = [];
  let loadingPosts = false;
  let fileInput: HTMLInputElement;
  let uploading = false;

  let activeTab = "Chart";
  const tabs = ["Chart", "Posts", "Replies", "Media", "Likes"];

  // Helpers
  function getQueryParam(param: string) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
  }

  function formatNumber(num: number | undefined | null) {
      if (num === undefined || num === null) return "0";
      return num.toLocaleString();
  }

  function formatPrice(num: number | undefined | null) {
      if (num === undefined || num === null) return "0";
      return num.toLocaleString(undefined, { maximumFractionDigits: 0 });
  }

  function formatTime(iso: string) {
      const date = new Date(iso);
      const now = new Date();
      const diffMins = Math.floor((now.getTime() - date.getTime()) / 60000);
      if (diffMins < 60) return `${diffMins}m`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h`;
      return date.toLocaleDateString();
  }

  async function loadProfile() {
    loading = true;
    error = null;
    profileData = null;
    userShares = 0;

    urlUsername = getQueryParam("u");

    if (urlUsername) {
      try {
        const { data, error: err } = await supabase
          .from("profiles")
          .select("*")
          .eq("username", urlUsername)
          .single();

        if (err) throw err;
        profileData = data;

        if ($userProfile && $userProfile.username === urlUsername) {
            isOwnProfile = true;
        } else {
            isOwnProfile = false;
        }

      } catch (err) {
        console.error("Error fetching profile:", err);
        error = "User not found";
      }
    } else {
      if ($userSession) {
        isOwnProfile = true;
        profileData = $userProfile;
      } else {
        isOwnProfile = false;
        profileData = null;
      }
    }
    // Fetch holdings if not own profile
    if (!isOwnProfile && profileData && $userProfile) {
        const { data: investments, error: invError } = await supabase
            .from("investments")
            .select("amount_shares")
            .eq("investor_id", $userProfile.id)
            .eq("target_user_id", profileData.id);

        if (!invError && investments) {
            userShares = investments.reduce((acc, curr) => acc + parseFloat(curr.amount_shares), 0);
        }
    }

    // Fetch shareholders count
    if (profileData) {
        const { data: allInvestments, error: countError } = await supabase
             .from("investments")
             .select("investor_id, amount_shares")
             .eq("target_user_id", profileData.id);

        if (!countError && allInvestments) {
            const holdingsMap = new Map();
            allInvestments.forEach((inv: any) => {
                const current = holdingsMap.get(inv.investor_id) || 0;
                holdingsMap.set(inv.investor_id, current + parseFloat(inv.amount_shares));
            });

            let count = 0;
            holdingsMap.forEach((shares) => {
                if (shares > 0.0001) count++;
            });
            shareholdersCount = count;
        }

        // Fetch Posts Count
        const { count, error: countPostsError } = await supabase
            .from('posts')
            .select('*', { count: 'exact', head: true })
            .eq('user_id', profileData.id);

        if (!countPostsError) {
            postsCount = count || 0;
        }

        // Load posts initially
        loadUserPosts();
    }

    loading = false;
  }

  async function loadUserPosts() {
      if (!profileData) return;
      loadingPosts = true;
      const { data, error } = await supabase
          .from('posts')
          .select('*')
          .eq('user_id', profileData.id)
          .order('created_at', { ascending: false });

      if (!error && data) {
          profilePosts = data;
      }
      loadingPosts = false;
  }

  function setActiveTab(tab: string) {
      activeTab = tab;
      if (tab === 'Posts') {
          loadUserPosts();
      }
  }

  async function uploadAvatar(event: Event) {
      const target = event.target as HTMLInputElement;
      if (!target.files || target.files.length === 0) return;

      const file = target.files[0];
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `${profileData.id}/${fileName}`;

      uploading = true;
      try {
          const { error: uploadError } = await supabase.storage
              .from('avatars')
              .upload(filePath, file);

          if (uploadError) throw uploadError;

          const { data } = supabase.storage.from('avatars').getPublicUrl(filePath);

          const { error: updateError } = await supabase
              .from('profiles')
              .update({ avatar_url: data.publicUrl })
              .eq('id', profileData.id);

          if (updateError) throw updateError;

          // Update local state and auth store
          profileData.avatar_url = data.publicUrl;
          if ($userProfile) {
              userProfile.set({ ...$userProfile, avatar_url: data.publicUrl });
          }
      } catch (err) {
          console.error('Error uploading avatar:', err);
          alert('Error uploading avatar');
      } finally {
          uploading = false;
      }
  }

  function triggerFileInput() {
      if (isOwnProfile) {
          fileInput.click();
      }
  }

  async function handleLogout() {
      await supabase.auth.signOut();
      window.location.href = '/login';
  }

  function toggleMoreMenu(e: Event) {
      e.stopPropagation();
      showMoreMenu = !showMoreMenu;
  }

  function handleShare() {
      if (navigator.share) {
          navigator.share({
              title: profileData.full_name,
              text: `Check out ${profileData.full_name} ($${profileData.username.toUpperCase()}) on Pulse`,
              url: window.location.href
          }).catch(console.error);
      } else {
          // Fallback
          navigator.clipboard.writeText(window.location.href);
          alert("Link copied to clipboard!");
      }
  }

  onMount(() => {
    loadProfile();
    const closeMenu = () => showMoreMenu = false;
    window.addEventListener('click', closeMenu);
    const handlePopState = () => { loadProfile(); };
    window.addEventListener('popstate', handlePopState);

    return () => {
        window.removeEventListener('click', closeMenu);
        window.removeEventListener('popstate', handlePopState);
    };
  });

  $: $userSession, $userProfile, currentPath, loadProfile();
</script>

<div class="profile-page">
  {#if loading}
    <div class="center-content">
      <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
    </div>

  {:else if error}
    <div class="center-content">
      <div class="error-container">
        <h2>User not found</h2>
        <p>The profile you are looking for does not exist.</p>
        <a href="/" class="btn-secondary">Go Home</a>
      </div>
    </div>

  {:else if profileData}
    <!-- Sticky Header -->
    <div class="sticky-header">
       <div class="header-content">
         {#if !isOwnProfile && urlUsername}
             <a href="/" class="back-btn"><ArrowLeft size={20} /></a>
         {/if}
         <div class="header-name">
            <h3>{profileData.full_name || profileData.username}</h3>
            <span class="post-count">{postsCount} posts</span>
         </div>
       </div>
    </div>

    <!-- Banner - Full Width -->
    <div class="banner">
      <!-- Could add image support here -->
    </div>

    <!-- Profile Content Container (Centered) -->
    <div class="profile-content-wrapper">
      <div class="profile-info-container">
        <div class="top-row">
           <div class="avatar-wrapper">
             <img
              src={profileData.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${profileData.username}`}
              alt={profileData.username}
              class="profile-avatar"
              on:click={triggerFileInput}
              on:keydown={(e) => e.key === 'Enter' && triggerFileInput()}
              role={isOwnProfile ? "button" : undefined}
              tabindex={isOwnProfile ? 0 : -1}
              style={isOwnProfile ? "cursor: pointer;" : ""}
            />
            {#if isOwnProfile}
                <div
                    class="avatar-overlay"
                    on:click={triggerFileInput}
                    on:keydown={(e) => e.key === 'Enter' && triggerFileInput()}
                    role="button"
                    tabindex="0"
                >
                    {#if uploading}
                        <Loader2 class="animate-spin" size={24} color="white" />
                    {:else}
                        <Camera size={24} color="white" />
                    {/if}
                </div>
                <input
                    type="file"
                    accept="image/*"
                    bind:this={fileInput}
                    on:change={uploadAvatar}
                    style="display: none;"
                />
            {/if}
           </div>

           <div class="actions">
            {#if isOwnProfile}
              <button class="btn-icon" on:click={handleShare} aria-label="Share"><Share2 size={18} /></button>
              <a href="/settings" class="btn-edit">Edit Profile</a>
              <div class="more-menu-container">
                  <button class="btn-icon" on:click={toggleMoreMenu}><MoreHorizontal size={20} /></button>
                  {#if showMoreMenu}
                      <div class="dropdown-menu">
                          <button class="menu-item logout" on:click={handleLogout}>
                              <LogOut size={16} />
                              <span>Log out</span>
                          </button>
                      </div>
                  {/if}
              </div>
            {:else}
              <div class="more-menu-container">
                  <button class="btn-icon" on:click={toggleMoreMenu}><MoreHorizontal size={20} /></button>
                  {#if showMoreMenu}
                       <div class="dropdown-menu">
                          <button class="menu-item" on:click={handleShare}>
                              <Share2 size={16} />
                              <span>Share</span>
                          </button>
                      </div>
                  {/if}
              </div>
              <a href={`/messages?u=${profileData.username}`} class="btn-icon" aria-label="Message"><MessageSquare size={20} /></a>
              {#if userShares > 0}
                  <button
                    class="btn-secondary-action"
                    on:click={() => showSellModal = true}
                  >
                    Vender
                  </button>
                  <button
                    class="btn-primary"
                    on:click={() => showInvestModal = true}
                  >
                    Invertir más
                  </button>
              {:else}
                  <button
                    class="btn-primary"
                    on:click={() => showInvestModal = true}
                  >
                    Invertir
                  </button>
              {/if}
            {/if}
          </div>
        </div>

        <div class="info">
          <h1 class="fullname">{profileData.full_name || profileData.username}</h1>
          <div class="handle">${profileData.username.toUpperCase()}</div>

          {#if profileData.bio}
            <p class="bio">{profileData.bio}</p>
          {/if}

          <div class="meta">
             <div class="meta-item">
                <Calendar size={16} />
                <span>Joined recently</span>
             </div>
             {#if profileData.website}
               <div class="meta-item">
                 <LinkIcon size={16} />
                 <a href={profileData.website} target="_blank" rel="noopener noreferrer">{profileData.website}</a>
               </div>
             {/if}
          </div>

          <!-- Social Stats -->
          <div class="stats-row social">
             <div class="stat-item">
               <span class="stat-value">{postsCount}</span>
               <span class="stat-label">Posts</span>
             </div>
             <div class="stat-item">
               <span class="stat-value">{formatNumber(shareholdersCount)}</span>
               <span class="stat-label">Accionistas</span>
             </div>
          </div>

          <!-- Financial Stats Card -->
          <div class="financial-card">
              <div class="fin-stat">
                  <div class="label"><TrendingUp size={14} /> Price</div>
                  <div class="value highlight">{formatPrice(profileData.price || 50)}</div>
              </div>
              <div class="divider"></div>
              <div class="fin-stat">
                  <div class="label"><Users size={14} /> Outstanding</div>
                  <div class="value">{formatNumber(profileData.shares || 1000000)}</div>
              </div>
              <div class="divider"></div>
              <div class="fin-stat">
                  <div class="label">Available</div>
                  <div class="value">{formatNumber(Math.floor(profileData.available_shares || 0))}</div>
              </div>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="profile-tabs">
         {#each tabs as tab}
             <div
                class="tab {activeTab === tab ? 'active' : ''}"
                on:click={() => setActiveTab(tab)}
                on:keydown={() => setActiveTab(tab)}
                role="button"
                tabindex="0"
             >
                {tab}
             </div>
         {/each}
      </div>

      <!-- Feed Content -->
      <div class="feed-content">
         {#if activeTab === "Posts"}
             {#if loadingPosts}
                 <div class="center-content">
                     <Loader2 class="animate-spin" size={24} color="var(--primary-color)" />
                 </div>
             {:else if profilePosts.length === 0}
                 <div class="empty-feed">
                    <div class="empty-icon-circle">
                        <MessageSquare size={32} />
                    </div>
                    <h3>No posts yet</h3>
                    <p>${profileData.username.toUpperCase()} hasn't posted anything yet. When they do, it will show up here.</p>
                 </div>
             {:else}
                 {#each profilePosts as post}
                     <div class="feed-item">
                         <div class="item-avatar">
                             <img src={profileData.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${profileData.username}`} alt="" />
                         </div>
                         <div class="item-content">
                             <div class="item-header">
                                  <span class="name">{profileData.full_name}</span>
                                  <span class="handle">@{profileData.username}</span>
                                  <span class="dot">·</span>
                                  <span class="time">{formatTime(post.created_at)}</span>
                              </div>
                              <div class="post-text">{post.content}</div>
                              <div class="post-actions">
                                  <button class="action-btn"><MessageCircle size={18} /> <span>0</span></button>
                                  <button class="action-btn"><Share2 size={18} /></button>
                                  <button class="action-btn"><Heart size={18} /> <span>{post.likes_count}</span></button>
                              </div>
                         </div>
                     </div>
                 {/each}
             {/if}
         {:else if activeTab === "Chart"}
             <div class="chart-tab-content">
                 <PriceChart
                    userId={profileData.id}
                    currentPrice={profileData.price || 50}
                 />
             </div>
         {:else}
             <div class="empty-feed">
                <p>No {activeTab.toLowerCase()} yet.</p>
             </div>
         {/if}
      </div>
    </div>

  {:else if !$userSession && !urlUsername}
    <div class="cta-container">
      <div class="cta-card">
         <h2>Join to see your profile</h2>
         <p>Sign up now to create your own profile, follow others, and start trading.</p>
         <div class="cta-actions">
           <a href="/login" class="btn-primary">Log in</a>
           <a href="/register" class="btn-secondary">Sign up</a>
         </div>
      </div>
    </div>
  {:else}
     <!-- Logged in but profile data loading or not found yet (and not in loading state) - likely waiting for profile store -->
     <div class="center-content">
        <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
     </div>
  {/if}

  {#if showInvestModal}
    <InvestModal
        targetUser={profileData}
        onClose={() => showInvestModal = false}
        on:success={loadProfile}
    />
  {/if}

  {#if showSellModal}
    <SellModal
        targetUser={profileData}
        userShares={userShares}
        onClose={() => showSellModal = false}
        on:success={loadProfile}
    />
  {/if}
</div>

<style>
  .profile-page {
    width: 100%;
    min-height: 100vh;
    background-color: var(--bg-main);
    display: flex;
    flex-direction: column;
  }

  .center-content {
    display: flex;
    justify-content: center;
    align-items: center;
    flex-grow: 1;
    min-height: 50vh;
  }

  /* Sticky Header */
  .sticky-header {
      position: sticky;
      top: 0;
      background: rgba(255, 255, 255, 0.85); /* Use var? var(--bg-main) might be opaque */
      /* Ideally use var(--bg-main) with opacity, but hex is easier for alpha */
      backdrop-filter: blur(12px);
      z-index: 100; /* Higher than banner */
      height: 53px;
      display: flex;
      align-items: center;
      border-bottom: 1px solid var(--border-color);
      width: 100%;
  }

  .header-content {
      width: 100%;
      /* Removed max-width to allow full width alignment */
      padding: 0 16px;
      display: flex;
      align-items: center;
      gap: 20px;
      box-sizing: border-box;
  }

  .header-name h3 {
      margin: 0;
      font-size: 20px;
      line-height: 24px;
      color: var(--text-main);
  }

  .post-count {
      font-size: 13px;
      color: var(--text-secondary);
      display: block;
  }

  .back-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      border-radius: 50%;
      color: var(--text-main);
      transition: background-color 0.2s;
  }
  .back-btn:hover {
      background-color: var(--bg-tertiary);
  }

  /* Banner */
  .banner {
    height: 200px;
    background-color: var(--bg-tertiary); /* Soft gray/blue */
    background: linear-gradient(to right, #cfd9df 0%, #e2ebf0 100%); /* Subtle gradient */
    width: 100%;
  }

  /* Content Wrapper - Controls width of the actual profile info and feed */
  .profile-content-wrapper {
      width: 100%;
      /* Removed max-width for full width content as requested */
      background-color: var(--bg-main);
      /* Borders removed as they are typically for the central column, but if full width, edges handle it */
      min-height: calc(100vh - 253px); /* approx */
      position: relative;
      top: 0; /* Stacking context */
      box-sizing: border-box;
  }

  /* If on mobile, remove borders */
  @media (max-width: 640px) {
      .profile-content-wrapper {
          border-left: none;
          border-right: none;
      }
  }

  .profile-info-container {
    padding: 12px 16px;
    display: flex;
    flex-direction: column;
    position: relative;
  }

  .top-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-end;
      margin-bottom: 12px;
      height: 45px; /* Space for avatar overlap */
  }

  .avatar-wrapper {
    width: 134px;
    height: 134px;
    border-radius: 50%;
    background-color: var(--bg-main);
    padding: 4px;
    position: absolute;
    top: -67px;
    left: 16px;
    z-index: 10;
  }

  .avatar-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0, 0, 0, 0.4);
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      opacity: 0;
      transition: opacity 0.2s;
      cursor: pointer;
      margin: 4px; /* Match padding */
  }

  .avatar-wrapper:hover .avatar-overlay {
      opacity: 1;
  }

  /* Responsive Avatar */
  @media (max-width: 640px) {
    .banner {
        height: 120px;
    }
    .avatar-wrapper {
        width: 90px;
        height: 90px;
        top: -45px;
    }
    .top-row {
        height: 35px;
    }
  }

  .profile-avatar {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    background-color: var(--bg-tertiary);
    cursor: default; /* Changed from pointer unless logic overrides */
    border: 4px solid var(--bg-main); /* Ensure separation from banner/bg */
    box-sizing: content-box; /* To account for border inside sizing if needed, or just let padding handle it */
    margin: -4px; /* Counter padding */
  }

  .actions {
    margin-left: auto;
    display: flex;
    gap: 8px;
    align-items: center;
  }

  .btn-edit {
    padding: 6px 16px;
    border: 1px solid var(--border-strong);
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    color: var(--text-main);
    background-color: transparent;
    transition: background-color 0.2s;
    text-decoration: none;
  }

  .btn-edit:hover {
    background-color: var(--bg-hover);
  }

  .btn-icon {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      border: 1px solid var(--border-strong);
      background: transparent;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
      transition: background-color 0.2s;
  }
  .btn-icon:hover {
      background-color: var(--bg-hover);
  }

  .more-menu-container {
      position: relative;
  }

  .dropdown-menu {
      position: absolute;
      top: 100%;
      right: 0;
      margin-top: 8px;
      background-color: var(--bg-main);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      box-shadow: var(--shadow-md);
      min-width: 150px;
      z-index: 1000;
      overflow: hidden;
      padding: 4px;
  }

  .menu-item {
      display: flex;
      align-items: center;
      gap: 12px;
      width: 100%;
      padding: 10px 12px;
      border: none;
      background: none;
      text-align: left;
      font-size: 15px;
      font-weight: 500;
      color: var(--text-main);
      cursor: pointer;
      border-radius: 8px;
      transition: background-color 0.2s;
  }

  .menu-item:hover {
      background-color: var(--bg-hover);
  }

  .menu-item.logout {
      color: var(--danger-color, #FF6961);
  }

  .btn-primary {
    padding: 8px 20px;
    background-color: #0f1419; /* Twitter black */
    color: white;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    text-decoration: none;
    transition: opacity 0.2s;
    border: none;
  }
  .btn-primary:hover {
      opacity: 0.9;
  }

  .btn-secondary-action {
    padding: 8px 20px;
    background-color: transparent;
    color: var(--text-main);
    border: 1px solid var(--border-strong);
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  .btn-secondary-action:hover {
      background-color: var(--bg-hover);
  }

  /* Text Info */
  .info {
      margin-top: 4px;
  }

  .fullname {
    font-size: 20px;
    font-weight: 800;
    margin: 0;
    color: var(--text-main);
    line-height: 24px;
  }

  .handle {
    font-size: 15px;
    color: var(--text-secondary);
    margin-bottom: 12px;
  }

  .bio {
    font-size: 15px;
    margin-bottom: 12px;
    white-space: pre-wrap;
    color: var(--text-main);
    line-height: 1.4;
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    gap: 16px; /* More space */
    margin-bottom: 12px;
    color: var(--text-secondary);
    font-size: 15px;
  }

  .meta-item {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  /* Stats Row */
  .stats-row {
    display: flex;
    gap: 20px;
    font-size: 14px;
    margin-top: 8px;
    align-items: center;
  }

  .stat-item {
    color: var(--text-secondary);
    display: flex;
    align-items: center;
    gap: 4px;
    text-decoration: none;
  }

  .stat-value {
    font-weight: 700;
    color: var(--text-main);
  }

  /* Financial Card */
  .financial-card {
      display: flex;
      justify-content: space-around;
      background-color: var(--bg-secondary);
      border-radius: 12px;
      padding: 12px 16px;
      margin-top: 16px;
      margin-bottom: 16px;
      border: 1px solid var(--border-color);
  }

  .fin-stat {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
  }

  .fin-stat .label {
      font-size: 12px;
      color: var(--text-secondary);
      display: flex;
      align-items: center;
      gap: 4px;
      text-transform: uppercase;
      font-weight: 600;
  }

  .fin-stat .value {
      font-size: 16px;
      font-weight: 800;
      color: var(--text-main);
  }

  .fin-stat .value.highlight {
      color: var(--text-main);
  }

  .divider {
      width: 1px;
      background-color: var(--border-color);
  }

  /* Tabs */
  .profile-tabs {
    display: flex;
    border-bottom: 1px solid var(--border-color);
    margin-top: 8px;
    width: 100%;
    overflow-x: auto; /* Handle many tabs on mobile */
  }

  .tab {
    flex: 1;
    min-width: 80px; /* Min width for chart tab */
    text-align: center;
    padding: 16px 0;
    font-weight: 500;
    color: var(--text-secondary);
    cursor: pointer;
    position: relative;
    transition: background-color 0.2s;
    font-size: 15px;
  }

  .tab:hover {
    background-color: var(--bg-hover);
  }

  .tab.active {
    color: var(--text-main);
    font-weight: 700;
  }

  .tab.active::after {
    content: "";
    position: absolute;
    bottom: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 56px;
    height: 4px;
    background-color: var(--primary-color);
    border-radius: 9999px;
  }

  /* Feed */
  .feed-content {
    min-height: 200px;
    background-color: var(--bg-main);
  }

  .chart-tab-content {
      padding: 16px;
  }

  /* Feed Items */
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
  }

  .empty-icon-circle {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background-color: var(--bg-secondary);
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-secondary);
      margin-bottom: 16px;
  }

  .empty-feed h3 {
      margin: 0 0 8px 0;
      color: var(--text-main);
      font-size: 20px;
      font-weight: 800;
  }

  .empty-feed p {
      max-width: 300px;
      margin: 0;
      font-size: 15px;
      line-height: 1.4;
  }

  /* CTA */
  .cta-container {
    display: flex;
    justify-content: center;
    padding-top: 60px;
    width: 100%;
  }

  .cta-card {
    background-color: var(--bg-main);
    padding: 32px;
    border-radius: 16px;
    border: 1px solid var(--border-color);
    text-align: center;
    max-width: 400px;
    box-shadow: var(--shadow-sm);
  }

  .cta-card h2 {
    font-size: 24px;
    margin-bottom: 12px;
  }

  .cta-card p {
    color: var(--text-secondary);
    margin-bottom: 24px;
  }

  .cta-actions {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .btn-secondary {
    display: block;
    padding: 12px;
    background-color: transparent;
    color: var(--primary-color);
    border: 1px solid var(--border-color);
    border-radius: 9999px;
    font-weight: 700;
    text-decoration: none;
    transition: background-color 0.2s;
  }
  .btn-secondary:hover {
    background-color: var(--bg-hover);
  }
</style>
