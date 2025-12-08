<script lang="ts">
  import { supabase } from "../../lib/supabase";
  import { userSession } from "../../lib/authStore";

  export let onNavigate: (path: string) => void = () => {};

  async function handleLogout() {
    await supabase.auth.signOut();
    onNavigate("/login");
  }
</script>

<div class="top-navbar">
  <div class="spacer"></div>
  <div class="auth-buttons">
    {#if !$userSession}
      <button class="btn-login" on:click={() => onNavigate("/login")}>Log in</button>
      <button class="btn-register" on:click={() => onNavigate("/register")}>Sign up</button>
    {:else}
      <button class="btn-logout" on:click={handleLogout}>Log out</button>
    {/if}
  </div>
</div>

<style>
  .top-navbar {
    display: flex;
    justify-content: flex-end; /* Align items to the right */
    align-items: center;
    padding: 12px 16px;
    background-color: rgba(255, 255, 255, 0.85);
    backdrop-filter: blur(12px);
    position: sticky;
    top: 0;
    z-index: 900;
    border-bottom: 1px solid rgb(239, 243, 244);
  }

  .auth-buttons {
    display: flex;
    gap: 12px;
  }

  button {
    padding: 8px 16px;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 14px;
    cursor: pointer;
    transition: background-color 0.2s;
    border: 1px solid transparent;
  }

  .btn-login {
    background-color: transparent;
    color: #0f1419;
    border: 1px solid #cfd9de;
  }

  .btn-login:hover {
    background-color: rgba(15, 20, 25, 0.1);
  }

  .btn-register {
    background-color: #0f1419;
    color: white;
  }

  .btn-register:hover {
    background-color: #272c30;
  }

  .btn-logout {
    background-color: transparent;
    color: #f4212e;
    border: 1px solid #fbdce0;
  }

  .btn-logout:hover {
    background-color: rgba(244, 33, 46, 0.1);
  }
</style>
