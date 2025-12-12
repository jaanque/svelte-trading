<script lang="ts">
  import { onMount } from "svelte";
  import { userProfile } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import { ArrowLeft, MessageCircle, Heart, Share2, MoreHorizontal, Send, Loader2 } from "lucide-svelte";
  import { formatMessage } from "../../lib/utils";

  export let postId: string;
  export let onNavigate: (path: string) => void;

  let post: any = null;
  let comments: any[] = [];
  let loading = true;
  let error: string | null = null;
  let newCommentText = "";
  let submittingComment = false;

  async function loadPostAndComments() {
    loading = true;
    error = null;

    try {
      // Fetch Post
      const { data: postData, error: postError } = await supabase
        .from("posts")
        .select(`
          *,
          user:profiles!user_id (*)
        `)
        .eq("id", postId)
        .single();

      if (postError) throw postError;
      post = postData;

      // Fetch Comments
      const { data: commentsData, error: commentsError } = await supabase
        .from("comments")
        .select(`
          *,
          user:profiles!user_id (*)
        `)
        .eq("post_id", postId)
        .order("created_at", { ascending: true });

      if (commentsError) throw commentsError;
      comments = commentsData || [];

    } catch (err: any) {
      console.error("Error fetching details:", err);
      error = "Failed to load post.";
    } finally {
      loading = false;
    }
  }

  async function submitComment() {
    if (!newCommentText.trim() || !$userProfile) return;

    submittingComment = true;
    try {
      const { data, error } = await supabase
        .from("comments")
        .insert({
          post_id: postId,
          user_id: $userProfile.id,
          content: newCommentText.trim()
        })
        .select(`*, user:profiles!user_id (*)`)
        .single();

      if (error) throw error;

      comments = [...comments, data];
      newCommentText = "";

      // Update local post state slightly to reflect reply count if desired (though trigger handles DB)
      if (post) {
          post.replies_count = (post.replies_count || 0) + 1;
      }

    } catch (err) {
      console.error("Error submitting comment:", err);
      alert("Failed to reply.");
    } finally {
      submittingComment = false;
    }
  }

  function formatTimeDetailed(iso: string) {
      const date = new Date(iso);
      return date.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) + ' · ' + date.toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' });
  }

  function formatTimeShort(iso: string) {
      const date = new Date(iso);
      const now = new Date();
      const diffMins = Math.floor((now.getTime() - date.getTime()) / 60000);
      if (diffMins < 60) return `${diffMins}m`;
      const diffHours = Math.floor(diffMins / 60);
      if (diffHours < 24) return `${diffHours}h`;
      return date.toLocaleDateString();
  }

  onMount(() => {
    if (postId) {
        loadPostAndComments();
    }
  });
</script>

