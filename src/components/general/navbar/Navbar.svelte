<script lang="ts">
  import "./navbar.ts";
  import {
    Home,
    Compass,
    Activity,
    MessageCircle,
    MoreHorizontal,
    ChevronLeft,
    ChevronRight,
  } from "lucide-svelte";

  export let isCollapsed = false;

  function toggleCollapse() {
    isCollapsed = !isCollapsed;
  }
</script>

<nav class="sidebar {isCollapsed ? 'collapsed' : ''}">
  <div class="sidebar-container">
    <div class="brand">
      <a href="/" aria-label="Home">
        <!-- X logo (Brand) -->
        <svg viewBox="0 0 24 24" aria-hidden="true" class="brand-icon">
          <g>
            <path
              d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
            ></path>
          </g>
        </svg>
      </a>
    </div>

    <a href="/profile" class="profile-card nav-item">
      <div class="profile-avatar">
        <img
          src="https://api.dicebear.com/9.x/avataaars/svg?seed=Jules"
          alt="Profile"
        />
      </div>
      <div class="profile-details">
        <div class="profile-name">Jules Agent</div>
        <div class="profile-handle">@jules_agent</div>
        <div class="profile-value">▲ $1,240.00</div>
      </div>
      <div class="profile-more">
        <MoreHorizontal size={18} color="#536471" />
      </div>
    </a>

    <ul class="nav-links">
      <li>
        <a href="/" class="nav-item active" title="Home">
          <div class="icon-container">
            <Home size={30} strokeWidth={3} />
          </div>
          <span class="text">Home</span>
        </a>
      </li>
      <li>
        <a href="/explore" class="nav-item" title="Explore">
          <div class="icon-container">
            <Compass size={28} strokeWidth={2} />
          </div>
          <span class="text">Explore</span>
        </a>
      </li>
      <li>
        <a href="/notifications" class="nav-item" title="Notifications">
          <div class="icon-container">
            <Activity size={28} strokeWidth={2} />
          </div>
          <span class="text">Notifications</span>
        </a>
      </li>
      <li>
        <a href="/messages" class="nav-item" title="Messages">
          <div class="icon-container">
            <MessageCircle size={28} strokeWidth={2} />
          </div>
          <span class="text">Messages</span>
        </a>
      </li>
      <li>
        <button class="nav-item-button" title="More">
          <div class="icon-container">
            <MoreHorizontal size={28} strokeWidth={2} />
          </div>
          <span class="text">More</span>
        </button>
      </li>
    </ul>
  </div>

  <button class="collapse-toggle" on:click={toggleCollapse} aria-label="Toggle Menu">
    {#if isCollapsed}
        <ChevronRight size={24} />
    {:else}
        <ChevronLeft size={24} />
    {/if}
  </button>
</nav>

<style>
  :root {
    --sidebar-width: 275px;
    --primary-color: #1d9bf0;
    --hover-bg: rgba(15, 20, 25, 0.1);
    --text-color: #0f1419;
    --font-family: "TwitterChirp", -apple-system, BlinkMacSystemFont, "Segoe UI",
      Roboto, Helvetica, Arial, sans-serif;
  }

  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: var(--sidebar-width);
    display: flex;
    flex-direction: column;
    padding: 0 16px;
    overflow-y: auto;
    border-right: 1px solid rgb(239, 243, 244);
    background-color: #ffffff;
    z-index: 1000;
    box-sizing: border-box;
    transition: width 0.5s cubic-bezier(0.2, 0.8, 0.2, 1), padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  /* Collapsed state styles - mimics tablet media query but via class */
  .sidebar.collapsed {
    width: 88px; /* Force width */
    padding: 0 12px;
    align-items: center;
  }

  .sidebar.collapsed .brand,
  .sidebar.collapsed .nav-links li {
    justify-content: center;
  }

  /* Animate text fading and hiding */
  .text,
  .profile-details,
  .profile-more {
    opacity: 1;
    width: auto;
    margin-right: 16px;
    transform: translateX(0);
    transition: opacity 0.3s cubic-bezier(0.2, 0.8, 0.2, 1), width 0.3s cubic-bezier(0.2, 0.8, 0.2, 1), transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1), margin-right 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed .text,
  .sidebar.collapsed .profile-details,
  .sidebar.collapsed .profile-more {
    opacity: 0;
    width: 0;
    margin-right: 0;
    transform: translateX(-10px);
    overflow: hidden;
    white-space: nowrap;
    pointer-events: none; /* Prevent clicks on hidden text */
  }

  .sidebar.collapsed .icon-container,
  .sidebar.collapsed .profile-avatar {
     margin-right: 0;
  }

  .sidebar.collapsed .profile-card {
      justify-content: center;
      padding: 12px;
  }

  .sidebar.collapsed .nav-item,
  .sidebar.collapsed .nav-item-button {
      padding: 12px;
  }

  .sidebar-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    align-items: flex-start;
    width: 100%;
    /* Transition inner container just in case */
    transition: align-items 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed .sidebar-container {
      align-items: center;
  }

  /* Brand */
  .brand {
    padding: 4px 0;
    margin-bottom: 4px;
    width: 100%;
    display: flex;
    transition: justify-content 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  /* Profile Card */
  .profile-card {
    display: flex;
    align-items: center;
    padding: 16px;
    margin: 12px 0 24px 0;
    width: 100%;
    border-radius: 9999px;
    text-decoration: none;
    color: var(--text-color);
    transition: all 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
    box-sizing: border-box;
    background-color: #ffffff;
    border: 1px solid rgb(239, 243, 244);
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.02);
    overflow: hidden; /* Hide overflow content during transition */
  }

  .profile-card:hover {
    background-color: #f7f9f9;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    border-color: transparent;
  }

  .sidebar.collapsed .profile-card:hover {
      transform: scale(1.1); /* Slightly more bounce when small */
  }

  .profile-avatar {
    margin-right: 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    transition: margin-right 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .profile-avatar img {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    object-fit: cover;
    background-color: #ddd;
  }

  .profile-details {
    display: flex;
    flex-direction: column;
    justify-content: center;
    line-height: 1.2;
    white-space: nowrap; /* Prevent wrapping during transition */
    /* Transition is handled by common rule above */
  }


  .profile-name {
    font-weight: 800;
    font-size: 17px;
    color: #0f1419;
  }

  /* Lucide icon class needs global or deep selector if passing class prop, but here inline styles or wrapper works better.
     However, we can just style it via SVG tag if needed, but let's assume default sizing works.
  */

  .profile-more {
      margin-left: auto;
      color: #0f1419;
      display: flex;
      align-items: center;
  }

  .profile-handle {
    font-size: 15px;
    color: #536471;
  }

  .profile-value {
    font-size: 15px;
    color: #00ba7c;
    font-weight: 700;
    margin-top: 4px;
  }

  /* Responsive adjustment for Profile Card - keep existing media query as fallback/base */
  @media (max-width: 768px) {
    .profile-card {
      justify-content: center;
      padding: 12px;
    }
    .profile-details {
      display: none;
    }
    .profile-avatar {
      margin-right: 0;
    }
  }

  .brand a {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 56px;
    height: 56px;
    border-radius: 50%;
    transition: background-color 0.2s;
    color: var(--text-color);
  }

  .brand a:hover {
    background-color: var(--hover-bg);
  }

  .brand-icon {
    height: 32px;
    width: 32px;
    fill: currentColor;
  }

  /* Nav Links */
  .nav-links {
    list-style: none;
    padding: 0;
    margin: 0;
    width: 100%;
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }

  .nav-links li {
    width: 100%;
    display: flex;
  }

  .nav-item,
  .nav-item-button {
    display: inline-flex;
    align-items: center;
    padding: 16px 24px 16px 16px;
    border-radius: 9999px;
    text-decoration: none;
    color: var(--text-color);
    transition: background-color 0.2s, padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1), transform 0.1s cubic-bezier(0.2, 0.8, 0.2, 1);
    cursor: pointer;
    background: none;
    border: none;
    outline: none;
    margin: 10px 0;
    overflow: hidden;
  }

  .nav-item:hover,
  .nav-item-button:hover {
    background-color: var(--hover-bg);
    transform: scale(1.02);
  }

  .nav-item:active,
  .nav-item-button:active {
    transform: scale(0.98);
  }

  .nav-item.active {
      background-color: rgba(29, 155, 240, 0.1); /* Subtle blue tint */
  }

  .nav-item.active .text {
      font-weight: 800;
  }

  .icon-container {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    margin-right: 20px;
    transition: margin-right 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .text {
    font-size: 20px;
    font-weight: 500;
    line-height: 24px;
    color: #0f1419;
    margin-right: 16px;
    font-family: var(--font-family);
    white-space: nowrap;
    /* Transition is handled by common rule above */
  }

  /* Collapse Toggle Button */
  .collapse-toggle {
    margin-top: auto;
    margin-bottom: 20px;
    background: none;
    border: none;
    cursor: pointer;
    padding: 10px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-color);
    transition: background-color 0.2s;
    align-self: center; /* Center horizontally in flex column */
  }

  .collapse-toggle:hover {
    background-color: var(--hover-bg);
  }

  /* Responsive adjustments */
  @media (max-width: 768px) {
    :root {
      --sidebar-width: 88px;
    }

    .sidebar {
      padding: 0 12px;
      align-items: center;
    }

    .sidebar-container {
      align-items: center;
    }

    .brand,
    .nav-links li {
      display: flex;
      justify-content: center;
    }

    .nav-item,
    .nav-item-button {
        padding: 12px;
        margin: 4px 0;
    }

    .text {
      display: none;
    }

    .icon-container {
      margin-right: 0;
    }

    /* Hide toggle on small screens where it's always collapsed anyway or controlled by system */
    .collapse-toggle {
        display: none;
    }
  }

  /* Mobile Bottom Navigation */
  @media (max-width: 640px) {
    .sidebar,
    .sidebar.collapsed {
      width: 100%;
      height: auto;
      top: auto;
      bottom: 0;
      flex-direction: row;
      border-right: none;
      border-top: 1px solid rgb(239, 243, 244);
      padding: 0;
      z-index: 2000;
      overflow-y: visible;
    }

    .sidebar-container {
      flex-direction: row;
      align-items: center;
      justify-content: space-around;
      width: 100%;
      height: 60px; /* Adjust as needed */
    }

    /* Hide unnecessary elements on mobile */
    .brand,
    .profile-card,
    .collapse-toggle {
      display: none;
    }

    .nav-links {
      flex-direction: row;
      justify-content: space-around;
      align-items: center;
      width: 100%;
      height: 100%;
    }

    .nav-item.active {
        background: none; /* No background on mobile */
        color: var(--primary-color);
    }

    .nav-links li {
      width: auto;
    }

    .nav-item,
    .nav-item-button,
    .sidebar.collapsed .nav-item {
      padding: 8px;
      margin: 0;
    }

    .icon-container,
    .sidebar.collapsed .icon-container {
      margin-right: 0;
      width: auto;
    }

    .text {
      display: none;
    }
  }
</style>
