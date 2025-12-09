<script lang="ts">
  import { onMount } from "svelte";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, Calendar, Link as LinkIcon, MapPin, ArrowLeft } from "lucide-svelte";

  let loading = true;
  let profileData: any = null;
  let error: string | null = null;
  let isOwnProfile = false;
  let urlUsername: string | null = null;

  // Helpers
  function getQueryParam(param: string) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
  }

  function formatNumber(num: number | undefined | null) {
      if (num === undefined || num === null) return "0";
      return num.toLocaleString();
  }

  async function loadProfile() {
    loading = true;
    error = null;
    profileData = null;

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
    loading = false;
  }

  onMount(() => {
    loadProfile();
    const handlePopState = () => { loadProfile(); };
    window.addEventListener('popstate', handlePopState);
  });

  $: $userSession, loadProfile();
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
    <div class="profile-header-section">
      <!-- Back button header if viewing another profile -->
      {#if !isOwnProfile && urlUsername}
        <div class="sticky-header">
           <a href="/" class="back-btn"><ArrowLeft size={20} /></a>
           <div class="header-name">
              <h3>{profileData.full_name}</h3>
              <span class="post-count">0 posts</span>
           </div>
        </div>
      {/if}

      <div class="banner"></div>

      <div class="profile-info-container">
        <div class="top-row">
           <div class="avatar-wrapper">
             <img
              src={profileData.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${profileData.username}`}
              alt={profileData.username}
              class="profile-avatar"
            />
           </div>

           <div class="actions">
            {#if isOwnProfile}
              <a href="/settings" class="btn-edit">Edit Profile</a>
            {:else}
              <!-- Future: Follow Button -->
              <button class="btn-primary">Follow</button>
            {/if}
          </div>
        </div>

        <div class="info">
          <h1 class="fullname">{profileData.full_name || profileData.username}</h1>
          <div class="handle">@{profileData.username}</div>

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

          <div class="stats">
             <div class="stat">
               <span class="count">0</span> <span class="label">Following</span>
             </div>
             <div class="stat">
               <span class="count">0</span> <span class="label">Followers</span>
             </div>
             <div class="stat">
                <a href="/portfolio" class="stat-link">
                    <span class="count">{formatNumber(profileData.price || 50)}</span> <span class="label">Price</span>
                </a>
             </div>
             <div class="stat">
               <span class="count">{formatNumber(profileData.shares || 1000000)}</span> <span class="label">Shares</span>
             </div>
          </div>
        </div>
      </div>
    </div>

    <div class="profile-tabs">
       <div class="tab active">Posts</div>
       <div class="tab">Replies</div>
       <div class="tab">Media</div>
       <div class="tab">Likes</div>
    </div>

    <div class="profile-content">
       <div class="empty-feed">
          <p>@{profileData.username} hasn't posted anything yet.</p>
       </div>
    </div>

  {:else}
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
  {/if}
</div>

<style>
  .profile-page {
    width: 100%;
    min-height: 100vh;
    border-left: 1px solid var(--border-color);
    border-right: 1px solid var(--border-color);
    background-color: var(--bg-main);
    /* In App.svelte, page-container has max-width: 1000px and padding.
       If we want to fill that, we are good.
       If we want to stretch to edges of that container, we might need negative margins
       if the container has padding we want to ignore (like for the banner).

       App.svelte: .page-container { padding: 16px 20px; }
       To make the banner full width relative to this component's container, we can just use width: 100%.
       But the page-container padding will leave whitespace around the banner.
       Often profiles look better if the banner hits the edges.

       Let's assume the user wants the profile to fill the "page-container" space fully.
       Actually, standard Twitter/modern layout usually has the feed column as the main thing.

       If we want "ocupe el width que se le permita" inside the existing padding, width: 100% is default.
    */
    display: flex;
    flex-direction: column;
  }

  /* To negate parent padding if desired, we would need to know exact padding values or use a different layout approach.
     For now, we will work within the container. */

  .center-content {
    display: flex;
    justify-content: center;
    align-items: center;
    flex-grow: 1;
    min-height: 50vh;
  }

  /* Sticky Header (optional, if we want that "scrolled down" effect) */
  .sticky-header {
      position: sticky;
      top: 0;
      background: rgba(255, 255, 255, 0.85);
      backdrop-filter: blur(12px);
      z-index: 10;
      padding: 0 16px;
      height: 53px;
      display: flex;
      align-items: center;
      gap: 20px;
      border-bottom: 1px solid var(--border-color);
  }

  .header-name h3 {
      margin: 0;
      font-size: 20px;
      line-height: 24px;
  }

  .post-count {
      font-size: 13px;
      color: var(--text-secondary);
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
    background-color: var(--bg-tertiary); /* Fallback */
    /* background-image: url(...); */
    width: 100%;
    position: relative;
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
      height: 40px; /* Space reserved for avatar overlap */
  }

  .avatar-wrapper {
    margin-top: -15%; /* Pull up into banner */
    /* To keep it precise: width 134px -> radius 67. half is 67.
       Usually on Twitter it overlaps by 50%. */
    width: 134px;
    height: 134px;
    border-radius: 50%;
    background-color: var(--bg-main);
    padding: 4px;
    position: absolute;
    top: -67px; /* Half height */
    left: 16px;
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
        height: 30px;
    }
  }

  .profile-avatar {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    background-color: var(--bg-tertiary);
    cursor: pointer;
    transition: filter 0.2s;
  }

  .profile-avatar:hover {
      filter: brightness(0.9);
  }

  .actions {
    margin-left: auto; /* Push to right */
    padding-bottom: 0; /* Align with bottom of avatar area conceptually */
  }

  .btn-edit {
    padding: 8px 16px;
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

  .btn-primary {
    padding: 8px 20px;
    background-color: var(--text-main); /* Black follow button often used */
    color: var(--bg-main);
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    text-decoration: none;
    transition: opacity 0.2s;
  }
  .btn-primary:hover {
      opacity: 0.8;
  }

  .fullname {
    font-size: 20px;
    font-weight: 800;
    margin: 4px 0 0 0;
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
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 12px;
    color: var(--text-secondary);
    font-size: 15px;
  }

  .meta-item {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .stats {
    display: flex;
    gap: 20px;
    font-size: 14px;
    margin-top: 4px;
  }

  .stat {
    color: var(--text-secondary);
    display: flex;
    align-items: center;
  }

  .stat-link {
    color: inherit;
    text-decoration: none;
  }
  .stat-link:hover {
      text-decoration: underline;
  }

  .count {
    font-weight: 700;
    color: var(--text-main);
    margin-right: 4px;
  }

  /* Tabs */
  .profile-tabs {
    display: flex;
    border-bottom: 1px solid var(--border-color);
    margin-top: 8px;
  }

  .tab {
    flex: 1;
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

  .profile-content {
    min-height: 200px;
  }

  .empty-feed {
    padding: 40px;
    text-align: center;
    color: var(--text-secondary);
    font-size: 15px;
    font-weight: 600;
  }

  /* CTA */
  .cta-container {
    display: flex;
    justify-content: center;
    padding-top: 60px;
  }

  .cta-card {
    background-color: var(--bg-main);
    padding: 32px;
    border-radius: 16px;
    border: 1px solid var(--border-color);
    text-align: center;
    max-width: 400px;
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
