<script lang="ts">
  import Navbar from "./components/general/navbar/Navbar.svelte";
</script>

<div class="app-layout">
  <Navbar />
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
    /* 
       The Navbar is fixed, so we need to offset the content.
       Since we can't easily share variables between Svelte component styles (without global CSS vars),
       we'll match the values used in navbar.css
    */
    margin-left: 275px;
    width: calc(100% - 275px);
    padding: 2rem;
    box-sizing: border-box;
  }

  @media (max-width: 1280px) {
    .main-content {
      margin-left: 88px;
      width: calc(100% - 88px);
    }
  }
</style>
