<script lang="ts">
  import { supabase } from "../../../lib/supabase";
  import { userSession } from "../../../lib/authStore";

  export let onNavigate: (path: string) => void = () => {};
  export let currentPath = "/";

  $: pageTitle = getPageTitle(currentPath);

  function getPageTitle(path: string) {
    // Remove query params
    const route = path.split('?')[0];

    if (route === "/") return "Inicio";
    if (route === "/markets") return "Mercados";
    if (route === "/messages") return "Mensajes";
    if (route === "/portfolio") return "Portafolio";
    if (route === "/notifications") return "Notificaciones";
    if (route === "/settings") return "Configuración";
    if (route === "/profile") return "Perfil";
    if (route === "/login") return "Iniciar Sesión";
    if (route === "/register") return "Registrarse";
    return "App";
  }

  async function handleLogout() {
    await supabase.auth.signOut();
    onNavigate("/login");
  }
</script>

<div class="top-navbar">
  <div class="page-header">
     <h2>{pageTitle}</h2>
  </div>
  <div class="actions">
    {#if !$userSession}
      <button class="btn-login" on:click={() => onNavigate("/login")}>Iniciar sesión</button>
      <button class="btn-register" on:click={() => onNavigate("/register")}>Registrarse</button>
    {:else}
      <!-- Logged in state: Maybe notifications or just nothing since profile is in sidebar -->
      <!-- We don't really need a logout button here if it's in the sidebar profile menu,
           but keeping it for backup or changing to something else is fine.
           Let's remove it to clean up the interface as requested ("mas ordenado")
           since we added it to the sidebar menu. -->
    {/if}
  </div>
</div>

<style>
  .top-navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 20px;
    background-color: rgba(255, 255, 255, 0.85);
    backdrop-filter: blur(12px);
    -webkit-backdrop-filter: blur(12px);
    position: sticky;
    top: 0;
    z-index: 900;
    border-bottom: 1px solid var(--border-color);
    height: 53px; /* Consistent height */
  }

  .actions {
    display: flex;
    gap: 12px;
    margin-left: auto;
  }

  button {
    padding: 6px 16px;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 14px;
    cursor: pointer;
    transition: background-color 0.2s;
    border: 1px solid transparent;
  }

  .btn-login {
    background-color: transparent;
    color: var(--text-main);
    border: 1px solid var(--border-strong);
  }

  .btn-login:hover {
    background-color: var(--bg-hover);
  }

  .btn-register {
    background-color: var(--text-main);
    color: var(--text-on-primary);
  }

  .btn-register:hover {
    background-color: #272c30;
  }
</style>
