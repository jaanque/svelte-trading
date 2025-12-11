<script lang="ts">
  import { onMount } from "svelte";
  import { userSession, userProfile } from "../../lib/authStore";
  import {
    getConversations,
    getMessages,
    sendMessage,
    type Conversation,
    type ChatMessage,
  } from "../../lib/chat";
  import { supabase } from "../../lib/supabase";
  import { formatMessage } from "../../lib/utils";
  import { Loader2, Send, Search, ArrowLeft, MessageSquare, Check, CheckCheck, MoreVertical } from "lucide-svelte";

  let loadingConversations = true;
  let loadingMessages = false;
  let conversations: Conversation[] = [];
  let messages: ChatMessage[] = [];
  let activeConversation: Conversation | null = null;
  let newMessage = "";
  let messageListContainer: HTMLElement;
  let searchQuery = "";
  let textarea: HTMLTextAreaElement;

  // Helper to handle auto-scrolling
  function scrollToBottom() {
    if (messageListContainer) {
      setTimeout(() => {
        messageListContainer.scrollTop = messageListContainer.scrollHeight;
      }, 50);
    }
  }

  function autoResize() {
      if (textarea) {
          textarea.style.height = 'auto';
          textarea.style.height = Math.min(textarea.scrollHeight, 120) + 'px';
      }
  }

  // Fetch initial data
  async function loadConversations() {
    loadingConversations = true;
    try {
      conversations = await getConversations();
    } catch (err) {
      console.error("Error loading conversations:", err);
    } finally {
      loadingConversations = false;
    }
  }

  async function loadMessages(userId: string) {
    loadingMessages = true;
    try {
      messages = await getMessages(userId);
      scrollToBottom();
    } catch (err) {
      console.error("Error loading messages:", err);
    } finally {
      loadingMessages = false;
    }
  }

  async function handleSendMessage() {
    if (!newMessage.trim() || !activeConversation) return;

    const tempMessage: ChatMessage = {
      id: "temp-" + Date.now(),
      sender_id: $userProfile.id,
      receiver_id: activeConversation.user_id,
      content: newMessage,
      created_at: new Date().toISOString(),
    };

    // Optimistic update
    messages = [...messages, tempMessage];
    const textToSend = newMessage;
    newMessage = "";
    if (textarea) {
        textarea.style.height = 'auto'; // Reset height
    }
    scrollToBottom();

    try {
      await sendMessage(activeConversation.user_id, textToSend);
      // Reload to get real ID and confirm
      await loadMessages(activeConversation.user_id);
      // Update sidebar list order/preview
      await loadConversations();
    } catch (err) {
      console.error("Error sending message:", err);
      // Rollback on error if needed
    }
  }

  function selectConversation(conv: Conversation) {
    activeConversation = conv;
    loadMessages(conv.user_id);
    // URL update for shareability/refresh
    const url = new URL(window.location.href);
    url.searchParams.set("u", conv.username);
    window.history.replaceState({}, "", url.toString());
  }

  async function initFromUrl() {
    const params = new URLSearchParams(window.location.search);
    const username = params.get("u");

    if (username) {
        // Check if we already have this conversation
        const existingConv = conversations.find(c => c.username === username);
        if (existingConv) {
            selectConversation(existingConv);
        } else {
            // New conversation, need to fetch user details to start
            const { data: userData, error } = await supabase
                .from("profiles")
                .select("id, username, full_name, avatar_url")
                .eq("username", username)
                .single();

            if (userData && !error) {
                const newConv: Conversation = {
                    user_id: userData.id,
                    username: userData.username,
                    full_name: userData.full_name || userData.username,
                    avatar_url: userData.avatar_url,
                    last_message: "",
                    last_message_at: new Date().toISOString()
                };
                // Prepend temporarily
                conversations = [newConv, ...conversations];
                selectConversation(newConv);
            }
        }
    }
  }

  onMount(async () => {
      await loadConversations();
      await initFromUrl();
  });

  $: filteredConversations = conversations.filter(c =>
      c.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.full_name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  function formatTime(isoString: string) {
      const date = new Date(isoString);
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }

  function formatDay(isoString: string) {
      const date = new Date(isoString);
      const today = new Date();
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      if (date.toDateString() === today.toDateString()) {
          return "Today";
      } else if (date.toDateString() === yesterday.toDateString()) {
          return "Yesterday";
      } else {
          return date.toLocaleDateString(undefined, { weekday: 'long', month: 'short', day: 'numeric' });
      }
  }

  function handleKeydown(e: KeyboardEvent) {
      if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();
          handleSendMessage();
      }
  }

  // Group messages by date for display
  let groupedMessages: { dateLabel: string, msgs: ChatMessage[] }[] = [];
  $: {
      if (messages.length > 0) {
          groupedMessages = [];
          let currentGroup: { dateLabel: string, msgs: ChatMessage[] } | null = null;

          messages.forEach(msg => {
              const dateLabel = formatDay(msg.created_at);
              if (!currentGroup || currentGroup.dateLabel !== dateLabel) {
                  if (currentGroup) groupedMessages.push(currentGroup);
                  currentGroup = { dateLabel, msgs: [] };
              }
              currentGroup.msgs.push(msg);
          });
          if (currentGroup) groupedMessages.push(currentGroup);
      } else {
          groupedMessages = [];
      }
  }
