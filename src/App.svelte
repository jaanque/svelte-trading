<script lang="ts">
  import Navbar from "./components/general/navbar/Navbar.svelte";
  import Home from "./components/pages/Home.svelte";
  import Markets from "./components/pages/Markets.svelte";
  import Messages from "./components/pages/Messages.svelte";
  import Portfolio from "./components/pages/Portfolio.svelte";
  import Notifications from "./components/pages/Notifications.svelte";
  import Settings from "./components/pages/Settings.svelte";
  import Profile from "./components/pages/Profile.svelte";
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
</script>

<div class="app-layout" style="--sidebar-width: {isCollapsed ? '88px' : '275px'}">
  <Navbar bind:isCollapsed {currentPath} onNavigate={handleNavigate} />
  <main class="main-content">
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
  </main>
</div>

<style>
  :global(body) {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
      Helvetica, Arial, sans-serif;
    background-color: #ffffff;
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
    padding: 2rem;
    box-sizing: border-box;
    transition: margin-left 0.5s cubic-bezier(0.2, 0.8, 0.2, 1), width 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
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
      padding: 1rem;
      padding-bottom: 80px; /* Space for bottom nav */
    }
  }
</style>
