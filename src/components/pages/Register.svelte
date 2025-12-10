<script lang="ts">
  import { supabase } from "../../lib/supabase";
  import logo from "../../assets/svelte.svg";

  let name = "";
  let username = "";
  let email = "";
  let password = "";
  let confirmPassword = "";
  let errorMsg = "";
  let loading = false;

  export let onNavigate: (path: string) => void = () => {};

  async function handleRegister() {
    if (password !== confirmPassword) {
      errorMsg = "Las contraseñas no coinciden";
      return;
    }

    if (username.length < 3) {
      errorMsg = "El nombre de usuario debe tener al menos 3 caracteres";
      return;
    }

    loading = true;
    errorMsg = "";

    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: name,
          username: username,
        },
      },
    });

    if (authError) {
      errorMsg = authError.message;
      loading = false;
      return;
    }

    if (authData.user) {
      loading = false;
      onNavigate("/");
    }
  }

  function goToLogin(e: Event) {
    e.preventDefault();
    onNavigate("/login");
  }
</script>

<div class="auth-container">
  <div class="auth-card">
    <div class="logo-container">
      <img src={logo} alt="Logo" class="logo" />
    </div>
    <h1>Crea tu cuenta</h1>

    {#if errorMsg}
      <div class="error">{errorMsg}</div>
    {/if}

    <form on:submit|preventDefault={handleRegister}>
      <div class="form-group">
        <label for="name">Nombre completo</label>
        <input
          type="text"
          id="name"
          bind:value={name}
          placeholder="Tu nombre"
          required
        />
      </div>

      <div class="form-group">
        <label for="username">Usuario</label>
        <input
          type="text"
          id="username"
          bind:value={username}
          placeholder="Elige un nombre de usuario"
          required
        />
      </div>

      <div class="form-group">
        <label for="email">Correo electrónico</label>
        <input
          type="email"
          id="email"
          bind:value={email}
          placeholder="Tu correo"
          required
        />
      </div>

      <div class="form-group">
        <label for="password">Contraseña</label>
        <input
          type="password"
          id="password"
          bind:value={password}
          placeholder="Crea una contraseña"
          required
        />
      </div>

      <div class="form-group">
        <label for="confirmPassword">Confirmar contraseña</label>
        <input
          type="password"
          id="confirmPassword"
          bind:value={confirmPassword}
          placeholder="Repite tu contraseña"
          required
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? "Creando cuenta..." : "Registrarse"}
      </button>
    </form>

    <div class="footer">
      <p>¿Ya tienes una cuenta? <a href="/login" on:click={goToLogin}>Inicia sesión</a></p>
    </div>
  </div>
</div>

<style>
  .auth-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    background-color: var(--bg-secondary);
    padding: var(--spacing-md);
  }

  .auth-card {
    background: var(--bg-main);
    padding: var(--spacing-xl);
    border-radius: 16px;
    box-shadow: var(--shadow-md);
    border: 1px solid var(--border-color);
    width: 100%;
    max-width: 400px;
    margin: var(--spacing-md) 0;
  }

  .logo-container {
    display: flex;
    justify-content: center;
    margin-bottom: var(--spacing-lg);
  }

  .logo {
    width: 48px;
    height: 48px;
  }

  h1 {
    margin-top: 0;
    margin-bottom: var(--spacing-lg);
    text-align: center;
    color: var(--text-main);
    font-size: var(--font-size-xl);
  }

  .error {
    background-color: rgba(255, 105, 97, 0.1);
    color: var(--danger-color);
    padding: var(--spacing-sm);
    border-radius: 8px;
    margin-bottom: var(--spacing-md);
    font-size: var(--font-size-sm);
    border: 1px solid var(--danger-color);
  }

  .form-group {
    margin-bottom: var(--spacing-md);
  }

  label {
    display: block;
    margin-bottom: var(--spacing-xs);
    font-weight: 600;
    font-size: var(--font-size-sm);
    color: var(--text-main);
  }

  input {
    width: 100%;
    padding: 12px;
    border: 1px solid var(--border-strong);
    border-radius: 8px;
    font-size: var(--font-size-md);
    box-sizing: border-box;
    background-color: var(--bg-main);
    color: var(--text-main);
    transition: all 0.2s ease;
  }

  input:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 3px var(--bg-hover);
  }

  button {
    width: 100%;
    padding: 12px;
    background-color: var(--primary-color);
    color: var(--text-on-primary);
    border: none;
    border-radius: 9999px;
    font-weight: 700;
    font-size: var(--font-size-md);
    cursor: pointer;
    transition: background-color 0.2s;
    margin-top: var(--spacing-sm);
  }

  button:hover {
    background-color: var(--primary-hover);
  }

  button:disabled {
    opacity: 0.7;
    cursor: not-allowed;
  }

  .footer {
    margin-top: var(--spacing-lg);
    text-align: center;
    font-size: var(--font-size-sm);
    color: var(--text-secondary);
  }

  .footer a {
    color: var(--primary-color);
    text-decoration: none;
    font-weight: 600;
  }

  .footer a:hover {
    text-decoration: underline;
  }
</style>
