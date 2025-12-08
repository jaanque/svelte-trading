<script lang="ts">
  import { supabase } from "../lib/supabase";

  let email = "";
  let password = "";
  let errorMsg = "";
  let loading = false;

  export let onNavigate: (path: string) => void = () => {};

  async function handleLogin() {
    loading = true;
    errorMsg = "";

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      errorMsg = error.message;
      loading = false;
    } else {
      loading = false;
      onNavigate("/");
    }
  }

  function goToRegister(e: Event) {
    e.preventDefault();
    onNavigate("/register");
  }
</script>

<div class="auth-container">
  <div class="auth-card">
    <h1>Log in</h1>

    {#if errorMsg}
      <div class="error">{errorMsg}</div>
    {/if}

    <form on:submit|preventDefault={handleLogin}>
      <div class="form-group">
        <label for="email">Email</label>
        <input
          type="email"
          id="email"
          bind:value={email}
          placeholder="Enter your email"
          required
        />
      </div>

      <div class="form-group">
        <label for="password">Password</label>
        <input
          type="password"
          id="password"
          bind:value={password}
          placeholder="Enter your password"
          required
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? "Logging in..." : "Log in"}
      </button>
    </form>

    <div class="footer">
      <p>Don't have an account? <a href="/register" on:click={goToRegister}>Sign up</a></p>
    </div>
  </div>
</div>

<style>
  .auth-container {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 100vh;
    background-color: #f7f9f9;
  }

  .auth-card {
    background: white;
    padding: 32px;
    border-radius: 16px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    width: 100%;
    max-width: 400px;
  }

  h1 {
    margin-top: 0;
    margin-bottom: 24px;
    text-align: center;
    color: #0f1419;
  }

  .error {
    background-color: rgba(244, 33, 46, 0.1);
    color: #f4212e;
    padding: 12px;
    border-radius: 8px;
    margin-bottom: 16px;
    font-size: 14px;
  }

  .form-group {
    margin-bottom: 20px;
  }

  label {
    display: block;
    margin-bottom: 8px;
    font-weight: 600;
    font-size: 14px;
    color: #0f1419;
  }

  input {
    width: 100%;
    padding: 12px;
    border: 1px solid #cfd9de;
    border-radius: 4px;
    font-size: 16px;
    box-sizing: border-box;
    transition: border-color 0.2s;
  }

  input:focus {
    outline: none;
    border-color: #1d9bf0;
    box-shadow: 0 0 0 1px #1d9bf0;
  }

  button {
    width: 100%;
    padding: 14px;
    background-color: #0f1419;
    color: white;
    border: none;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 16px;
    cursor: pointer;
    transition: background-color 0.2s;
  }

  button:hover {
    background-color: #272c30;
  }

  button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .footer {
    margin-top: 24px;
    text-align: center;
    font-size: 14px;
    color: #536471;
  }

  .footer a {
    color: #1d9bf0;
    text-decoration: none;
    font-weight: 600;
  }

  .footer a:hover {
    text-decoration: underline;
  }
</style>
