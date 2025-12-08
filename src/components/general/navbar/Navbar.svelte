<script lang="ts">
  import "./navbar.ts";
  import {
    Home,
    Search,
    Mail,
    BarChart3,
    Bell,
    Settings,
    ChevronLeft,
    ChevronRight,
    MoreHorizontal,
  } from "lucide-svelte";
  import { onMount } from "svelte";
  // @ts-ignore
  import svelteLogo from "../../../assets/svelte.svg";

  export let isCollapsed = false;
  export let currentPath = "/";
  export let onNavigate: (path: string) => void = () => {};

  function toggleCollapse() {
    isCollapsed = !isCollapsed;
  }

  function handleLinkClick(event: MouseEvent, path: string) {
    event.preventDefault();
    onNavigate(path);
  }

  const navItems = [
    { path: "/", label: "Home", icon: Home, size: 28, strokeWidth: 2 },
    { path: "/markets", label: "Markets", icon: Search, size: 28, strokeWidth: 2 },
    { path: "/messages", label: "Messages", icon: Mail, size: 28, strokeWidth: 2 },
    { path: "/portfolio", label: "Portfolio", icon: BarChart3, size: 28, strokeWidth: 2 },
    { path: "/notifications", label: "Notifications", icon: Bell, size: 28, strokeWidth: 2 },
    { path: "/settings", label: "Configuration", icon: Settings, size: 28, strokeWidth: 2 },
  ];

  let navElements: HTMLAnchorElement[] = [];
  let indicatorStyle = "";

  function updateIndicator() {
    // Wait for the DOM to settle if called during render
    requestAnimationFrame(() => {
        const activeIndex = navItems.findIndex((item) => item.path === currentPath);

        if (activeIndex !== -1 && navElements[activeIndex]) {
          const el = navElements[activeIndex];
          indicatorStyle = `
            top: ${el.offsetTop}px;
            left: ${el.offsetLeft}px;
            width: ${el.offsetWidth}px;
            height: ${el.offsetHeight}px;
            opacity: 1;
          `;
        } else {
          indicatorStyle = "opacity: 0;";
        }
    });
  }

  $: currentPath, isCollapsed, updateIndicator();

  onMount(() => {
    updateIndicator();
    window.addEventListener('resize', updateIndicator);
    return () => window.removeEventListener('resize', updateIndicator);
  });
</script>

<nav class="sidebar {isCollapsed ? 'collapsed' : ''}">
  <div class="sidebar-container">
    <div class="brand">
      <a href="/" aria-label="Home" on:click={(e) => handleLinkClick(e, "/")}>
        <img src={svelteLogo} class="brand-icon" alt="Svelte Logo" />
      </a>
    </div>

    <a href="/profile" class="profile-card nav-item" on:click={(e) => handleLinkClick(e, "/profile")}>
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
      <div class="active-indicator" style={indicatorStyle}></div>
      {#each navItems as item, i}
        <li>
          <a
            href={item.path}
            class="nav-item {currentPath === item.path ? 'active' : ''}"
            title={item.label}
            on:click={(e) => handleLinkClick(e, item.path)}
            bind:this={navElements[i]}
          >
            <div class="icon-container">
              <svelte:component this={item.icon} size={item.size} strokeWidth={item.strokeWidth} />
            </div>
            <!-- Use data-text to create a bold placeholder -->
            <span class="text" data-text={item.label}>{item.label}</span>
          </a>
        </li>
      {/each}
    </ul>
  </div>

  <button
    class="collapse-toggle"
    on:click={toggleCollapse}
    aria-label="Toggle Menu"
  >
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
    transition:
      width 0.5s cubic-bezier(0.2, 0.8, 0.2, 1),
      padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
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
    transition:
      opacity 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      width 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      margin-right 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
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

  .sidebar.collapsed .nav-item {
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
    padding: 4px 0 4px 16px; /* Adjusted padding for alignment in expanded mode */
    margin-bottom: 4px;
    width: 100%;
    display: flex;
    box-sizing: border-box; /* Ensure padding is included in width */
    transition: justify-content 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  /* Reset padding in collapsed mode to ensure centering */
  .sidebar.collapsed .brand {
    padding-left: 0;
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
    transition:
      background-color 0.2s,
      padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1),
      transform 0.1s cubic-bezier(0.2, 0.8, 0.2, 1);
    box-sizing: border-box;
    background: none;
    border: none;
    overflow: hidden; /* Hide overflow content during transition */
  }

  .profile-card:hover {
    background-color: var(--hover-bg);
    transform: scale(1.02);
  }

  .profile-card:active {
    transform: scale(0.98);
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
    width: 48px;
    height: 48px;
    border-radius: 50%;
    transition: background-color 0.2s;
    color: var(--text-color);
  }

  .brand a:hover {
    background-color: var(--hover-bg);
  }

  .brand-icon {
    height: 28px;
    width: 28px;
    object-fit: contain; /* Ensure image fits nicely */
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
    position: relative; /* Essential for absolute positioning of indicator */
  }

  .nav-links li {
    width: 100%;
    display: flex;
  }

  .nav-item {
    display: inline-flex;
    align-items: center; /* Ensures vertical alignment of icon and text */
    padding: 16px 24px 16px 16px;
    border-radius: 9999px;
    text-decoration: none;
    color: var(--text-color);
    transition:
      background-color 0.2s,
      padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1),
      transform 0.1s cubic-bezier(0.2, 0.8, 0.2, 1);
    cursor: pointer;
    background: none;
    border: none;
    outline: none;
    margin: 10px 0;
    overflow: hidden;
    position: relative; /* Ensure it's above indicator if z-index is tricky, or below? */
    z-index: 1; /* Content above indicator */
  }

  .nav-item:hover {
    background-color: var(--hover-bg);
    transform: scale(1.02);
  }

  .nav-item:active {
    transform: scale(0.98);
  }

  /* Remove old active background */
  .nav-item.active {
    background-color: transparent;
  }

  .nav-item.active .text {
    font-weight: 800;
  }

  /* Reserve space for bold text to prevent layout shift */
  .text::after {
    display: block;
    content: attr(data-text);
    font-weight: 800;
    height: 0;
    overflow: hidden;
    visibility: hidden;
  }

  /* Active Indicator */
  .active-indicator {
    position: absolute;
    background-color: rgba(29, 155, 240, 0.1);
    border-radius: 9999px;
    z-index: 0; /* Behind the link content */
    pointer-events: none;
    transition:
      top 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      left 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      width 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      height 0.3s cubic-bezier(0.2, 0.8, 0.2, 1),
      opacity 0.2s;
  }

  .icon-container {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px; /* Fixed width for icon container ensures alignment */
    height: 32px; /* Ensure sufficient height */
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

    .brand {
       padding-left: 0;
    }

    .brand,
    .nav-links li {
      display: flex;
      justify-content: center;
    }

    .nav-item {
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

    /* Since mobile layout changes drastically (horizontal), absolute positioning of indicator might be tricky.
       Maybe hide the sliding indicator on mobile and fall back to simple color?
       Or try to make it horizontal?
       For now, let's keep it simple. If it works, great.
       Horizontal flex: offsetTop will be constant (0 or small), left will change.
       It should work!
    */

    .nav-links li {
      width: auto;
    }

    .nav-item,
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
