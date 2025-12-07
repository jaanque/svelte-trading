<script lang="ts">
  // Navbar logic can go here
</script>

<nav class="navbar">
  <div class="logo">My App</div>
  <ul class="nav-links">
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>

<style>
  .navbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background-color: #333;
    color: white;
    padding: 1rem;
  }

  .logo {
    font-size: 1.5rem;
    font-weight: bold;
  }

  .nav-links {
    list-style: none;
    display: flex;
    gap: 1rem;
    margin: 0;
    padding: 0;
  }

  .nav-links a {
    color: white;
    text-decoration: none;
  }

  .nav-links a:hover {
    text-decoration: underline;
  }
</style>
