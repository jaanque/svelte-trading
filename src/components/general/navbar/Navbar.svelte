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
  :root {
    --navbar-height: 70px;
    --primary-color: #007bff;
    --hover-bg: #f3f4f6;
    --text-color: #374151;
    --font-family: 'Inter', system-ui, -apple-system, sans-serif;
  }

  .navbar {
    background-color: #ffffff;
    border-bottom: 1px solid #e5e7eb;
    position: sticky;
    top: 0;
    z-index: 1000;
    width: 100%;
    height: var(--navbar-height);
    display: flex;
    align-items: center;
    font-family: var(--font-family);
  }

  .navbar-container {
    width: 100%;
    max-width: 1920px; /* Limit width on ultra-wide screens but keep it spacious */
    margin: 0 auto;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0 2rem; /* Consistent horizontal padding */
  }

  /* Brand / Logo */
  .brand a {
    font-size: 1.5rem;
    font-weight: 800;
    color: #111827;
    text-decoration: none;
    letter-spacing: -0.025em;
    padding: 0.5rem;
    border-radius: 0.5rem;
    transition: background-color 0.2s ease;
  }

  .brand a:hover {
    background-color: var(--hover-bg);
  }

  /* Navigation Links */
  .nav-links {
    list-style: none;
    display: flex;
    gap: 0.5rem; /* Space between the "boxes" */
    margin: 0;
    padding: 0;
  }

  .nav-links a {
    color: var(--text-color);
    text-decoration: none;
    font-weight: 500;
    font-size: 0.95rem;
    padding: 0.5rem 1rem; /* Create the box area */
    border-radius: 0.5rem;
    transition: all 0.2s ease;
    display: block;
  }

  .nav-links a:hover {
    background-color: var(--hover-bg);
    color: #111827;
  }

  /* Auth Buttons */
  .auth-actions {
    display: flex;
    gap: 0.75rem;
    align-items: center;
  }

  .btn {
    text-decoration: none;
    padding: 0.5rem 1.25rem;
    border-radius: 0.5rem;
    font-weight: 600;
    font-size: 0.9rem;
    transition: all 0.2s ease;
    display: inline-flex;
    align-items: center;
    justify-content: center;
  }

  .btn-text {
    color: var(--text-color);
  }

  .btn-text:hover {
    background-color: var(--hover-bg);
    color: #111827;
  }

  .btn-primary {
    background-color: #111827; /* Darker, more professional black/grey */
    color: white;
  }

  .btn-primary:hover {
    background-color: #000000;
    transform: translateY(-1px);
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  }

  /* Responsive Behavior */
  @media (max-width: 768px) {
    .nav-links {
      display: none; /* In a real app, this would be a hamburger menu */
    }

    .navbar-container {
      padding: 0 1rem;
    }
  }
</style>
