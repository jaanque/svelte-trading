<script lang="ts">
  import { Image, Smile, Calendar, BarChart2, MapPin, X } from "lucide-svelte";
  import { userProfile } from "../../lib/authStore";

  let content = "";
  let isFocused = false;

  $: isValid = content.trim().length > 0;

  function handlePost() {
    if (!isValid) return;
    console.log("Posting:", content);
    // Logic to submit post would go here
    content = "";
  }

  function autoResize(e: Event) {
    const target = e.target as HTMLTextAreaElement;
    target.style.height = 'auto';
    target.style.height = target.scrollHeight + 'px';
  }
</script>

<div class="post-page">
  <div class="header">
    <div class="close-btn">
       <a href="/" aria-label="Close"><X size={24} /></a>
    </div>
    <div class="actions-header">
       <button class="btn-text">Drafts</button>
    </div>
  </div>

  <div class="editor-layout">
    <div class="avatar-column">
      {#if $userProfile}
        <img
          src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
          alt="Profile"
          class="avatar"
        />
      {:else}
        <div class="avatar-placeholder"></div>
      {/if}
    </div>

    <div class="content-column">
        <div class="input-area">
            <textarea
                placeholder="What is happening?!"
                bind:value={content}
                on:input={autoResize}
                on:focus={() => isFocused = true}
                on:blur={() => isFocused = false}
                rows="3"
            ></textarea>
        </div>

        <div class="visibility-control">
            <span class="globe-icon">🌎</span>
            <span class="visibility-text">Everyone can reply</span>
        </div>

        <div class="toolbar">
            <div class="media-actions">
                <button class="icon-btn" aria-label="Media"><Image size={20} /></button>
                <button class="icon-btn" aria-label="GIF"><div class="gif-badge">GIF</div></button>
                <button class="icon-btn" aria-label="Poll"><BarChart2 size={20} transform="rotate(90)" /></button>
                <button class="icon-btn" aria-label="Emoji"><Smile size={20} /></button>
                <button class="icon-btn" aria-label="Schedule"><Calendar size={20} /></button>
                <button class="icon-btn disabled" aria-label="Location"><MapPin size={20} /></button>
            </div>

            <div class="submit-action">
                {#if content.length > 0}
                    <div class="character-count-ring">
                        <!-- Simplified visual for progress -->
                        <div class="ring-circle"></div>
                    </div>
                {/if}
                <button class="btn-primary" disabled={!isValid} on:click={handlePost}>Post</button>
            </div>
        </div>
    </div>
  </div>
</div>

<style>
  .post-page {
    max-width: 600px;
    margin: 0 auto;
    padding: 0 16px;
    min-height: 100vh;
  }

  .header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 0;
    margin-bottom: 12px;
  }

  .close-btn a {
      color: var(--text-main);
      display: flex;
      align-items: center;
      justify-content: center;
      width: 36px;
      height: 36px;
      border-radius: 50%;
      transition: background-color 0.2s;
  }

  .close-btn a:hover {
      background-color: var(--bg-hover);
      text-decoration: none;
  }

  .btn-text {
      background: none;
      color: var(--primary-color);
      font-weight: 700;
      font-size: 14px;
      padding: 8px 16px;
      border-radius: 9999px;
  }

  .btn-text:hover {
      background-color: var(--bg-hover);
  }

  .editor-layout {
    display: flex;
    gap: 12px;
  }

  .avatar-column {
      flex-shrink: 0;
      width: 48px;
  }

  .avatar {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    object-fit: cover;
  }

  .avatar-placeholder {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
  }

  .content-column {
      flex-grow: 1;
      display: flex;
      flex-direction: column;
  }

  .input-area {
      margin-bottom: 12px;
  }

  textarea {
    width: 100%;
    min-height: 120px;
    border: none;
    resize: none;
    font-family: inherit;
    font-size: 20px;
    line-height: 24px;
    outline: none;
    background: transparent;
    color: var(--text-main);
    padding: 12px 0;
  }

  textarea::placeholder {
      color: var(--text-secondary);
  }

  .visibility-control {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 0;
      border-bottom: 1px solid var(--border-color);
      margin-bottom: 12px;
      color: var(--primary-color);
      font-weight: 700;
      font-size: 14px;
      cursor: pointer;
  }

  .visibility-control:hover {
      background-color: rgba(29, 155, 240, 0.05); /* Very light highlight */
      border-radius: 12px;
      padding-left: 8px;
      margin-left: -8px;
      width: fit-content;
      border-bottom-color: transparent;
  }

  .toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 4px;
  }

  .media-actions {
      display: flex;
      gap: 2px;
  }

  .icon-btn {
      width: 36px;
      height: 36px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 50%;
      background: none;
      color: var(--primary-color);
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .icon-btn:hover {
      background-color: var(--bg-hover);
  }

  .icon-btn.disabled {
      opacity: 0.5;
      cursor: default;
  }

  .icon-btn.disabled:hover {
      background: none;
  }

  .gif-badge {
      border: 2px solid currentColor;
      border-radius: 4px;
      font-size: 9px;
      font-weight: 800;
      padding: 1px 2px;
  }

  .submit-action {
      display: flex;
      align-items: center;
      gap: 12px;
  }

  .btn-primary {
    background-color: var(--primary-color);
    color: white;
    border-radius: 9999px;
    padding: 8px 16px;
    font-weight: 700;
    font-size: 15px;
    transition: opacity 0.2s, background-color 0.2s;
  }

  .btn-primary:hover:not(:disabled) {
    background-color: var(--primary-hover);
  }

  .btn-primary:disabled {
      opacity: 0.5;
      cursor: default;
  }

  .ring-circle {
      width: 20px;
      height: 20px;
      border: 2px solid var(--primary-color);
      border-radius: 50%;
      border-top-color: transparent; /* Indicate progress roughly */
      transform: rotate(45deg);
  }
</style>
