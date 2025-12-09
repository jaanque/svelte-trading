<script lang="ts">
  import { Search, X } from "lucide-svelte";
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

  function clearSearch() {
      searchQuery = "";
      searchResults = [];
  }

  // Initial fetch or specific logic if needed on mount, but usually search is user-driven.
</script>

<div class="explore-container">
  <!-- Search Bar Header -->
  <div class="search-header">
    <div class="search-bar-wrapper">
      <div class="search-bar">
        <div class="search-icon">
          <Search size={18} color="var(--text-secondary)" />
        </div>
        <input
          type="text"
          placeholder="Search for users..."
          bind:value={searchQuery}
          on:input={handleInput}
        />
        {#if searchQuery}
            <button class="clear-btn" on:click={clearSearch}>
                <div class="clear-icon-bg">
                    <X size={12} color="white" strokeWidth={3} />
                </div>
            </button>
        {/if}
      </div>
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
    margin-bottom: 12px;
    position: sticky;
    top: 0;
    background-color: rgba(255, 255, 255, 0.95); /* High opacity backdrop */
    backdrop-filter: blur(12px);
    z-index: 10;
    padding: 8px 0; /* Vertical padding */
  }

  .search-bar-wrapper {
      width: 100%;
      /* If the parent has padding, this fills it. If we want it strictly full width of container */
  }

  /* Twitter-like Search Bar */
  .search-bar {
    display: flex;
    align-items: center;
    background-color: var(--bg-secondary);
    border-radius: 9999px;
    padding: 0 16px;
    height: 48px; /* Slightly taller/friendlier */
    border: 1px solid transparent;
    transition: background-color 0.2s, border-color 0.2s, box-shadow 0.2s;
    width: 100%; /* Ensure it takes full width */
    box-sizing: border-box;
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
    color: var(--text-secondary);
  }

  .search-bar:focus-within .search-icon {
      color: var(--primary-color);
  }

  .search-bar input {
    flex-grow: 1;
    background: transparent;
    border: none;
    outline: none;
    font-size: 15px;
    color: var(--text-main);
    height: 100%;
    padding: 0;
  }

  .search-bar input::placeholder {
    color: var(--text-secondary);
  }

  /* Clear Button */
  .clear-btn {
      background: none;
      border: none;
      padding: 0;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-left: 8px;
      opacity: 0.7;
      transition: opacity 0.2s;
  }
  .clear-btn:hover {
      opacity: 1;
  }

  .clear-icon-bg {
      background-color: var(--primary-color);
      width: 20px;
      height: 20px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
  }

  /* Results */
  .results-container {
    min-height: 200px;
  }

  .empty-state, .no-results {
    padding: 60px 20px;
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
    padding: 16px;
    border-bottom: 1px solid var(--border-color);
    text-decoration: none;
    transition: background-color 0.2s;
    cursor: pointer;
  }

  .user-card:hover {
    background-color: var(--bg-secondary); /* Softer hover */
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
    font-size: 15px; /* Consistent font size */
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
