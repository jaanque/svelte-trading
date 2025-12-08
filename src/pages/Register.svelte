<script lang="ts">
  import { supabase } from "../lib/supabase";

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
      errorMsg = "Passwords do not match";
      return;
    }

    if (username.length < 3) {
      errorMsg = "Username must be at least 3 characters long";
      return;
    }

    loading = true;
    errorMsg = "";

    // 1. Sign up the user
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
      // 2. Create profile entry (optional, depends on if trigger is used or manual insert)
      // Since we provided meta data, if we have a trigger, it might handle it.
      // But typically we might want to manually insert into a public profiles table if triggers aren't set up.
      // For now, let's assume the user is created and we can redirect.
      // However, the prompt asked for "script sql for tables", implying we need a profiles table.
      // Best practice with Supabase is to use a trigger on auth.users to create a public profile.
      // I will include that in the SQL script.

      loading = false;
      // Ideally show a message to check email if email confirmation is on.
      // Assuming auto-confirm or just redirecting for now.
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
    <h1>Create your account</h1>

    {#if errorMsg}
      <div class="error">{errorMsg}</div>
    {/if}

    <form on:submit|preventDefault={handleRegister}>
      <div class="form-group">
        <label for="name">Name</label>
        <input
          type="text"
          id="name"
          bind:value={name}
          placeholder="Enter your name"
          required
        />
      </div>

      <div class="form-group">
        <label for="username">Username</label>
        <input
          type="text"
          id="username"
          bind:value={username}
          placeholder="Choose a unique username"
          required
        />
      </div>

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
          placeholder="Create a password"
          required
        />
      </div>

      <div class="form-group">
        <label for="confirmPassword">Verify Password</label>
        <input
          type="password"
          id="confirmPassword"
          bind:value={confirmPassword}
          placeholder="Confirm your password"
          required
        />
      </div>

      <button type="submit" disabled={loading}>
        {loading ? "Creating account..." : "Sign up"}
      </button>
    </form>

    <div class="footer">
      <p>Have an account already? <a href="/login" on:click={goToLogin}>Log in</a></p>
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
