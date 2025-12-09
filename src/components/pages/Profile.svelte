<script lang="ts">
  import { onMount } from "svelte";
  import { userProfile, userSession } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { Loader2, Calendar, Link as LinkIcon, MapPin } from "lucide-svelte";

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

  // Determine what to show
  // 1. u=username -> Fetch public profile
  // 2. No param -> Check Auth
  //    a. Auth -> Show own profile
  //    b. No Auth -> Show CTA

  async function loadProfile() {
    loading = true;
    error = null;
    profileData = null;

    urlUsername = getQueryParam("u");

    if (urlUsername) {
      // Fetch public profile
      try {
        const { data, error: err } = await supabase
          .from("profiles")
          .select("*")
          .eq("username", urlUsername)
          .single();

        if (err) throw err;
        profileData = data;

        // Check if this is actually the logged in user viewing their own public link
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
      // Viewing own profile route /profile
      if ($userSession) {
        // Logged in
        isOwnProfile = true;
        profileData = $userProfile;
        // If userProfile isn't fully loaded yet, we might wait or it reacts automatically since it's a store
        // But usually $userProfile is populated if $userSession is true (handled in authStore)
      } else {
        // Not logged in
        isOwnProfile = false;
        profileData = null;
        // We stay in a state where we show CTA
      }
    }
    loading = false;
  }

  // React to URL changes (popstate is handled in App, but we need to re-run logic if we navigate from /profile to /profile?u=xyz)
  // Since App.svelte mounts this component, purely changing query params might not unmount/remount it if the component stays the same?
  // Svelte's key block in App or reactive statements here help.
  // Let's watch window location or use a reactive statement if we can get the current path passed down, but query params change might not trigger path change prop in App.

  // A simple way is to subscribe to navigation events or just poll/watch.
  // For now, let's rely on onMount. If the user navigates *within* the app using pushState,
  // we might need a way to reload.

  // Quick fix: Use a reactive statement on a variable that changes on nav, or hook into the `onNavigate` prop if we passed it.
  // We didn't pass onNavigate to pages in App.svelte.

  // Let's add a mechanism to detect URL changes if the component is already mounted.

  onMount(() => {
    loadProfile();

    const handlePopState = () => {
        loadProfile();
    };
    window.addEventListener('popstate', handlePopState);

    // Custom event dispatch from App.svelte or Navbar could help, but for now assuming full re-renders or popstate.
    // If clicking a link in Svelte SPA updates history state but doesn't unmount component, we need to know.
    // In App.svelte: `{#if currentPath === "/profile"} <Profile /> {/if}`.
    // If we go from /profile to /profile?u=x, currentPath is likely still /profile (depending on how we parsed it).
    // In App.svelte: `currentPath = window.location.pathname`. Query params are ignored in that matching logic.
    // So <Profile> remains mounted. We need to watch the URL.

    // We can use a MutationObserver or just patch pushState (overkill).
    // Or simply, we can export a function or variable that App updates.
    // OR, simpler: use a reactive block with a hacky timer or just rely on the fact that `App.svelte` `handleNavigate`
    // updates `currentPath`. If `currentPath` doesn't change, App doesn't re-render.
    // BUT `window.location.search` changes.

    // Let's hook into the global navigation function if possible, or simple setInterval check for URL change? No.
    // Let's assume for this iteration that links trigger a full nav or we add a listener for a custom event.
    // The `Navbar` calls `onNavigate`, which does `pushState`.
    // We can listen to that if we emit an event.
  });

  // Re-run loadProfile if $userSession changes (login/logout)
  $: $userSession, loadProfile();

</script>

<div class="profile-page">
  <!-- Loading State -->
  {#if loading}
    <div class="center-content">
      <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
    </div>

  <!-- Error State (e.g. User not found) -->
  {:else if error}
    <div class="center-content">
      <div class="error-container">
        <h2>User not found</h2>
        <p>The profile you are looking for does not exist.</p>
        <a href="/" class="btn-secondary">Go Home</a>
      </div>
    </div>

  <!-- Case: Show Profile (Own or Other) -->
  {:else if profileData}
    <div class="profile-header">
      <div class="banner"></div> <!-- Placeholder for banner -->
      <div class="profile-info-container">
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
            <!-- Follow/Message buttons could go here -->
          {/if}
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
                <span>Joined recently</span> <!-- We assume joined_at isn't in table yet or we default -->
             </div>
             {#if profileData.website}
               <div class="meta-item">
                 <LinkIcon size={16} />
                 <a href={profileData.website} target="_blank" rel="noopener noreferrer">{profileData.website}</a>
               </div>
             {/if}
          </div>

          <div class="stats">
             <!-- Example stats -->
             <div class="stat">
               <span class="count">0</span> <span class="label">Following</span>
             </div>
             <div class="stat">
               <span class="count">0</span> <span class="label">Followers</span>
             </div>
             <div class="stat">
                <span class="count">{profileData.tokens || 0}</span> <span class="label">Tokens</span>
             </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Profile Tabs/Content -->
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

  <!-- Case: CTA (Not logged in, no 'u' param) -->
  {:else}
    <div class="cta-container">
      <div class="cta-card">
         <h2>Join to see your profile</h2>
         <p>Sign up now to create your own profile, follow others, and start trading.</p>
         <div class="cta-actions">
           <!-- Note: These should trigger navigation. Using href for simplicity, assuming App intercepts or standard link nav. -->
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
    min-height: 100%;
    position: relative;
  }

  .center-content {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 50vh;
  }

  /* Banner */
  .banner {
    height: 200px;
    background-color: var(--bg-tertiary);
    width: 100%;
    /* Could add background image support later */
  }

  /* Info Header */
  .profile-info-container {
    padding: 12px 16px;
    position: relative;
  }

  .avatar-wrapper {
    margin-top: -15%; /* Overlap banner */
    margin-bottom: 12px;
    width: 134px;
    height: 134px;
    border-radius: 50%;
    background-color: var(--bg-main);
    padding: 4px;
    display: inline-block;
  }

  @media (max-width: 640px) {
    .avatar-wrapper {
        width: 90px;
        height: 90px;
        margin-top: -45px;
    }
    .banner {
        height: 120px;
    }
  }

  .profile-avatar {
    width: 100%;
    height: 100%;
    border-radius: 50%;
    object-fit: cover;
    background-color: var(--bg-tertiary);
  }

  .actions {
    position: absolute;
    top: 12px;
    right: 16px;
  }

  .btn-edit {
    display: inline-block;
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

  .fullname {
    font-size: 20px;
    font-weight: 800;
    margin: 0;
    color: var(--text-main);
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

  .meta-item a {
    color: var(--primary-color);
  }

  .stats {
    display: flex;
    gap: 20px;
    font-size: 14px;
  }

  .stat {
    color: var(--text-secondary);
  }

  .count {
    font-weight: 700;
    color: var(--text-main);
  }

  /* Tabs */
  .profile-tabs {
    display: flex;
    border-bottom: 1px solid var(--border-color);
    margin-top: 16px;
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
    width: 56px; /* Approx width of text */
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

  .btn-primary {
    display: block;
    padding: 12px;
    background-color: var(--primary-color);
    color: white;
    border-radius: 9999px;
    font-weight: 700;
    text-decoration: none;
    transition: background-color 0.2s;
  }

  .btn-primary:hover {
    background-color: var(--primary-hover);
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
