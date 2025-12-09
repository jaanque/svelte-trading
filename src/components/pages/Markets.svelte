<script lang="ts">
  import { Search, Clock } from "lucide-svelte";
  import { supabase } from "../../lib/supabase";
  import { onMount } from "svelte";
  import UserCard from "../../components/general/UserCard.svelte";

  export let onNavigate: (path: string) => void = (path) => { window.location.href = path; };

  let searchQuery = "";
  let searchResults: any[] = [];
  let isLoading = false;
  let debounceTimer: any;
  let searchHistory: any[] = [];
  let historyLoading = false;

  async function fetchHistory() {
    historyLoading = true;
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from("search_history")
        .select(`
          created_at,
          searched_profile:profiles!inner(id, username, full_name, avatar_url)
        `)
        .eq("user_id", user.id)
        .order("created_at", { ascending: false })
        .limit(10);

      if (error) {
        // If table doesn't exist yet, we might get an error.
        // We'll ignore it for now or log it.
        console.warn("Could not fetch history:", error.message);
      } else {
        // Map data to flat profile structure
        searchHistory = data.map((item: any) => item.searched_profile).filter((p: any) => p);

        // Remove duplicates client-side just in case, though unique constraint should handle it
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

  async function addToHistory(profile: any) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // We want to upsert to update the created_at timestamp if it already exists
      // However, Supabase upsert requires primary key or unique constraint.
      // We assume (user_id, searched_profile_id) is unique.

      // First, let's try to delete existing entry for this profile to ensure "recent" behavior
      // (Putting it at the top by re-inserting)
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

      // Refresh history if we were on the history view (empty query)
      if (searchQuery.trim() === "") {
        // Optimistically update UI
        searchHistory = [profile, ...searchHistory.filter(p => p.id !== profile.id)];
      }

    } catch (err) {
      console.error("Error adding to history:", err);
    }
  }

  async function performSearch() {
    if (!searchQuery.trim()) {
      searchResults = [];
      fetchHistory(); // Refresh history when clearing search
      return;
    }

    isLoading = true;
    try {
      const { data, error } = await supabase
        .from("profiles")
        .select("id, username, full_name, avatar_url")
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

  onMount(() => {
    fetchHistory();
  });
</script>

<div class="explore-container">
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

  <!-- Content -->
  <div class="results-container">
    {#if isLoading}
      <div class="loading-state">
        <div class="spinner"></div>
      </div>
    {:else if searchQuery.trim() === ""}
      <!-- History View -->
      <div class="history-section">
        <div class="section-header">
           <h2>
             <Clock size={20} class="icon-inline" />
             Recent Searches
           </h2>
        </div>

        {#if historyLoading}
           <div class="loading-state">
             <div class="spinner"></div>
           </div>
        {:else if searchHistory.length === 0}
           <div class="empty-state">
             <p>Your search history will appear here.</p>
           </div>
        {:else}
           <div class="history-grid">
             {#each searchHistory as user (user.id)}
                  <div role="button" tabindex="0" class="card-wrapper">
                      <!-- We pass an onClick handler that intercepts the link navigation -->
                      <UserCard
                        {user}
                        onClick={() => handleProfileClick(user)}
                      />
                </div>
             {/each}
           </div>
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
          </a>
        {/each}
      </div>
    {/if}
  </div>
</div>

<style>
  .explore-container {
    width: 100%;
    padding-bottom: 80px; /* Space for bottom nav on mobile if needed */
  }

  .search-header {
    margin-bottom: 24px;
    position: sticky;
    top: 0;
    background-color: var(--bg-main, #ffffff);
    z-index: 10;
    padding-top: 10px;
    padding-bottom: 10px;
  }

  /* Twitter-like Search Bar */
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

  /* Results */
  .results-container {
    min-height: 200px;
  }

  .empty-state, .no-results {
    padding: 40px 20px;
    text-align: center;
    color: var(--text-secondary, #536471);
    font-size: 15px;
  }

  /* History Section */
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

  /* Lucide icon global style usually needs specific targeting or usage of global class if available.
     Here we scope it. */
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

  /* User List Item (Search Results) */
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

  /* Loading Spinner */
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

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
</style>
