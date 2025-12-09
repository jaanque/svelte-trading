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
    LogOut,
    Plus,
  } from "lucide-svelte";
  import { onMount } from "svelte";
  import { userProfile } from "../../../lib/authStore";
  import { supabase } from "../../../lib/supabase";
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
    { path: "/settings", label: "Settings", icon: Settings, size: 28, strokeWidth: 2 },
  ];

  let navElements: HTMLAnchorElement[] = [];
  let indicatorStyle = "";

  let showProfileMenu = false;

  async function handleLogout() {
    await supabase.auth.signOut();
    showProfileMenu = false;
    window.location.href = '/';
  }

  function toggleProfileMenu(e: Event) {
    e.stopPropagation();
    showProfileMenu = !showProfileMenu;
  }

  function updateIndicator() {
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
    const closeMenu = () => showProfileMenu = false;
    window.addEventListener('click', closeMenu);
    return () => {
      window.removeEventListener('resize', updateIndicator);
      window.removeEventListener('click', closeMenu);
    };
  });
</script>

<nav class="sidebar {isCollapsed ? 'collapsed' : ''}">
  <div class="sidebar-container">
    <div class="brand">
      <a href="/" aria-label="Home" on:click={(e) => handleLinkClick(e, "/")}>
        <img src={svelteLogo} class="brand-icon" alt="Svelte Logo" />
      </a>
    </div>

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
            <span class="text" data-text={item.label}>{item.label}</span>
          </a>
        </li>
      {/each}
    </ul>

    <a
      href="/post"
      class="post-btn"
      aria-label="Post"
      on:click={(e) => handleLinkClick(e, "/post")}
    >
      <div class="post-icon-container">
        <Plus size={24} strokeWidth={3} />
      </div>
      <span class="text post-text">Post</span>
    </a>

    <div class="spacer"></div>

    {#if $userProfile}
      <div class="profile-section">
        <div class="profile-card-container">
          <!-- Main profile click area navigates to profile -->
          <a href="/profile" class="profile-card nav-item" on:click={(e) => handleLinkClick(e, "/profile")}>
            <div class="profile-avatar">
              <img
                src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
                alt="Profile"
              />
            </div>
            <div class="profile-details">
              <div class="profile-name">{$userProfile.full_name}</div>
              <div class="profile-handle">@{$userProfile.username}</div>
            </div>
          </a>

          <!-- More button is separate -->
          <button class="profile-more-btn" on:click={toggleProfileMenu}>
            <MoreHorizontal size={18} color="var(--text-secondary)" />
          </button>

          {#if showProfileMenu}
            <div class="profile-menu">
              <button class="menu-item logout" on:click={handleLogout}>
                <LogOut size={16} style="margin-right: 8px;" />
                Log out @{$userProfile.username}
              </button>
            </div>
          {/if}
        </div>
      </div>
    {/if}
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
    border-right: 1px solid var(--border-color);
    background-color: var(--bg-main);
    z-index: 1000;
    box-sizing: border-box;
    transition:
      width 0.5s cubic-bezier(0.2, 0.8, 0.2, 1),
      padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed {
    width: var(--sidebar-width-collapsed);
    padding: 0 12px;
    align-items: center;
  }

  .sidebar-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    align-items: flex-start;
    width: 100%;
    transition: align-items 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed .sidebar-container {
    align-items: center;
  }

  /* Brand */
  .brand {
    padding: 8px 0;
    margin-bottom: 8px;
    width: 100%;
    display: flex;
    justify-content: flex-start;
    transition: justify-content 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed .brand {
    justify-content: center;
  }

  .brand a {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 48px;
    height: 48px;
    border-radius: 50%;
    transition: background-color 0.2s;
    color: var(--text-main);
  }

  .brand a:hover {
    background-color: var(--bg-hover);
  }

  .brand-icon {
    height: 28px;
    width: 28px;
    object-fit: contain;
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
    position: relative;
    /* Removed flex-grow to insert items below */
  }

  .nav-links li {
    width: 100%;
    display: flex;
  }

  .sidebar.collapsed .nav-links li {
    justify-content: center;
  }

  .nav-item {
    display: inline-flex;
    align-items: center;
    padding: 12px;
    border-radius: 9999px;
    text-decoration: none;
    color: var(--text-main);
    transition:
      background-color 0.2s,
      padding 0.5s cubic-bezier(0.2, 0.8, 0.2, 1),
      transform 0.1s cubic-bezier(0.2, 0.8, 0.2, 1);
    cursor: pointer;
    background: none;
    border: none;
    outline: none;
    margin: 4px 0;
    overflow: hidden;
    position: relative;
    z-index: 1;
  }

  .nav-item:hover {
    background-color: var(--bg-hover);
  }

  .active-indicator {
    position: absolute;
    background-color: var(--bg-hover); /* Use hover color or primary with low opacity */
    /* background-color: rgba(29, 155, 240, 0.1); */
    border-radius: 9999px;
    z-index: 0;
    pointer-events: none;
    transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .icon-container {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    margin-right: 16px;
    transition: margin-right 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
  }

  .sidebar.collapsed .icon-container {
    margin-right: 0;
  }

  .text {
    font-size: 20px;
    font-weight: 400;
    line-height: 24px;
    color: var(--text-main);
    margin-right: 16px;
    white-space: nowrap;
    opacity: 1;
    width: auto;
    transition:
      opacity 0.3s,
      width 0.3s;
  }

  .sidebar.collapsed .text {
    opacity: 0;
    width: 0;
    margin-right: 0;
    overflow: hidden;
  }

  .text::after {
    display: block;
    content: attr(data-text);
    font-weight: 700;
    height: 0;
    overflow: hidden;
    visibility: hidden;
  }

  .nav-item.active .text {
    font-weight: 700;
  }

  .nav-item.active {
      color: var(--text-main); /* Ensure text stays main color */
  }

  /* Post Button */
  .post-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--primary-color);
    color: white;
    border-radius: 9999px;
    padding: 16px;
    margin: 32px 0 12px 0;
    width: 90%;
    font-weight: 800;
    font-size: 18px;
    cursor: pointer;
    transition: background-color 0.2s, width 0.3s, padding 0.3s, transform 0.2s;
    text-decoration: none;
    border: none;
    align-self: center; /* Center in sidebar */
  }

  .post-btn:hover {
    background-color: var(--primary-hover);
    transform: scale(1.02);
    text-decoration: none;
  }

  .post-btn:active {
    transform: scale(0.98);
  }

  .post-icon-container {
    display: flex; /* Always flex to center icon */
    align-items: center;
    justify-content: center;
  }

  /* Collapsed Post Button */
  .sidebar.collapsed .post-btn {
    width: 50px;
    height: 50px;
    padding: 0;
    border-radius: 50%;
    margin: 24px 0 12px 0;
    box-shadow: var(--shadow-md);
  }

  .sidebar.collapsed .post-text {
    display: none;
    opacity: 0;
    width: 0;
  }

  /* When expanded, we show text and hide icon? No, user wants icon ("icona quiero que sea un simbolo de mas")
     Ideally on expanded: Icon + "Post" text, or just "Post"?
     Twitter does "Post" text only on expanded large screens, but feather icon on smaller.
     Let's do Icon + Text for clarity or Text only?
     "perfeccionalo y la icona quiero que sea un simbolo de mas" implies the icon is important.
     Let's show Icon + Text on expanded.
  */
  .post-btn .post-icon-container {
     margin-right: 8px;
  }

  .sidebar.collapsed .post-btn .post-icon-container {
     margin-right: 0;
  }

  /* Spacer to push profile down */
  .spacer {
    flex-grow: 1;
    width: 100%;
  }

  /* Profile Section */
  .profile-section {
    width: 100%;
    margin-bottom: 12px;
  }

  .profile-card-container {
    display: flex;
    align-items: center;
    width: 100%;
    position: relative;
    padding: 4px;
    border-radius: 9999px;
    transition: background-color 0.2s;
  }

  .profile-card-container:hover {
     background-color: var(--bg-hover);
  }

  .sidebar.collapsed .profile-card-container {
    justify-content: center;
    padding: 0;
    background: none;
  }

  .profile-card {
    padding: 8px;
    margin: 0;
    flex-grow: 1;
  }

  .sidebar.collapsed .profile-card {
     justify-content: center;
     flex-grow: 0;
     padding: 12px;
  }

  .sidebar.collapsed .profile-card:hover {
     background-color: var(--bg-hover);
     border-radius: 50%;
  }

  .profile-avatar {
    margin-right: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    transition: margin-right 0.5s;
  }

  .sidebar.collapsed .profile-avatar {
    margin-right: 0;
  }

  .profile-avatar img {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    object-fit: cover;
    background-color: var(--bg-tertiary);
  }

  .profile-details {
    display: flex;
    flex-direction: column;
    justify-content: center;
    line-height: 1.2;
    overflow: hidden;
    transition: opacity 0.3s, width 0.3s;
    opacity: 1;
    width: auto;
  }

  .sidebar.collapsed .profile-details {
    display: none;
    opacity: 0;
    width: 0;
  }

  .profile-name {
    font-weight: 700;
    font-size: 15px;
    color: var(--text-main);
  }

  .profile-handle {
    font-size: 15px;
    color: var(--text-secondary);
  }

  .profile-more-btn {
    margin-left: auto;
    color: var(--text-main);
    display: flex;
    align-items: center;
    justify-content: center;
    background: none;
    border: none;
    cursor: pointer;
    padding: 8px;
    border-radius: 50%;
    transition: background-color 0.2s;
  }

  .sidebar.collapsed .profile-more-btn {
      display: none;
  }

  .profile-more-btn:hover {
    background-color: rgba(29, 155, 240, 0.1);
    color: var(--primary-color);
  }

  /* Profile Menu Dropdown */
  .profile-menu {
    position: absolute;
    bottom: 100%;
    right: 0; /* Or left: 0 depending on preference */
    left: 0;
    min-width: 240px;
    background-color: var(--bg-main);
    border-radius: 16px;
    box-shadow: var(--shadow-float);
    padding: 12px 0;
    z-index: 2000;
    overflow: hidden;
    margin-bottom: 12px;
    border: 1px solid var(--border-color);
  }

  .menu-item {
    display: flex;
    align-items: center;
    width: 100%;
    padding: 12px 16px;
    text-align: left;
    background: none;
    border: none;
    font-size: 15px;
    font-weight: 500;
    color: var(--text-main);
    cursor: pointer;
    transition: background-color 0.2s;
  }

  .menu-item:hover {
    background-color: var(--bg-secondary);
  }

  .menu-item.logout {
    color: var(--text-main);
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
    color: var(--text-main);
    transition: background-color 0.2s;
    align-self: center;
  }

  .collapse-toggle:hover {
    background-color: var(--bg-hover);
  }

  /* Responsive adjustments */
  @media (max-width: 768px) {
    .sidebar {
      padding: 0 12px;
      align-items: center;
    }
    .sidebar-container {
       align-items: center;
    }
    .brand, .nav-links li {
       justify-content: center;
    }
    .text, .profile-details, .profile-more-btn, .collapse-toggle {
       display: none;
    }
    .icon-container, .profile-avatar {
       margin-right: 0;
    }
    .profile-card {
        justify-content: center;
        padding: 12px;
    }
  }

  @media (max-width: 640px) {
    .sidebar, .sidebar.collapsed {
      width: 100%;
      height: 53px; /* Fixed height for bottom bar */
      top: auto;
      bottom: 0;
      flex-direction: row;
      border-right: none;
      border-top: 1px solid var(--border-color);
      padding: 0;
      z-index: 2000;
      overflow-y: visible;
    }

    .sidebar-container {
      flex-direction: row;
      align-items: center;
      justify-content: space-around;
      width: 100%;
      height: 100%;
    }

    .brand, .profile-section, .collapse-toggle {
      display: none;
    }

    .nav-links {
      flex-direction: row;
      justify-content: space-around;
      align-items: center;
      width: 100%;
      height: 100%;
    }

    .nav-links li {
       width: auto;
    }

    .nav-item {
      padding: 8px;
      margin: 0;
    }

    .icon-container {
        margin-right: 0;
    }

    /* Floating Action Button (FAB) for Mobile */
    .post-btn {
        display: flex;
        position: fixed;
        bottom: 70px; /* Above bottom nav */
        right: 20px;
        width: 56px;
        height: 56px;
        padding: 0;
        border-radius: 50%;
        margin: 0;
        box-shadow: 0 4px 10px rgba(0,0,0,0.3);
        z-index: 2100;
        align-self: auto;
    }

    .post-text {
        display: none;
    }

    .post-btn .post-icon-container {
        margin-right: 0;
    }
  }
</style>