</script>

<div class="messages-page">
    <!-- Sidebar / Conversation List -->
    <div class="conversation-list {activeConversation ? 'hidden-mobile' : ''}">
        <div class="search-header">
            <h1>Messages</h1>
            <div class="search-bar">
                <Search size={18} class="search-icon"/>
                <input
                    type="text"
                    placeholder="Search messages..."
                    bind:value={searchQuery}
                />
            </div>
        </div>

        {#if loadingConversations}
            <div class="loading-container">
                 {#each Array(5) as _}
                    <div class="skeleton-item">
                        <div class="skeleton-avatar skeleton"></div>
                        <div class="skeleton-text">
                            <div class="skeleton-line short skeleton"></div>
                            <div class="skeleton-line long skeleton"></div>
                        </div>
                    </div>
                 {/each}
            </div>
        {:else if filteredConversations.length === 0}
            <div class="empty-state">
                <p>No messages found.</p>
            </div>
        {:else}
            <div class="list-content">
                {#each filteredConversations as conv}
                    <div
                        class="conversation-item {activeConversation?.user_id === conv.user_id ? 'active' : ''}"
                        on:click={() => selectConversation(conv)}
                        on:keydown={(e) => e.key === 'Enter' && selectConversation(conv)}
                        role="button"
                        tabindex="0"
                    >
                        <div class="avatar-wrapper">
                             <img
                                src={conv.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${conv.username}`}
                                alt={conv.username}
                                class="avatar"
                            />
                        </div>
                        <div class="info">
                            <div class="top">
                                <span class="name">{conv.full_name}</span>
                                <span class="time">{formatDay(conv.last_message_at) === 'Today' ? formatTime(conv.last_message_at) : new Date(conv.last_message_at).toLocaleDateString()}</span>
                            </div>
                            <div class="bottom">
                                <span class="preview">
                                    {#if conv.last_message}
                                        <span class="preview-text">
                                            {conv.last_message}
                                        </span>
                                    {:else}
                                        Start a conversation
                                    {/if}
                                </span>
                            </div>
                        </div>
                    </div>
                {/each}
            </div>
        {/if}
    </div>

    <!-- Chat Area -->
    <div class="chat-area {activeConversation ? 'active-mobile' : ''}">
        {#if activeConversation}
            <div class="chat-header">
                <button class="back-button" on:click={() => {
                    activeConversation = null;
                    const url = new URL(window.location.href);
                    url.searchParams.delete("u");
                    window.history.replaceState({}, "", url.toString());
                }}>
                    <ArrowLeft size={24} />
                </button>
                <div class="header-avatar-container">
                    <img
                        src={activeConversation.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${activeConversation.username}`}
                        alt={activeConversation.username}
                    />
                </div>
                <div class="header-info">
                    <span class="header-name">{activeConversation.full_name}</span>
                    <span class="header-username">${activeConversation.username.toUpperCase()}</span>
                </div>
                <div class="header-actions">
                    <!-- Future: Info button or menu -->
                </div>
            </div>

            <div class="messages-list" bind:this={messageListContainer}>
                {#if loadingMessages}
                    <div class="loading-container-chat">
                        {#each Array(3) as _, i}
                             <div class="skeleton-msg skeleton-left">
                                 <div class="skeleton-bubble skeleton"></div>
                             </div>
                             <div class="skeleton-msg skeleton-right">
                                 <div class="skeleton-bubble skeleton"></div>
                             </div>
                        {/each}
                    </div>
                {:else}
                    <div class="messages-container">
                        {#each groupedMessages as group}
                            <div class="date-separator-wrapper">
                                <div class="date-separator">
                                    <span>{group.dateLabel}</span>
                                </div>
                            </div>
                            {#each group.msgs as msg, i}
                                <div class="message-row {msg.sender_id === $userProfile?.id ? 'sent' : 'received'}">
                                    <div class="message-content-wrapper">
                                        <div class="message-bubble">
                                            {@html formatMessage(msg.content)}
                                        </div>
                                        <div class="message-meta">
                                            <span class="message-time">{formatTime(msg.created_at)}</span>
                                            {#if msg.sender_id === $userProfile?.id}
                                                <span class="read-receipt">
                                                    <!-- Simulated read receipt logic -->
                                                    <CheckCheck size={14} class="read-icon" />
                                                </span>
                                            {/if}
                                        </div>
                                    </div>
                                </div>
                            {/each}
                        {/each}
                    </div>
                {/if}
            </div>

            <div class="input-area-wrapper">
                <div class="input-area">
                    <textarea
                        bind:this={textarea}
                        placeholder="Start a new message"
                        bind:value={newMessage}
                        on:keydown={handleKeydown}
                        on:input={autoResize}
                        rows="1"
                    ></textarea>
                    <button class="send-btn" on:click={handleSendMessage} disabled={!newMessage.trim()}>
                        <Send size={20} />
                    </button>
                </div>
            </div>

        {:else}
            <div class="no-chat-selected">
                <div class="empty-illustration">
                     <div class="circle-bg">
                        <MessageSquare size={64} strokeWidth={1.5} />
                     </div>
                </div>
                <h2>Select a message</h2>
                <p>Choose from your existing conversations, start a new one, or search for a trader.</p>
                <button class="btn-primary-small" on:click={() => {
                    // Logic to focus search or redirect
                    const searchInput = document.querySelector('.search-bar input') as HTMLInputElement;
                    if(searchInput) searchInput.focus();
                }}>
                    Start new chat
                </button>
            </div>
        {/if}
    </div>
</div>

<style>
    .messages-page {
        display: flex;
        height: 100vh;
        width: 100%;
        background-color: var(--bg-main);
        overflow: hidden;
    }

    /* Sidebar */
    .conversation-list {
        width: 380px;
        border-right: 1px solid var(--border-color);
        display: flex;
        flex-direction: column;
        background-color: var(--bg-main);
    }

    .search-header {
        padding: 20px 16px;
        border-bottom: 1px solid var(--border-color);
    }

    .search-header h1 {
        margin: 0 0 16px 0;
        font-size: 24px;
        font-weight: 800;
        color: var(--text-main);
    }

    .search-bar {
        display: flex;
        align-items: center;
        background-color: var(--bg-secondary);
        border-radius: 9999px;
        padding: 10px 16px;
        border: 1px solid transparent;
        transition: all 0.2s;
    }

    .search-bar:focus-within {
        background-color: var(--bg-main);
        border-color: var(--primary-color);
        box-shadow: 0 0 0 2px rgba(29, 155, 240, 0.1);
    }

    .search-icon {
        color: var(--text-secondary);
        margin-right: 12px;
    }

    .search-bar input {
        border: none;
        background: transparent;
        outline: none;
        width: 100%;
        color: var(--text-main);
        font-size: 15px;
    }

    .list-content {
        flex: 1;
        overflow-y: auto;
    }

    .conversation-item {
        display: flex;
        padding: 16px;
        cursor: pointer;
        transition: background-color 0.2s;
        border-right: 2px solid transparent;
        position: relative;
    }

    .conversation-item:hover {
        background-color: var(--bg-hover);
    }

    .conversation-item.active {
        background-color: var(--bg-secondary);
        border-right-color: var(--primary-color);
    }

    .avatar-wrapper {
        position: relative;
    }

    .avatar {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        margin-right: 12px;
        background-color: var(--bg-tertiary);
        object-fit: cover;
    }

    .info {
        flex: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        overflow: hidden;
        gap: 2px;
    }

    .top {
        display: flex;
        justify-content: space-between;
        align-items: baseline;
    }

    .name {
        font-weight: 700;
        font-size: 15px;
        color: var(--text-main);
    }

    .time {
        font-size: 12px;
        color: var(--text-secondary);
    }

    .bottom {
        display: flex;
    }

    .preview {
        font-size: 14px;
        color: var(--text-secondary);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .conversation-item.active .preview {
        color: var(--text-main);
    }

    /* Chat Area */
    .chat-area {
        flex: 1;
        display: flex;
        flex-direction: column;
        background-color: var(--bg-main);
        position: relative;
    }

    .chat-header {
        padding: 0 24px;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        background-color: rgba(255, 255, 255, 0.9);
        backdrop-filter: blur(12px);
        z-index: 10;
        height: 70px;
        box-sizing: border-box;
    }

    .back-button {
        display: none;
        background: none;
        border: none;
        cursor: pointer;
        padding: 8px;
        margin-right: 4px;
        color: var(--text-main);
    }

    .header-avatar-container {
        width: 40px;
        height: 40px;
        margin-right: 12px;
    }

    .header-avatar-container img {
        width: 100%;
        height: 100%;
        border-radius: 50%;
        object-fit: cover;
    }

    .header-info {
        display: flex;
        flex-direction: column;
        justify-content: center;
    }

    .header-name {
        font-weight: 700;
        font-size: 16px;
        line-height: 1.2;
        color: var(--text-main);
    }

    .header-username {
        font-size: 13px;
        color: var(--text-secondary);
    }

    .header-actions {
        margin-left: auto;
    }

    .messages-list {
        flex: 1;
        overflow-y: auto;
        padding: 20px 24px;
        display: flex;
        flex-direction: column;
    }

    .messages-container {
        display: flex;
        flex-direction: column;
        gap: 8px;
        padding-bottom: 20px;
    }

    .date-separator-wrapper {
        position: sticky;
        top: 0;
        z-index: 5;
        display: flex;
        justify-content: center;
        margin-bottom: 16px;
        pointer-events: none; /* Let clicks pass through */
    }

    .date-separator {
        display: flex;
        justify-content: center;
    }

    .date-separator span {
        background-color: var(--bg-secondary); /* Needs opacity for sticky? */
        background-color: rgba(239, 243, 244, 0.9); /* var(--bg-secondary) with alpha */
        backdrop-filter: blur(4px);
        padding: 6px 16px;
        border-radius: 20px;
        font-size: 12px;
        color: var(--text-secondary);
        font-weight: 600;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }

    .message-row {
        display: flex;
        flex-direction: column;
        max-width: 70%;
    }

    .message-row.sent {
        align-self: flex-end;
        align-items: flex-end;
    }

    .message-row.received {
        align-self: flex-start;
        align-items: flex-start;
    }

    .message-content-wrapper {
        position: relative;
        display: flex;
        flex-direction: column;
    }

    .message-bubble {
        padding: 12px 18px;
        border-radius: 22px;
        font-size: 15px;
        line-height: 1.5;
        word-break: break-word;
        box-shadow: 0 1px 2px rgba(0,0,0,0.05);
    }

    /* Links in messages */
    .message-bubble :global(a) {
        text-decoration: underline;
        word-break: break-all;
    }

    .message-bubble :global(a:hover) {
        opacity: 0.8;
    }

    .sent .message-bubble {
        background-color: var(--primary-color);
        color: white;
        border-bottom-right-radius: 4px;
    }

    .sent .message-content-wrapper {
        align-items: flex-end;
    }

    .sent .message-bubble :global(a) {
        color: white;
    }

    .received .message-bubble {
        background-color: var(--bg-secondary);
        color: var(--text-main);
        border-bottom-left-radius: 4px;
    }

    .received .message-content-wrapper {
        align-items: flex-start;
    }

    .received .message-bubble :global(a) {
        color: var(--primary-color);
    }

    .message-meta {
        display: flex;
        align-items: center;
        gap: 4px;
        margin-top: 4px;
        padding: 0 4px;
        opacity: 0;
        transition: opacity 0.2s ease;
    }

    /* Reveal meta on hover of the row */
    .message-row:hover .message-meta {
        opacity: 1;
    }

    .message-time {
        font-size: 11px;
        color: var(--text-secondary);
    }

    .read-receipt {
        color: var(--primary-color);
        display: flex;
        align-items: center;
    }

    .input-area-wrapper {
        padding: 24px;
        background-color: var(--bg-main);
    }

    .input-area {
        display: flex;
        align-items: flex-end;
        gap: 12px;
        background-color: var(--bg-secondary);
        padding: 8px 16px;
        border-radius: 24px;
        border: 1px solid transparent;
        transition: background-color 0.2s, box-shadow 0.2s;
    }

    .input-area:focus-within {
        background-color: var(--bg-main);
        border-color: var(--primary-color);
        box-shadow: 0 0 0 2px rgba(29, 155, 240, 0.1);
    }

    .input-area textarea {
        flex: 1;
        padding: 8px 0;
        border: none;
        background: transparent;
        font-size: 15px;
        outline: none;
        color: var(--text-main);
        resize: none;
        max-height: 120px;
        line-height: 1.5;
        font-family: inherit;
    }

    .send-btn {
        background: var(--primary-color);
        border: none;
        cursor: pointer;
        color: white;
        width: 36px;
        height: 36px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
        margin-bottom: 2px; /* Align with bottom of text */
        flex-shrink: 0;
    }

    .send-btn:disabled {
        background-color: var(--bg-tertiary);
        color: var(--text-secondary);
        cursor: default;
    }

    .send-btn:hover:not(:disabled) {
        transform: scale(1.05);
    }

    /* Empty state */
    .no-chat-selected {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: var(--text-main);
        text-align: center;
        padding: 20px;
    }

    .empty-illustration {
        margin-bottom: 24px;
    }

    .circle-bg {
        width: 100px;
        height: 100px;
        background-color: var(--bg-secondary);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: var(--text-main);
    }

    .no-chat-selected h2 {
        font-size: 28px;
        font-weight: 800;
        margin-bottom: 12px;
        color: var(--text-main);
    }

    .no-chat-selected p {
        color: var(--text-secondary);
        max-width: 400px;
        margin-bottom: 32px;
        line-height: 1.5;
        font-size: 15px;
    }

    .btn-primary-small {
        background-color: var(--primary-color);
        color: white;
        padding: 12px 28px;
        border-radius: 9999px;
        border: none;
        font-weight: 700;
        font-size: 15px;
        transition: opacity 0.2s;
        cursor: pointer;
    }

    .btn-primary-small:hover {
        opacity: 0.9;
    }

    /* Skeleton Loading */
    @keyframes shimmer {
      0% { background-position: -200% 0; }
      100% { background-position: 200% 0; }
    }

    .skeleton {
      background: linear-gradient(90deg, var(--bg-tertiary) 25%, var(--bg-secondary) 50%, var(--bg-tertiary) 75%);
      background-size: 200% 100%;
      animation: shimmer 1.5s infinite;
      border-radius: 4px;
    }

    .loading-container {
        padding: 16px;
        display: flex;
        flex-direction: column;
        gap: 20px;
    }

    .skeleton-item {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .skeleton-avatar {
        width: 48px;
        height: 48px;
        border-radius: 50%;
    }

    .skeleton-text {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 8px;
    }

    .skeleton-line {
        height: 12px;
    }

    .skeleton-line.short { width: 40%; }
    .skeleton-line.long { width: 70%; }

    .loading-container-chat {
        display: flex;
        flex-direction: column;
        gap: 24px;
        padding: 20px;
    }

    .skeleton-msg {
        display: flex;
        width: 100%;
    }

    .skeleton-left { justify-content: flex-start; }
    .skeleton-right { justify-content: flex-end; }

    .skeleton-bubble {
        width: 200px;
        height: 40px;
        border-radius: 20px;
    }

    .empty-state {
        text-align: center;
        padding: 40px;
        color: var(--text-secondary);
    }

    /* Responsive */
    @media (max-width: 768px) {
        .conversation-list {
            width: 100%;
            display: flex;
        }

        .chat-area {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 50;
        }

        .conversation-list.hidden-mobile {
            display: none;
        }

        .chat-area.active-mobile {
            display: flex;
        }

        .back-button {
            display: block;
        }
    }
</style>
