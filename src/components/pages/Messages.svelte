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
  import { Loader2, Send, Search, ArrowLeft } from "lucide-svelte";

  let loadingConversations = true;
  let loadingMessages = false;
  let conversations: Conversation[] = [];
  let messages: ChatMessage[] = [];
  let activeConversation: Conversation | null = null;
  let newMessage = "";
  let messageListContainer: HTMLElement;
  let searchQuery = "";

  // Helper to handle auto-scrolling
  function scrollToBottom() {
    if (messageListContainer) {
      setTimeout(() => {
        messageListContainer.scrollTop = messageListContainer.scrollHeight;
      }, 50);
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

  function handleKeydown(e: KeyboardEvent) {
      if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();
          handleSendMessage();
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
                <Loader2 class="animate-spin" />
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
                        <img
                            src={conv.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${conv.username}`}
                            alt={conv.username}
                            class="avatar"
                        />
                        <div class="info">
                            <div class="top">
                                <span class="name">{conv.full_name}</span>
                                <span class="time">{new Date(conv.last_message_at).toLocaleDateString()}</span>
                            </div>
                            <div class="bottom">
                                <span class="preview">{conv.last_message || "Start a conversation"}</span>
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
                <div class="header-info">
                    <span class="header-name">{activeConversation.full_name}</span>
                    <span class="header-username">${activeConversation.username.toUpperCase()}</span>
                </div>
            </div>

            <div class="messages-list" bind:this={messageListContainer}>
                {#if loadingMessages}
                    <div class="loading-container">
                        <Loader2 class="animate-spin" />
                    </div>
                {:else}
                    {#each messages as msg}
                        <div class="message-row {msg.sender_id === $userProfile?.id ? 'sent' : 'received'}">
                            <div class="message-bubble">
                                {msg.content}
                            </div>
                            <span class="message-time">{formatTime(msg.created_at)}</span>
                        </div>
                    {/each}
                {/if}
            </div>

            <div class="input-area">
                <input
                    type="text"
                    placeholder="Type a message..."
                    bind:value={newMessage}
                    on:keydown={handleKeydown}
                />
                <button class="send-btn" on:click={handleSendMessage} disabled={!newMessage.trim()}>
                    <Send size={20} />
                </button>
            </div>

        {:else}
            <div class="no-chat-selected">
                <h2>Select a conversation</h2>
                <p>Choose from your existing conversations or start a new one.</p>
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
        width: 350px;
        border-right: 1px solid var(--border-color);
        display: flex;
        flex-direction: column;
        background-color: var(--bg-main);
    }

    .search-header {
        padding: 16px;
        border-bottom: 1px solid var(--border-color);
    }

    .search-header h1 {
        margin: 0 0 16px 0;
        font-size: 20px;
    }

    .search-bar {
        display: flex;
        align-items: center;
        background-color: var(--bg-secondary);
        border-radius: 9999px;
        padding: 8px 16px;
        border: 1px solid transparent;
    }

    .search-bar:focus-within {
        background-color: var(--bg-main);
        border-color: var(--primary-color);
    }

    .search-icon {
        color: var(--text-secondary);
        margin-right: 8px;
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
        padding: 12px 16px;
        cursor: pointer;
        transition: background-color 0.2s;
        border-bottom: 1px solid var(--border-color);
    }

    .conversation-item:hover {
        background-color: var(--bg-hover);
    }

    .conversation-item.active {
        background-color: var(--bg-secondary);
        border-right: 2px solid var(--primary-color);
    }

    .avatar {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        margin-right: 12px;
        background-color: var(--bg-tertiary);
    }

    .info {
        flex: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        overflow: hidden;
    }

    .top {
        display: flex;
        justify-content: space-between;
        margin-bottom: 4px;
    }

    .name {
        font-weight: 700;
        font-size: 15px;
        color: var(--text-main);
    }

    .time {
        font-size: 13px;
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

    /* Chat Area */
    .chat-area {
        flex: 1;
        display: flex;
        flex-direction: column;
        background-color: var(--bg-main);
    }

    .chat-header {
        padding: 10px 16px;
        border-bottom: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        background-color: rgba(255, 255, 255, 0.85);
        backdrop-filter: blur(12px);
        z-index: 10;
        height: 53px;
        box-sizing: border-box;
    }

    .back-button {
        display: none; /* Hidden on desktop */
        background: none;
        border: none;
        cursor: pointer;
        padding: 8px;
        margin-right: 8px;
        color: var(--text-main);
    }

    .header-info {
        display: flex;
        flex-direction: column;
    }

    .header-name {
        font-weight: 700;
        font-size: 16px;
    }

    .header-username {
        font-size: 13px;
        color: var(--text-secondary);
    }

    .messages-list {
        flex: 1;
        overflow-y: auto;
        padding: 16px;
        display: flex;
        flex-direction: column;
        gap: 8px;
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

    .message-bubble {
        padding: 10px 16px;
        border-radius: 16px;
        font-size: 15px;
        line-height: 1.4;
        word-break: break-word;
    }

    .sent .message-bubble {
        background-color: var(--primary-color);
        color: white;
        border-bottom-right-radius: 4px;
    }

    .received .message-bubble {
        background-color: var(--bg-secondary);
        color: var(--text-main);
        border-bottom-left-radius: 4px;
    }

    .message-time {
        font-size: 11px;
        color: var(--text-secondary);
        margin-top: 4px;
        margin-left: 4px;
        margin-right: 4px;
    }

    .input-area {
        padding: 16px;
        border-top: 1px solid var(--border-color);
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .input-area input {
        flex: 1;
        padding: 12px 16px;
        border-radius: 20px;
        border: 1px solid var(--border-color);
        background-color: var(--bg-secondary);
        font-size: 15px;
        outline: none;
        color: var(--text-main);
    }

    .input-area input:focus {
        border-color: var(--primary-color);
        background-color: var(--bg-main);
    }

    .send-btn {
        background: none;
        border: none;
        cursor: pointer;
        color: var(--primary-color);
        padding: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .send-btn:disabled {
        color: var(--text-secondary);
        cursor: default;
    }

    .no-chat-selected {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: var(--text-secondary);
    }

    .loading-container {
        display: flex;
        justify-content: center;
        padding: 20px;
    }

    .empty-state {
        text-align: center;
        padding: 20px;
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
