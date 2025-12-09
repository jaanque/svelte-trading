<script lang="ts">
  import { Search } from "lucide-svelte";
  import { supabase } from "../../lib/supabase";
  import { onMount } from "svelte";

  let searchQuery = "";
  let searchResults: any[] = [];
  let isLoading = false;
  let debounceTimer: any;

  async function performSearch() {
    if (!searchQuery.trim()) {
      searchResults = [];
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

  // Initial fetch or specific logic if needed on mount, but usually search is user-driven.
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
      <div class="empty-state">
        <p>Try searching for people, lists, or keywords</p>
      </div>
    {:else if searchResults.length === 0}
      <div class="no-results">
        <p>No results for "{searchQuery}"</p>
      </div>
    {:else}
      <div class="users-list">
        {#each searchResults as user}
          <a href={`/profile?u=${user.username}`} class="user-card">
            <div class="avatar">
              <img
                src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`}
                alt={user.username}
              />
            </div>
            <div class="user-info">
              <span class="fullname">{user.full_name || "Unknown"}</span>
              <span class="username">@{user.username}</span>
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
    /* Replicating the "Twitter" style explore header which is often sticky or part of the flow */
  }

  .search-header {
    margin-bottom: 24px;
    position: sticky;
    top: 0;
    background-color: rgba(255, 255, 255, 0.85); /* fallback */
    background-color: var(--bg-main); /* Ensure it matches bg */
    z-index: 10;
    padding-bottom: 8px; /* Spacing */
  }

  /* Twitter-like Search Bar */
  .search-bar {
    display: flex;
    align-items: center;
    background-color: var(--bg-secondary);
    border-radius: 9999px;
    padding: 0 12px;
    height: 44px;
    border: 1px solid transparent;
    transition: background-color 0.2s, border-color 0.2s, box-shadow 0.2s;
  }

  .search-bar:focus-within {
    background-color: var(--bg-main);
    border-color: var(--primary-color);
    box-shadow: 0 0 0 1px var(--primary-color);
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
    color: var(--text-main);
    height: 100%;
  }

  .search-bar input::placeholder {
    color: var(--text-secondary);
  }

  /* Results */
  .results-container {
    min-height: 200px;
  }

  .empty-state, .no-results {
    padding: 40px 20px;
    text-align: center;
    color: var(--text-secondary);
    font-size: 15px;
  }

  /* User List */
  .users-list {
    display: flex;
    flex-direction: column;
  }

  .user-card {
    display: flex;
    align-items: center;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color);
    text-decoration: none;
    transition: background-color 0.2s;
    cursor: pointer;
  }

  .user-card:hover {
    background-color: var(--bg-hover);
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
    background-color: var(--bg-tertiary);
  }

  .user-info {
    display: flex;
    flex-direction: column;
    justify-content: center;
  }

  .fullname {
    font-weight: 700;
    font-size: 15px;
    color: var(--text-main);
  }

  .username {
    font-size: 14px;
    color: var(--text-secondary);
  }

  /* Loading Spinner */
  .loading-state {
    display: flex;
    justify-content: center;
    padding: 40px;
  }

  .spinner {
    border: 3px solid var(--bg-tertiary);
    border-top: 3px solid var(--primary-color);
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
