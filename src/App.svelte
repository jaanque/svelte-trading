<script lang="ts">
  import Navbar from "./components/general/navbar/Navbar.svelte";
  import Home from "./components/pages/Home.svelte";
  import Markets from "./components/pages/Markets.svelte";
  import Messages from "./components/pages/Messages.svelte";
  import Portfolio from "./components/pages/Portfolio.svelte";
  import Notifications from "./components/pages/Notifications.svelte";
  import Settings from "./components/pages/Settings.svelte";
  import Profile from "./components/pages/Profile.svelte";
  import Post from "./components/pages/Post.svelte";
  import Login from "./components/pages/Login.svelte";
  import Register from "./components/pages/Register.svelte";
  import TopNavbar from "./components/general/navbar/TopNavbar.svelte";
  import { onMount } from "svelte";
  import { initAuth, userSession } from "./lib/authStore";

  let isCollapsed = false;
  let currentPath = window.location.pathname;
  let showPostModal = false;

  function handleNavigate(path: string) {
    if (path === "/post") {
      showPostModal = true;
      // Do not update history or currentPath for modal interactions
      return;
    }
    currentPath = path;
    window.history.pushState({}, "", path);
  }

  function closePostModal() {
    showPostModal = false;
  }

  onMount(() => {
    initAuth(); // Initialize authentication listener

    const handlePopState = () => {
      currentPath = window.location.pathname;
    };

    window.addEventListener("popstate", handlePopState);

    return () => {
      window.removeEventListener("popstate", handlePopState);
    };
  });

  $: isAuthPage = currentPath === "/login" || currentPath === "/register";
  $: route = currentPath.split("?")[0];
</script>

{#if isAuthPage}
  {#if currentPath === "/login"}
    <Login onNavigate={handleNavigate} />
  {:else if currentPath === "/register"}
    <Register onNavigate={handleNavigate} />
  {/if}
{:else}
  <div class="app-layout" style="--sidebar-width: {isCollapsed ? '88px' : '275px'}">
    <Navbar bind:isCollapsed {currentPath} onNavigate={handleNavigate} />
    <main class="main-content">
      {#if !$userSession}
        <TopNavbar onNavigate={handleNavigate} />
      {/if}
      <div class="page-container {route === '/profile' || route === '/portfolio' || route === '/messages' || route === '/settings' || route === '/markets' ? 'full-width' : ''}">
        {#if route === "/" || route === ""}
          <Home />
        {:else if route === "/markets"}
          <Markets onNavigate={handleNavigate} />
        {:else if route === "/messages"}
          <Messages />
        {:else if route === "/portfolio"}
          <Portfolio />
        {:else if route === "/notifications"}
          <Notifications />
        {:else if route === "/settings"}
          <Settings />
        {:else if route === "/profile"}
          <Profile />
        {:else}
          <Home />
        {/if}
      </div>
    </main>

    {#if showPostModal}
      <Post onClose={closePostModal} />
    {/if}
  </div>
{/if}

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      Helvetica, Arial, sans-serif;
    background-color: #ffffff;
    color: #0f1419;
  }

  /* Global Typography Refinements for Pages */
  :global(h1) {
    font-size: 24px;
    font-weight: 700;
    margin: 0 0 24px 0;
    line-height: 28px;
    color: #0f1419;
  }

  .app-layout {
    display: flex;
    width: 100%;
    min-height: 100vh;
  }

  .main-content {
    margin-left: var(--sidebar-width);
    width: calc(100% - var(--sidebar-width));
    padding: 0; /* Reset padding to allow full control by page container or sticky headers if needed */
    box-sizing: border-box;
    transition: margin-left 0.5s cubic-bezier(0.2, 0.8, 0.2, 1), width 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .page-container {
    padding: 16px 20px;
    max-width: 1000px; /* Increased for dashboard feel */
    margin: 0;
  }

  /* Full width modifier for Profile page */
  .page-container.full-width {
    padding: 0;
    max-width: none;
    width: 100%;
  }

  @media (max-width: 768px) {
    .main-content {
      margin-left: 88px;
      width: calc(100% - 88px);
    }
  }

  @media (max-width: 640px) {
    .main-content {
      margin-left: 0;
      width: 100%;
      padding-bottom: 80px; /* Space for bottom nav */
    }

    .page-container {
      padding: 12px 16px;
    }

    .page-container.full-width {
      padding: 0;
    }
  }
</style>
