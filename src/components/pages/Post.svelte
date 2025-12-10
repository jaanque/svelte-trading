<script lang="ts">
  import { Image, Smile, Calendar, BarChart2, MapPin, X, Globe, UserPlus } from "lucide-svelte";
  import { userProfile } from "../../lib/authStore";

  export let onClose: () => void = () => {};

  let content = "";
  let isFocused = false;
  let showVisibilityOptions = false;
  let visibility = "Everyone"; // Everyone, Followers

  $: isValid = content.trim().length > 0;
  $: charCount = content.length;
  $: progress = Math.min((charCount / 280) * 100, 100);
  $: isNearLimit = charCount > 260;
  $: isOverLimit = charCount > 280;

  function handlePost() {
    if (!isValid || isOverLimit) return;
    console.log("Posting:", content);
    // Logic to submit post would go here
    content = "";
    onClose();
  }

  function handleBackdropClick(e: MouseEvent) {
    if (e.target === e.currentTarget) {
      onClose();
    }
  }

  function autoResize(e: Event) {
    const target = e.target as HTMLTextAreaElement;
    target.style.height = 'auto';
    target.style.height = target.scrollHeight + 'px';
  }

  function toggleVisibility() {
      showVisibilityOptions = !showVisibilityOptions;
  }

  function setVisibility(type: string) {
      visibility = type;
      showVisibilityOptions = false;
  }
</script>

