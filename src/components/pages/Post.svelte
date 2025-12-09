<script lang="ts">
  // Placeholder for Post page
</script>

<div class="post-page">
  <div class="header">
    <h1>Create Post</h1>
  </div>

  <div class="card editor-container">
    <textarea placeholder="What's happening?"></textarea>
    <div class="actions">
      <button class="btn-primary">Post</button>
    </div>
  </div>
</div>

<style>
  .post-page {
    max-width: 600px;
    margin: 0 auto;
  }

  .editor-container {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  textarea {
    width: 100%;
    height: 150px;
    border: none;
    resize: vertical;
    font-family: inherit;
    font-size: 18px;
    outline: none;
    background: transparent;
    color: var(--text-main);
  }

  .actions {
    display: flex;
    justify-content: flex-end;
    border-top: 1px solid var(--border-color);
    padding-top: 12px;
  }

  .btn-primary {
    background-color: var(--primary-color);
    color: white;
    border-radius: 9999px;
    padding: 8px 24px;
    font-weight: 700;
  }

  .btn-primary:hover {
    background-color: var(--primary-hover);
  }
</style>
