<script lang="ts">
  import Navbar from "./components/general/navbar/Navbar.svelte";
  import Home from "./pages/Home.svelte";
  import Markets from "./pages/Markets.svelte";
  import Messages from "./pages/Messages.svelte";
  import Portfolio from "./pages/Portfolio.svelte";
  import Notifications from "./pages/Notifications.svelte";
  import Settings from "./pages/Settings.svelte";
  import Profile from "./pages/Profile.svelte";
  import Login from "./pages/Login.svelte";
  import Register from "./pages/Register.svelte";
  import TopNavbar from "./components/general/TopNavbar.svelte";
  import { onMount } from "svelte";

  let isCollapsed = false;
  let currentPath = window.location.pathname;

  function handleNavigate(path: string) {
    currentPath = path;
    window.history.pushState({}, "", path);
  }

  onMount(() => {
    const handlePopState = () => {
      currentPath = window.location.pathname;
    };

    window.addEventListener("popstate", handlePopState);

    return () => {
      window.removeEventListener("popstate", handlePopState);
    };
  });

  $: isAuthPage = currentPath === "/login" || currentPath === "/register";
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
      <TopNavbar onNavigate={handleNavigate} />
      <div class="page-container">
        {#if currentPath === "/" || currentPath === ""}
          <Home />
        {:else if currentPath === "/markets"}
          <Markets />
        {:else if currentPath === "/messages"}
          <Messages />
        {:else if currentPath === "/portfolio"}
          <Portfolio />
        {:else if currentPath === "/notifications"}
          <Notifications />
        {:else if currentPath === "/settings"}
          <Settings />
        {:else if currentPath === "/profile"}
          <Profile />
        {:else}
          <Home />
        {/if}
      </div>
    </main>
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
    max-width: 600px; /* Twitter-like content column width */
    margin: 0;
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
  }
</style>
