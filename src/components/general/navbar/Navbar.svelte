<script lang="ts">
  // Navbar logic can go here
</script>

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
  .navbar {
    background-color: #ffffff;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    position: sticky;
    top: 0;
    z-index: 1000;
    width: 100%;
  }

  .navbar-container {
    max-width: 1200px;
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem 2rem;
  }

  .brand a {
    font-size: 1.5rem;
    font-weight: 700;
    color: #333;
    text-decoration: none;
    letter-spacing: -0.5px;
  }

  .nav-links {
    list-style: none;
    display: flex;
    gap: 2rem;
    margin: 0;
    padding: 0;
  }

  .nav-links a {
    color: #555;
    text-decoration: none;
    font-weight: 500;
    font-size: 1rem;
    transition: color 0.2s ease;
  }

  .nav-links a:hover {
    color: #000;
  }

  .auth-actions {
    display: flex;
    gap: 1rem;
    align-items: center;
  }

  .btn {
    text-decoration: none;
    padding: 0.5rem 1rem;
    border-radius: 6px;
    font-weight: 600;
    font-size: 0.95rem;
    transition: all 0.2s ease;
  }

  .btn-text {
    color: #555;
  }

  .btn-text:hover {
    color: #000;
    background-color: #f5f5f5;
  }

  .btn-primary {
    background-color: #007bff;
    color: white;
    border: 1px solid #007bff;
  }

  .btn-primary:hover {
    background-color: #0056b3;
    border-color: #0056b3;
    box-shadow: 0 2px 4px rgba(0, 123, 255, 0.2);
  }

  /* Responsive adjustments could go here */
  @media (max-width: 768px) {
    .nav-links {
      display: none; /* Mobile menu implementation needed for smaller screens */
    }
  }
</style>