<div class="post-details-page">
  <!-- Clean, soft header -->
  <div class="sticky-header">
    <div class="header-content">
      <button class="back-btn" on:click={() => window.history.back()} aria-label="Go back">
        <ArrowLeft size={24} />
      </button>
      <h3>Thread</h3>
    </div>
  </div>

  {#if loading}
    <div class="center-content">
      <Loader2 class="animate-spin" size={40} color="var(--primary-color)" />
    </div>
  {:else if error}
    <div class="center-content">
      <div class="error-container">
        <h2>Post not found</h2>
        <p>This post might have been deleted or is unavailable.</p>
        <button class="btn-secondary" on:click={() => onNavigate('/')}>Return Home</button>
      </div>
    </div>
  {:else if post}
    <!-- Main Card Container for "Blanda" feel -->
    <div class="content-container">

      <!-- The Main Post -->
      <article class="main-post-card">
        <div class="post-header">
          <div class="avatar-wrapper">
             <img
               src={post.user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${post.user.username}`}
               alt={post.user.username}
               class="avatar"
             />
          </div>
          <div class="user-info">
             <span class="fullname">{post.user.full_name || post.user.username}</span>
             <span class="username">${post.user.username.toUpperCase()}</span>
          </div>
          <button class="more-btn"><MoreHorizontal size={20} /></button>
        </div>

        <div class="post-body">
           <p class="post-content">{@html formatMessage(post.content)}</p>
        </div>

        <div class="post-meta">
           <span class="time">{formatTimeDetailed(post.created_at)}</span>
        </div>

        <div class="post-stats">
           {#if (post.replies_count || 0) > 0}
             <div class="stat"><strong>{post.replies_count}</strong> <span class="label">Replies</span></div>
           {/if}
           {#if (post.likes_count || 0) > 0}
             <div class="stat"><strong>{post.likes_count}</strong> <span class="label">Likes</span></div>
           {/if}
        </div>

        <div class="post-actions">
           <button class="action-btn" title="Reply"><MessageCircle size={22} /></button>
           <button class="action-btn" title="Repost"><Share2 size={22} /></button>
           <button class="action-btn" title="Like"><Heart size={22} /></button>
        </div>
      </article>

      <!-- Soft Reply Input Area -->
      <div class="reply-section">
         {#if $userProfile}
           <div class="reply-card">
              <img
                 src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
                 alt=""
                 class="current-avatar"
              />
              <div class="input-area">
                 <textarea
                    placeholder="Post your reply..."
                    bind:value={newCommentText}
                    rows="1"
                    on:input={(e) => {
                        const target = e.target as HTMLTextAreaElement;
                        target.style.height = 'auto';
                        target.style.height = target.scrollHeight + 'px';
                    }}
                 ></textarea>
                 <div class="input-actions">
                    <button class="reply-btn" disabled={!newCommentText.trim() || submittingComment} on:click={submitComment}>
                       {#if submittingComment}
                           <Loader2 class="animate-spin" size={18} />
                       {:else}
                           <Send size={18} class="send-icon" /> Reply
                       {/if}
                    </button>
                 </div>
              </div>
           </div>
         {:else}
           <div class="guest-reply-card">
              <p>Join the conversation</p>
              <a href="/login" class="btn-primary-soft" on:click|preventDefault={() => onNavigate('/login')}>Log in</a>
           </div>
         {/if}
      </div>

      <!-- Comments List -->
      <div class="comments-list">
         {#each comments as comment}
            <div class="comment-card">
               <div class="comment-sidebar">
                  <img
                     src={comment.user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${comment.user.username}`}
                     alt={comment.user.username}
                     class="comment-avatar"
                  />
                  <!-- Connector line could go here if threaded -->
               </div>
               <div class="comment-main">
                  <div class="comment-header">
                     <span class="name">{comment.user.full_name || comment.user.username}</span>
                     <span class="handle">${comment.user.username.toUpperCase()}</span>
                     <span class="dot">·</span>
                     <span class="time">{formatTimeShort(comment.created_at)}</span>
                  </div>
                  <div class="comment-text">{@html formatMessage(comment.content)}</div>
                  <div class="comment-footer">
                      <button class="mini-action-btn"><MessageCircle size={18} /></button>
                      <button class="mini-action-btn"><Heart size={18} /></button>
                  </div>
               </div>
            </div>
         {/each}
      </div>
    </div>
  {/if}
</div>

<style>
  /* Page Layout */
  .post-details-page {
    width: 100%;
    min-height: 100vh;
    background-color: var(--bg-main);
    display: flex;
    flex-direction: column;
    padding-bottom: 80px;
  }

  .content-container {
    max-width: 680px; /* Optimal reading width */
    margin: 0 auto;
    width: 100%;
    padding: 0 16px;
    box-sizing: border-box;
  }

  /* Soft Header */
  .sticky-header {
      position: sticky;
      top: 0;
      background: rgba(250, 249, 246, 0.95); /* Matches bg-main but transparent */
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      z-index: 100;
      height: 64px;
      display: flex;
      align-items: center;
      border-bottom: 1px solid transparent; /* Removed harsh border */
      box-shadow: 0 4px 20px rgba(0,0,0,0.02); /* Soft shadow instead */
      margin-bottom: 12px;
  }

  .header-content {
      display: flex;
      align-items: center;
      gap: 24px;
      max-width: 680px;
      margin: 0 auto;
      width: 100%;
      padding: 0 16px;
  }

  .header-content h3 {
      margin: 0;
      font-size: 20px;
      font-weight: 800;
      color: var(--text-main);
  }

  .back-btn {
      background: var(--bg-secondary);
      border: none;
      cursor: pointer;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
      transition: all 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
  }
  .back-btn:hover {
      background-color: var(--bg-tertiary);
      transform: scale(1.05);
  }

  .center-content {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 50vh;
      text-align: center;
  }

  /* Main Post Card - "Blanda" & "Acolchada" */
  .main-post-card {
      background: white; /* Explicit white for card pop against cream bg */
      border-radius: 24px;
      padding: 24px;
      box-shadow: 0 8px 32px rgba(119, 158, 203, 0.08); /* Soft blue-ish shadow */
      margin-bottom: 24px;
      border: 1px solid rgba(255,255,255,0.5);
      animation: fadeIn 0.4s ease-out;
  }

  .post-header {
      display: flex;
      gap: 16px;
      align-items: flex-start;
      margin-bottom: 20px;
  }

  .avatar {
      width: 56px;
      height: 56px;
      border-radius: 20px; /* Squircle/Rounded feel */
      object-fit: cover;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  }

  .user-info {
      display: flex;
      flex-direction: column;
      flex: 1;
      justify-content: center;
      height: 56px;
  }

  .fullname {
      font-weight: 800;
      font-size: 18px;
      color: var(--text-main);
      line-height: 1.2;
  }

  .username {
      color: var(--text-secondary);
      font-size: 15px;
      font-weight: 500;
  }

  .more-btn {
      background: transparent;
      border: none;
      color: var(--text-tertiary);
      cursor: pointer;
      padding: 8px;
      border-radius: 50%;
      transition: background-color 0.2s;
  }
  .more-btn:hover { background-color: var(--bg-hover); color: var(--text-main); }

  .post-content {
      font-size: 20px;
      line-height: 1.6;
      color: var(--text-main);
      margin: 0 0 24px 0;
      white-space: pre-wrap;
      font-weight: 400;
  }

  .post-meta {
      color: var(--text-secondary);
      font-size: 15px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--bg-tertiary);
      margin-bottom: 16px;
  }

  .post-stats {
      display: flex;
      gap: 24px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--bg-tertiary);
      margin-bottom: 16px;
  }

  .stat { font-size: 15px; }
  .stat strong { color: var(--text-main); font-weight: 700; }
  .stat .label { color: var(--text-secondary); }

  .post-actions {
      display: flex;
      justify-content: space-between; /* Spread evenly */
      padding: 4px 12px;
  }

  .action-btn {
      background: transparent;
      border: none;
      color: var(--text-secondary);
      cursor: pointer;
      padding: 12px;
      border-radius: 20px;
      transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1); /* Bouncy hover */
      display: flex;
      align-items: center;
      justify-content: center;
  }
  .action-btn:hover {
      background-color: var(--bg-hover);
      color: var(--primary-color);
      transform: translateY(-2px);
  }

  /* Reply Section - "Bubble" Style */
  .reply-section {
      margin-bottom: 32px;
  }

  .reply-card {
      background: white;
      border-radius: 24px;
      padding: 20px;
      display: flex;
      gap: 16px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.03);
      border: 1px solid var(--bg-tertiary);
  }

  .current-avatar {
      width: 44px;
      height: 44px;
      border-radius: 16px;
  }

  .input-area {
      flex: 1;
      display: flex;
      flex-direction: column;
  }

  textarea {
      width: 100%;
      border: none;
      background: transparent;
      font-size: 16px;
      resize: none;
      outline: none;
      color: var(--text-main);
      font-family: inherit;
      min-height: 40px;
      margin-bottom: 12px;
  }
  textarea::placeholder { color: var(--text-tertiary); }

  .input-actions {
      display: flex;
      justify-content: flex-end;
  }

  .reply-btn {
      background-color: var(--primary-color);
      color: white;
      border: none;
      padding: 10px 24px;
      border-radius: 99px;
      font-weight: 700;
      font-size: 15px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s;
      box-shadow: 0 4px 12px rgba(119, 158, 203, 0.3);
  }
  .reply-btn:hover:not(:disabled) {
      background-color: var(--primary-hover);
      transform: translateY(-1px);
      box-shadow: 0 6px 16px rgba(119, 158, 203, 0.4);
  }
  .reply-btn:disabled {
      opacity: 0.5;
      cursor: default;
      box-shadow: none;
  }

  .guest-reply-card {
      background: var(--bg-secondary);
      border-radius: 20px;
      padding: 24px;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
  }
  .btn-primary-soft {
      background-color: var(--primary-color);
      color: white;
      padding: 10px 24px;
      border-radius: 99px;
      text-decoration: none;
      font-weight: 700;
  }

  /* Comments List */
  .comments-list {
      display: flex;
      flex-direction: column;
      gap: 16px;
  }

  .comment-card {
      background: white;
      border-radius: 20px;
      padding: 20px;
      display: flex;
      gap: 16px;
      transition: transform 0.2s;
      border: 1px solid transparent;
  }

  /* Minimal separator or just spacing - opting for spacing for "soft" feel */
  /* If we want card style for comments too */
  .comment-card {
      box-shadow: 0 2px 8px rgba(0,0,0,0.02);
  }
  .comment-card:hover {
      background-color: #fdfdfd;
      border-color: var(--bg-tertiary);
  }

  .comment-avatar {
      width: 44px;
      height: 44px;
      border-radius: 16px;
      object-fit: cover;
  }

  .comment-main {
      flex: 1;
  }

  .comment-header {
      display: flex;
      gap: 8px;
      align-items: baseline;
      margin-bottom: 6px;
  }

  .comment-header .name { font-weight: 700; color: var(--text-main); font-size: 15px; }
  .comment-header .handle { color: var(--text-secondary); font-size: 14px; }
  .comment-header .dot { color: var(--text-tertiary); font-size: 12px; }
  .comment-header .time { color: var(--text-tertiary); font-size: 14px; }

  .comment-text {
      font-size: 15px;
      line-height: 1.5;
      color: var(--text-main);
      margin-bottom: 12px;
  }

  .comment-footer {
      display: flex;
      gap: 24px;
  }

  .mini-action-btn {
      background: transparent;
      border: none;
      color: var(--text-tertiary);
      cursor: pointer;
      display: flex;
      align-items: center;
      padding: 6px;
      border-radius: 12px;
      transition: all 0.2s;
  }
  .mini-action-btn:hover {
      background-color: var(--bg-hover);
      color: var(--primary-color);
  }

  @keyframes fadeIn {
      from { opacity: 0; transform: translateY(10px); }
      to { opacity: 1; transform: translateY(0); }
  }
</style>
