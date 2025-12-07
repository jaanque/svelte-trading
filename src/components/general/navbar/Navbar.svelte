<script lang="ts">
  import "./navbar.ts";
  import {
    Home,
    Search,
    Bell,
    Mail,
    SquareTerminal,
    FileText,
    Bookmark,
    Users,
    Zap,
    User,
    MoreHorizontal,
    Feather
  } from "lucide-svelte";
</script>

<nav class="sidebar">
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

    <ul class="nav-links">
      <li>
        <a href="/" class="nav-item">
          <div class="icon-container">
            <Home size={28} strokeWidth={2} />
          </div>
          <span class="text">Home</span>
        </a>
      </li>
      <li>
        <a href="/explore" class="nav-item">
          <div class="icon-container">
            <Search size={28} strokeWidth={2} />
          </div>
          <span class="text">Explore</span>
        </a>
      </li>
      <li>
        <a href="/notifications" class="nav-item">
          <div class="icon-container">
            <div class="badge">20+</div>
            <Bell size={28} strokeWidth={2} />
          </div>
          <span class="text">Notifications</span>
        </a>
      </li>
      <li>
        <a href="/messages" class="nav-item">
          <div class="icon-container">
            <Mail size={28} strokeWidth={2} />
          </div>
          <span class="text">Messages</span>
        </a>
      </li>
      <li>
        <a href="/grok" class="nav-item">
          <div class="icon-container">
            <SquareTerminal size={28} strokeWidth={2} />
          </div>
          <span class="text">Grok</span>
        </a>
      </li>
      <li>
        <a href="/lists" class="nav-item">
          <div class="icon-container">
            <FileText size={28} strokeWidth={2} />
          </div>
          <span class="text">Lists</span>
        </a>
      </li>
      <li>
        <a href="/bookmarks" class="nav-item">
          <div class="icon-container">
            <Bookmark size={28} strokeWidth={2} />
          </div>
          <span class="text">Bookmarks</span>
        </a>
      </li>
      <li>
        <a href="/communities" class="nav-item">
          <div class="icon-container">
            <Users size={28} strokeWidth={2} />
          </div>
          <span class="text">Communities</span>
        </a>
      </li>
      <li>
        <a href="/premium" class="nav-item">
          <div class="icon-container">
            <Zap size={28} strokeWidth={2} />
          </div>
          <span class="text">Premium</span>
        </a>
      </li>
      <li>
        <a href="/profile" class="nav-item">
          <div class="icon-container">
            <User size={28} strokeWidth={2} />
          </div>
          <span class="text">Profile</span>
        </a>
      </li>
      <li>
        <button class="nav-item-button">
          <div class="icon-container">
            <MoreHorizontal size={28} strokeWidth={2} />
          </div>
          <span class="text">More</span>
        </button>
      </li>
    </ul>

    <button class="post-btn">
      <span class="text">Post</span>
      <div class="icon-feather">
        <Feather size={24} color="white" />
      </div>
    </button>
  </div>
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
  }

  .sidebar-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    align-items: flex-start;
    width: 100%;
  }

  /* Brand */
  .brand {
    padding: 4px 0;
    margin-bottom: 4px;
    width: 100%;
    display: flex;
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
    transition: background-color 0.2s;
    cursor: pointer;
    background: none;
    border: none;
    outline: none;
    margin: 8px 0;
  }

  .nav-item:hover,
  .nav-item-button:hover {
    background-color: var(--hover-bg);
  }

  .icon-container {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 20px;
  }

  .text {
    font-size: 20px;
    font-weight: 400;
    line-height: 24px;
    color: #0f1419;
    margin-right: 16px;
    font-family: var(--font-family);
  }

  /* Badge */
  .badge {
    position: absolute;
    top: -6px;
    right: -6px;
    background-color: #1d9bf0;
    color: white;
    font-size: 11px;
    font-weight: 700;
    padding: 1px 4px;
    border-radius: 999px;
    border: 1px solid #fff;
    z-index: 1;
  }

  /* Post Button */
  .post-btn {
    margin-top: 24px;
    background-color: #0f1419;
    color: white;
    border: none;
    border-radius: 9999px;
    height: 56px;
    width: 90%;
    font-size: 18px;
    font-weight: 700;
    cursor: pointer;
    transition: background-color 0.2s;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.08);
  }

  .post-btn:hover {
    background-color: #272c30;
  }

  .post-btn .icon-feather {
    display: none;
  }

  /* Responsive adjustments */
  @media (max-width: 1280px) {
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

    .post-btn {
      width: 56px;
      height: 56px;
      padding: 0;
      min-width: 56px;
      border-radius: 50%;
    }

    .post-btn .text {
      display: none;
    }

    .post-btn .icon-feather {
      display: flex;
      align-items: center;
      justify-content: center;
    }
  }
</style>
