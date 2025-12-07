<script lang="ts" src="./navbar.ts"></script>

<nav class="navbar">
  <div class="navbar-container">
    <div class="brand">
      <a href="/">MyApp</a>
    </div>

    <ul class="nav-links">
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
      <li><a href="/services">Services</a></li>
      <li><a href="/contact">Contact</a></li>
    </ul>

    <div class="auth-actions">
      <a href="/login" class="btn btn-text">Log in</a>
      <a href="/register" class="btn btn-primary">Sign up</a>
    </div>
  </div>
</nav>

<style>
  @import './navbar.css';
</style>
