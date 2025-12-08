<script lang="ts">
  import Navbar from "./components/general/navbar/Navbar.svelte";

  let isCollapsed = false;
</script>

<div class="app-layout" style="--sidebar-width: {isCollapsed ? '88px' : '275px'}">
  <Navbar bind:isCollapsed />
  <main class="main-content">
    <!-- Content will go here -->
    <h1>Home</h1>
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