<!-- Backdrop -->
<!-- svelte-ignore a11y-click-events-have-key-events -->
<!-- svelte-ignore a11y-no-static-element-interactions -->
<div class="modal-overlay" on:click={handleBackdropClick}>
  <div class="modal-content" role="dialog" aria-modal="true">
    <div class="modal-header">
      <button class="close-btn" on:click={onClose} aria-label="Close">
        <X size={20} />
      </button>
      <!-- Removed Drafts button as implied it's not functional yet, cleaner UI -->
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
          <div class="visibility-wrapper">
               <button class="visibility-btn" on:click={toggleVisibility}>
                   {#if visibility === 'Everyone'}
                       <Globe size={14} />
                       <span>Everyone</span>
                   {:else}
                       <UserPlus size={14} />
                       <span>Followers</span>
                   {/if}
                   <!-- Dropdown arrow could go here -->
               </button>
               {#if showVisibilityOptions}
                   <div class="visibility-dropdown">
                       <button class="dropdown-item {visibility === 'Everyone' ? 'selected' : ''}" on:click={() => setVisibility('Everyone')}>
                           <div class="icon-circle"><Globe size={18} /></div>
                           <div class="text">
                               <span class="label">Everyone</span>
                           </div>
                       </button>
                       <button class="dropdown-item {visibility === 'Followers' ? 'selected' : ''}" on:click={() => setVisibility('Followers')}>
                           <div class="icon-circle"><UserPlus size={18} /></div>
                           <div class="text">
                               <span class="label">Followers</span>
                           </div>
                       </button>
                   </div>
                   <!-- Backdrop for dropdown to close on click outside -->
                   <div class="dropdown-backdrop" on:click={() => showVisibilityOptions = false}></div>
               {/if}
          </div>

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

          <!-- Divider line if needed -->
          <div class="divider"></div>

          <div class="reply-permission">
              <Globe size={14} />
              <span>{visibility === 'Everyone' ? 'Everyone can reply' : 'Only followers can reply'}</span>
          </div>

          <div class="toolbar">
              <div class="media-actions">
                  <button class="icon-btn" aria-label="Media" title="Media"><Image size={20} /></button>
                  <button class="icon-btn" aria-label="GIF" title="GIF"><div class="gif-badge">GIF</div></button>
                  <button class="icon-btn" aria-label="Poll" title="Poll"><BarChart2 size={20} transform="rotate(90)" /></button>
                  <button class="icon-btn" aria-label="Emoji" title="Emoji"><Smile size={20} /></button>
                  <button class="icon-btn" aria-label="Schedule" title="Schedule"><Calendar size={20} /></button>
                  <button class="icon-btn disabled" aria-label="Location" title="Location"><MapPin size={20} /></button>
              </div>

              <div class="submit-action">
                  {#if content.length > 0}
                      <div class="progress-indicator">
                          {#if isNearLimit}
                              <span class="count-text {isOverLimit ? 'danger' : 'warning'}">{280 - charCount}</span>
                          {:else}
                              <svg width="24" height="24" viewBox="0 0 24 24" class="circular-chart">
                                <path class="circle-bg" d="M12 2.5 A9.5 9.5 0 1 1 12 21.5 A9.5 9.5 0 1 1 12 2.5" />
                                <path
                                    class="circle"
                                    stroke-dasharray="{progress}, 100"
                                    d="M12 2.5 A9.5 9.5 0 1 1 12 21.5 A9.5 9.5 0 1 1 12 2.5"
                                />
                              </svg>
                          {/if}
                      </div>
                      <div class="separator"></div>
                  {/if}

                  <!-- Add Circle Icon if content > 0? Maybe not needed for this simplified request -->

                  <button class="btn-primary" disabled={!isValid || isOverLimit} on:click={handlePost}>Post</button>
              </div>
          </div>
      </div>
    </div>
  </div>
</div>

<style>
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(91, 112, 131, 0.4);
    backdrop-filter: blur(4px); /* Nice blur effect */
    z-index: 9999;
    display: flex;
    justify-content: center;
    align-items: flex-start;
    padding-top: 5%;
  }

  .modal-content {
    background-color: var(--bg-main);
    width: 100%;
    max-width: 600px;
    border-radius: 16px;
    padding: 0 16px 16px 16px;
    box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
    display: flex;
    flex-direction: column;
    max-height: 90vh;
    overflow-y: auto;
  }

  .modal-header {
    display: flex;
    justify-content: flex-start;
    align-items: center;
    height: 53px;
    position: sticky;
    top: 0;
    background-color: var(--bg-main);
    z-index: 10;
  }

  .close-btn {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: transparent;
    color: var(--text-main);
    cursor: pointer;
    transition: background-color 0.2s;
    margin-left: -8px;
  }

  .close-btn:hover {
    background-color: var(--bg-hover);
  }

  .editor-layout {
    display: flex;
    gap: 12px;
    margin-top: 4px;
  }

  .avatar-column {
      flex-shrink: 0;
      width: 48px;
  }

  .avatar {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    object-fit: cover;
  }

  .avatar-placeholder {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
  }

  .content-column {
      flex-grow: 1;
      display: flex;
      flex-direction: column;
  }

  .visibility-wrapper {
      position: relative;
      margin-bottom: 12px;
  }

  .visibility-btn {
      display: flex;
      align-items: center;
      gap: 4px;
      color: var(--primary-color);
      border: 1px solid var(--border-color);
      background-color: transparent;
      padding: 4px 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .visibility-btn:hover {
      background-color: var(--bg-hover);
  }

  .visibility-dropdown {
      position: absolute;
      top: 100%;
      left: 0;
      background-color: var(--bg-main);
      box-shadow: var(--shadow-md); /* Assuming shadow variable exists, else 0 2px 10px rgba(0,0,0,0.1) */
      border-radius: 12px;
      padding: 8px 0;
      z-index: 20;
      min-width: 200px;
      border: 1px solid var(--border-color);
  }

  .dropdown-backdrop {
      position: fixed;
      inset: 0;
      z-index: 15;
      cursor: default;
  }

  .dropdown-item {
      display: flex;
      align-items: center;
      width: 100%;
      padding: 12px 16px;
      background: none;
      border: none;
      text-align: left;
      cursor: pointer;
      gap: 12px;
  }

  .dropdown-item:hover {
      background-color: var(--bg-hover);
  }

  .dropdown-item .icon-circle {
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background-color: var(--bg-tertiary);
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
  }

  .dropdown-item.selected .icon-circle {
      color: var(--primary-color);
  }

  .dropdown-item .label {
      font-weight: 700;
      font-size: 15px;
      color: var(--text-main);
  }

  .input-area {
      margin-bottom: 8px;
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

  .divider {
      height: 1px;
      background-color: var(--border-color);
      margin-bottom: 12px;
      opacity: 0.5;
  }

  .reply-permission {
      display: flex;
      align-items: center;
      gap: 8px;
      color: var(--primary-color);
      font-weight: 700;
      font-size: 13px;
      margin-bottom: 12px;
      padding: 0 4px;
      cursor: pointer;
  }

  .toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 4px;
  }

  .media-actions {
      display: flex;
      gap: 0px;
      margin-left: -8px; /* Offset padding of first icon */
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
    padding: 8px 20px;
    font-weight: 700;
    font-size: 15px;
    transition: opacity 0.2s, background-color 0.2s;
    border: none;
  }

  .btn-primary:hover:not(:disabled) {
    opacity: 0.9;
  }

  .btn-primary:disabled {
      opacity: 0.5;
      cursor: default;
  }

  /* Progress Ring */
  .progress-indicator {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 24px;
      height: 24px;
  }

  .circular-chart {
      display: block;
      margin: 0 auto;
      max-width: 100%;
      max-height: 100%;
      transform: rotate(-90deg);
  }

  .circle-bg {
      fill: none;
      stroke: var(--border-color);
      stroke-width: 2;
  }

  .circle {
      fill: none;
      stroke: var(--primary-color);
      stroke-width: 2;
      stroke-linecap: round;
      transition: stroke-dasharray 0.3s ease;
  }

  .count-text {
      font-size: 13px;
      font-weight: 500;
  }
  .count-text.warning { color: #eab308; } /* Yellow */
  .count-text.danger { color: #ef4444; } /* Red */

  .separator {
      width: 1px;
      height: 24px;
      background-color: var(--border-color);
  }

  @media (max-width: 640px) {
      .modal-overlay {
          padding-top: 0;
      }
      .modal-content {
          height: 100%;
          max-height: 100%;
          border-radius: 0;
      }
  }
</style>
