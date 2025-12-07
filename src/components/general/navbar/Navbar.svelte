<script lang="ts">
  import "./navbar.ts";
</script>

<nav class="sidebar">
  <div class="sidebar-container">
    <div class="brand">
      <a href="/" aria-label="Home">
        <!-- X logo -->
        <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
          ><g
            ><path
              d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
            ></path></g
          ></svg
        >
      </a>
    </div>

    <ul class="nav-links">
      <li>
        <a href="/" class="nav-item">
          <div class="icon-container">
            <!-- Filled Home Icon -->
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g><path d="M12 2L2 12h3v8h6v-6h2v6h6v-8h3L12 2z"></path></g
              ></svg
            >
          </div>
          <span class="text" style="font-weight: 700;">Home</span>
        </a>
      </li>
      <li>
        <a href="/explore" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M10.25 3.75c-3.59 0-6.5 2.91-6.5 6.5s2.91 6.5 6.5 6.5c1.795 0 3.419-.726 4.596-1.904 1.178-1.177 1.904-2.801 1.904-4.596 0-3.59-2.91-6.5-6.5-6.5zm-8.5 6.5c0-4.694 3.806-8.5 8.5-8.5s8.5 3.806 8.5 8.5c0 1.986-.682 3.815-1.824 5.262l4.781 4.781-1.414 1.414-4.781-4.781c-1.447 1.142-3.276 1.824-5.262 1.824-4.694 0-8.5-3.806-8.5-8.5z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Explore</span>
        </a>
      </li>
      <li>
        <a href="/notifications" class="nav-item">
          <div class="icon-container">
            <div class="badge">20+</div>
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M21.697 16.468c-.02-.016-2.14-1.64-2.103-6.03.02-2.532-.812-4.982-2.347-6.888-1.515-1.88-3.61-2.97-5.974-3.088-.164-.007-.324-.007-.487-.007H10.5c-4.113 0-7.48 3.322-7.533 7.427-.04 2.977-1.272 5.09-2.455 6.442-.647.74-1.077 1.34-1.22 1.936-.145.6.012 1.167.43 1.554.405.373.968.498 1.545.498h18.266c.556 0 1.1-.132 1.492-.51.4-.39.553-.946.42-1.54-.14-.62-.596-1.252-1.242-1.994zM7.223 20.28c-.52 0-.966-.088-1.246-.35-.29-.272-.373-.59-.286-.948.1-.42.662-1.196 1.458-2.106 1.29-1.472 2.82-3.922 2.864-7.4.04-3.02 2.517-5.467 5.56-5.467.11 0 .22 0 .33.006 1.77.087 3.344.9 4.474 2.304 1.145 1.42 1.764 3.25 1.75 5.15-.027 3.354 1.56 4.545 1.574 4.557.708.814 1.13 1.488 1.216 1.86.06.27-.006.526-.2.715-.2.193-.5.28-.817.28H7.223zm4.777 3.22c1.783 0 3.37-1.042 4.098-2.5h-8.2c.73 1.458 2.316 2.5 4.102 2.5z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Notifications</span>
        </a>
      </li>
      <li>
        <a href="/messages" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M1.998 5.5c0-1.38 1.119-2.5 2.5-2.5h15.004c1.381 0 2.502 1.12 2.502 2.5v13c0 1.38-1.12 2.5-2.502 2.5H4.498c-1.381 0-2.5-1.12-2.5-2.5v-13zm2.5-1c-.552 0-1 .448-1 1v.79l8.502 5.176 8.502-5.176V5.5c0-.552-.448-1-1-1H4.498zm15.504 14V8.04l-7.986 4.86-.516.314-.516-.315-7.986-4.86v11.46c0 .553.448 1 1 1h15.004c.552 0 1-.447 1-1z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Messages</span>
        </a>
      </li>
      <li>
        <a href="/grok" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M2.25 12c0-5.385 4.365-9.75 9.75-9.75s9.75 4.365 9.75 9.75-4.365 9.75-9.75 9.75S2.25 17.385 2.25 12zm2 0c0 4.28 3.47 7.75 7.75 7.75 2.54 0 4.797-1.226 6.18-3.136L7.114 7.614C5.204 8.997 4.25 11.21 4.25 12zm7.75-7.75c-2.54 0-4.797 1.226-6.18 3.136l11.066 11.05c1.91-1.383 2.864-3.64 2.864-6.436 0-4.28-3.47-7.75-7.75-7.75z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Grok</span>
        </a>
      </li>
      <li>
        <a href="/lists" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M3 4.5C3 3.12 4.12 2 5.5 2h13C19.88 2 21 3.12 21 4.5v15c0 1.38-1.12 2.5-2.5 2.5h-13C4.12 22 3 20.88 3 19.5v-15zM5.5 4c-.28 0-.5.22-.5.5v15c0 .28.22.5.5.5h13c.28 0 .5-.22.5-.5v-15c0-.28-.22-.5-.5-.5h-13zM16 10H8V8h8v2zm-8 2h8v2H8v-2z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Lists</span>
        </a>
      </li>
      <li>
        <a href="/bookmarks" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M4 4.5C4 3.12 5.119 2 6.5 2h11C18.881 2 20 3.12 20 4.5v18.44l-8-5.71-8 5.71V4.5zM6.5 4c-.276 0-.5.22-.5.5v14.56l6-4.29 6 4.29V4.5c0-.28-.224-.5-.5-.5h-11z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Bookmarks</span>
        </a>
      </li>
      <li>
        <a href="/communities" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M2.5 12c0-5.247 4.253-9.5 9.5-9.5s9.5 4.253 9.5 9.5-4.253 9.5-9.5 9.5-9.5-4.253-9.5-9.5zm9.5-7.5c-4.142 0-7.5 3.358-7.5 7.5s3.358 7.5 7.5 7.5 7.5-3.358 7.5-7.5-3.358-7.5-7.5-7.5zm5.5 14h-1.63c-.808-1.57-2.315-2.5-3.87-2.5s-3.062.93-3.87 2.5H6.5c-.868 0-1.69-.378-2.26-1.042C3.127 15.938 2 13.792 2 12c0-5.523 4.477-10 10-10s10 4.477 10 10c0 1.793-1.127 3.938-2.24 5.458-.57.664-1.392 1.042-2.26 1.042zM12 7c-1.657 0-3 1.343-3 3s1.343 3 3 3 3-1.343 3-3-1.343-3-3-3z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Communities</span>
        </a>
      </li>
      <li>
        <a href="/premium" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Premium</span>
        </a>
      </li>
      <li>
        <a href="/profile" class="nav-item">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M5.651 19h12.698c-.337-4.429-3.466-8-7.349-8-3.883 0-7.012 3.571-7.349 8zM12 3c2.21 0 4 1.79 4 4s-1.79 4-4 4-4-1.79-4-4 1.79-4 4-4zm-9 16c0-5.523 4.477-10 10-10s10 4.477 10 10H3z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">Profile</span>
        </a>
      </li>
      <li>
        <button class="nav-item-button">
          <div class="icon-container">
            <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
              ><g
                ><path
                  d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-5 11c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm5 0c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm5 0c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2z"
                ></path></g
              ></svg
            >
          </div>
          <span class="text">More</span>
        </button>
      </li>
    </ul>

    <button class="post-btn">
      <span class="text">Post</span>
      <div class="icon-feather">
        <svg viewBox="0 0 24 24" aria-hidden="true" class="icon"
          ><g
            ><path
              d="M23 3c-6.62-.1-10.38 2.421-13.05 6.03C7.29 12.61 6 17.331 6 22h2c0-1.007.07-2.012.19-3H12c4.1 0 7.48-3.082 7.94-7.054C22.79 10.147 23.17 6.359 23 3zm-7 8h-1.5v2H16c.63-.016 1.2-.08 1.72-.188C16.95 15.24 14.68 17 12 17H8.55c.57-2.512 1.57-4.851 3-6.78 2.16-2.912 5.29-4.911 9.45-5.187C20.95 8.079 19.9 11 16 11zM4 9V6H1V4h3V1h2v3h3v2H6v3H4z"
            ></path></g
          ></svg
        >
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
    --icon-size: 26.25px;
  }

  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    height: 100vh;
    width: var(--sidebar-width);
    display: flex;
    flex-direction: column;
    padding: 0 12px;
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
    padding: 2px 0;
    margin-bottom: 2px;
    width: 100%;
    display: flex;
  }

  .brand a {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 52px;
    height: 52px;
    border-radius: 50%;
    transition: background-color 0.2s;
    color: var(--text-color);
  }

  .brand a:hover {
    background-color: var(--hover-bg);
  }

  .brand svg {
    height: 30px;
    width: 30px;
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
    padding: 12px;
    border-radius: 9999px;
    /* Pill shape */
    text-decoration: none;
    color: var(--text-color);
    transition: background-color 0.2s;
    cursor: pointer;
    background: none;
    border: none;
    outline: none;
    margin: 4px 0;
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

  .icon {
    width: var(--icon-size);
    height: var(--icon-size);
    fill: currentColor;
  }

  .text {
    font-size: 20px;
    font-weight: 400;
    line-height: 24px;
    color: #0f1419;
    margin-right: 16px;
    font-family: var(--font-family);
  }

  /* Bold text for active state if needed, here generally regular */
  .nav-item .text,
  .nav-item-button .text {
    font-weight: 400;
    /* As per image, looks regular/medium */
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
  }

  /* Post Button */
  .post-btn {
    margin-top: 16px;
    background-color: #0f1419;
    /* Dark black */
    color: white;
    border: none;
    border-radius: 9999px;
    height: 52px;
    width: 90%;
    /* Occupy most width */
    font-size: 17px;
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

    .text {
      display: none;
    }

    .icon-container {
      margin-right: 0;
    }

    .post-btn {
      width: 52px;
      height: 52px;
      padding: 0;
      min-width: 52px;
    }

    .post-btn .text {
      display: none;
    }

    .post-btn .icon-feather {
      display: flex;
      fill: white;
      width: 24px;
      height: 24px;
    }

    .post-btn .icon-feather svg {
      width: 24px;
      height: 24px;
      fill: white;
    }
  }

  @media (prefers-color-scheme: dark) {
    /* If system is dark, maybe invert, but the user image is light mode */
    /* Keeping it light mode as per user request image */
  }
</style>
