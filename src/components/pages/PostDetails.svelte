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
  <div class="sticky-header">
    <div class="header-content">
      <button class="back-btn" on:click={() => window.history.back()}><ArrowLeft size={20} /></button>
      <h3>Post</h3>
    </div>
  </div>

  {#if loading}
    <div class="center-content">
      <Loader2 class="animate-spin" size={32} color="var(--primary-color)" />
    </div>
  {:else if error}
    <div class="center-content">
      <div class="error-container">
        <h2>Post not found</h2>
        <button class="btn-secondary" on:click={() => onNavigate('/')}>Go Home</button>
      </div>
    </div>
  {:else if post}
    <div class="main-post">
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
         <div class="stat"><strong>{post.replies_count || 0}</strong> <span class="label">Replies</span></div>
         <div class="stat"><strong>{post.likes_count || 0}</strong> <span class="label">Likes</span></div>
      </div>

      <div class="post-actions">
         <button class="action-btn"><MessageCircle size={20} /></button>
         <button class="action-btn"><Share2 size={20} /></button>
         <button class="action-btn"><Heart size={20} /></button>
      </div>
    </div>

    <!-- Reply Input -->
    <div class="reply-section">
       {#if $userProfile}
         <div class="reply-input-container">
            <img
               src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
               alt=""
               class="current-avatar"
            />
            <div class="input-wrapper">
               <textarea
                  placeholder="Post your reply"
                  bind:value={newCommentText}
                  rows="1"
                  on:input={(e) => {
                      const target = e.target as HTMLTextAreaElement;
                      target.style.height = 'auto';
                      target.style.height = target.scrollHeight + 'px';
                  }}
               ></textarea>
            </div>
            <button class="reply-btn" disabled={!newCommentText.trim() || submittingComment} on:click={submitComment}>
               {#if submittingComment}
                   <Loader2 class="animate-spin" size={18} />
               {:else}
                   Reply
               {/if}
            </button>
         </div>
       {:else}
         <div class="guest-reply">
            <a href="/login" on:click|preventDefault={() => onNavigate('/login')}>Log in</a> to reply
         </div>
       {/if}
    </div>

    <!-- Comments List -->
    <div class="comments-list">
       {#each comments as comment}
          <div class="comment-item">
             <div class="comment-avatar">
                <img
                   src={comment.user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${comment.user.username}`}
                   alt={comment.user.username}
                />
             </div>
             <div class="comment-content">
                <div class="comment-header">
                   <span class="name">{comment.user.full_name || comment.user.username}</span>
                   <span class="handle">${comment.user.username.toUpperCase()}</span>
                   <span class="dot">·</span>
                   <span class="time">{formatTimeShort(comment.created_at)}</span>
                </div>
                <div class="comment-text">{@html formatMessage(comment.content)}</div>
                <div class="comment-actions">
                    <button class="mini-action-btn"><MessageCircle size={16} /></button>
                    <button class="mini-action-btn"><Heart size={16} /></button>
                </div>
             </div>
          </div>
       {/each}
    </div>
  {/if}
</div>

<style>
  .post-details-page {
    width: 100%;
    min-height: 100vh;
    background-color: var(--bg-main);
    display: flex;
    flex-direction: column;
  }

  .sticky-header {
      position: sticky;
      top: 0;
      background: rgba(255, 255, 255, 0.85);
      backdrop-filter: blur(12px);
      z-index: 100;
      height: 53px;
      display: flex;
      align-items: center;
      border-bottom: 1px solid var(--border-color);
      padding: 0 16px;
  }

  .header-content {
      display: flex;
      align-items: center;
      gap: 20px;
  }

  .header-content h3 {
      margin: 0;
      font-size: 20px;
      font-weight: 800;
  }

  .back-btn {
      background: none;
      border: none;
      cursor: pointer;
      padding: 8px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
      transition: background-color 0.2s;
  }
  .back-btn:hover { background-color: var(--bg-hover); }

  .center-content {
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 40px;
  }

  /* Main Post Styles */
  .main-post {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
  }

  .post-header {
      display: flex;
      gap: 12px;
      align-items: center;
      margin-bottom: 16px;
  }

  .avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      object-fit: cover;
  }

  .user-info {
      display: flex;
      flex-direction: column;
      flex: 1;
  }

  .fullname {
      font-weight: 800;
      font-size: 16px;
      color: var(--text-main);
  }

  .username {
      color: var(--text-secondary);
      font-size: 15px;
  }

  .more-btn {
      background: none;
      border: none;
      color: var(--text-secondary);
      cursor: pointer;
  }

  .post-content {
      font-size: 18px; /* Larger font for main post */
      line-height: 1.5;
      color: var(--text-main);
      margin: 0 0 16px 0;
      white-space: pre-wrap;
  }

  .post-meta {
      color: var(--text-secondary);
      font-size: 15px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border-color);
      margin-bottom: 16px;
  }

  .post-stats {
      display: flex;
      gap: 20px;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border-color);
      margin-bottom: 4px; /* Space for actions border */
  }

  .stat strong { color: var(--text-main); }
  .stat .label { color: var(--text-secondary); }

  .post-actions {
      display: flex;
      justify-content: space-around;
      padding: 12px 0;
      border-bottom: 1px solid var(--border-color);
  }

  .action-btn {
      background: none;
      border: none;
      color: var(--text-secondary);
      cursor: pointer;
      padding: 8px;
      border-radius: 50%;
      transition: all 0.2s;
  }
  .action-btn:hover { background-color: var(--bg-hover); color: var(--primary-color); }

  /* Reply Input */
  .reply-section {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
  }

  .reply-input-container {
      display: flex;
      gap: 12px;
      align-items: flex-start;
  }

  .current-avatar {
      width: 40px;
      height: 40px;
      border-radius: 50%;
  }

  .input-wrapper {
      flex: 1;
      padding-top: 8px;
  }

  textarea {
      width: 100%;
      border: none;
      background: transparent;
      font-size: 18px;
      resize: none;
      outline: none;
      color: var(--text-main);
      font-family: inherit;
  }

  .reply-btn {
      background-color: var(--primary-color);
      color: white;
      border: none;
      padding: 8px 16px;
      border-radius: 9999px;
      font-weight: 700;
      cursor: pointer;
      opacity: 1;
      transition: opacity 0.2s;
  }
  .reply-btn:disabled { opacity: 0.5; cursor: default; }

  /* Comments List */
  .comments-list {
      padding-bottom: 40px;
  }

  .comment-item {
      padding: 16px;
      border-bottom: 1px solid var(--border-color);
      display: flex;
      gap: 12px;
      transition: background-color 0.2s;
  }
  .comment-item:hover { background-color: var(--bg-hover); cursor: pointer; }

  .comment-avatar img {
      width: 40px;
      height: 40px;
      border-radius: 50%;
  }

  .comment-content {
      flex: 1;
  }

  .comment-header {
      display: flex;
      gap: 6px;
      align-items: center;
      font-size: 15px;
      margin-bottom: 4px;
  }

  .comment-header .name { font-weight: 700; color: var(--text-main); }
  .comment-header .handle { color: var(--text-secondary); }
  .comment-header .dot { color: var(--text-secondary); }
  .comment-header .time { color: var(--text-secondary); }

  .comment-text {
      font-size: 15px;
      line-height: 1.4;
      color: var(--text-main);
      margin-bottom: 12px;
  }

  .comment-actions {
      display: flex;
      gap: 40px;
  }

  .mini-action-btn {
      background: none;
      border: none;
      color: var(--text-secondary);
      cursor: pointer;
      display: flex;
      align-items: center;
      padding: 0;
  }
  .mini-action-btn:hover { color: var(--primary-color); }
</style>
