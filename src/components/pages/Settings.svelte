<script lang="ts">
  import { onMount } from "svelte";
  import { userProfile } from "../../lib/authStore";
  import { supabase } from "../../lib/supabase";
  import {
    User,
    Settings as SettingsIcon,
    Bell,
    Shield,
    Wallet,
    LogOut,
    ChevronRight,
    Moon,
    HelpCircle,
    CreditCard,
    Lock,
    Smartphone,
    Mail
  } from "lucide-svelte";

  // Mock toggle states
  let notificationsEnabled = true;
  let darkMode = false;
  let privateAccount = false;

  async function handleLogout() {
      await supabase.auth.signOut();
      window.location.href = '/login';
  }

  const sections = [
      {
          title: "Account",
          items: [
              { icon: User, label: "Account Information", desc: "Username, Email, Phone", action: () => {} },
              { icon: Lock, label: "Change Password", desc: "Update your security", action: () => {} },
              { icon: Shield, label: "Privacy & Safety", desc: "Manage who sees your content", action: () => {} }
          ]
      },
      {
          title: "Wallet & Trading",
          items: [
              { icon: Wallet, label: "Wallet Balance", desc: "Manage your funds", action: () => {} },
              { icon: CreditCard, label: "Payment Methods", desc: "Cards and bank accounts", action: () => {} }
          ]
      },
      {
          title: "Preferences",
          items: [
              {
                  icon: Bell,
                  label: "Notifications",
                  desc: "Push and email preferences",
                  type: "toggle",
                  value: notificationsEnabled,
                  toggle: () => notificationsEnabled = !notificationsEnabled
              },
              {
                  icon: Moon,
                  label: "Dark Mode",
                  desc: "Toggle application theme",
                  type: "toggle",
                  value: darkMode,
                  toggle: () => darkMode = !darkMode
              }
          ]
      },
      {
          title: "Support",
          items: [
              { icon: HelpCircle, label: "Help Center", desc: "FAQ and contact support", action: () => {} }
          ]
      }
  ];
</script>

<div class="settings-page">
  <div class="settings-container">
      <div class="header">
          <h1>Settings</h1>
      </div>

      <!-- User Summary Card -->
      {#if $userProfile}
      <div class="user-summary">
          <div class="avatar-container">
               <img
                  src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
                  alt={$userProfile.username}
                  class="avatar"
               />
          </div>
          <div class="user-info">
              <h2 class="fullname">{$userProfile.full_name || $userProfile.username}</h2>
              <p class="username">${$userProfile.username.toUpperCase()}</p>
              <div class="contact-badges">
                   <div class="badge"><Mail size={12}/> <span>Verified</span></div>
                   <!-- Mock phone -->
                   <div class="badge secondary"><Smartphone size={12}/> <span>Add Phone</span></div>
              </div>
          </div>
          <button class="edit-btn">Edit</button>
      </div>
      {/if}

      <!-- Settings List -->
      <div class="settings-list">
          {#each sections as section}
              <div class="section">
                  <h3 class="section-title">{section.title}</h3>
                  <div class="section-items">
                      {#each section.items as item}
                          <div
                              class="setting-item {item.type === 'toggle' ? '' : 'clickable'}"
                              role="button"
                              tabindex="0"
                              on:click={item.type === 'toggle' ? item.toggle : item.action}
                          >
                              <div class="icon-box">
                                  <svelte:component this={item.icon} size={20} />
                              </div>
                              <div class="item-content">
                                  <span class="item-label">{item.label}</span>
                                  <span class="item-desc">{item.desc}</span>
                              </div>
                              <div class="item-action">
                                  {#if item.type === 'toggle'}
                                      <div class="toggle-switch {item.value ? 'active' : ''}">
                                          <div class="toggle-knob"></div>
                                      </div>
                                  {:else}
                                      <ChevronRight size={18} class="chevron" />
                                  {/if}
                              </div>
                          </div>
                      {/each}
                  </div>
              </div>
          {/each}

          <!-- Logout Section -->
          <div class="section logout-section">
              <button class="logout-btn" on:click={handleLogout}>
                  <LogOut size={20} />
                  <span>Log out of Pulse</span>
              </button>
              <p class="version-info">Version 1.0.0 (Beta)</p>
          </div>
      </div>
  </div>
</div>

<style>
  .settings-page {
      min-height: 100vh;
      background-color: var(--bg-main);
      display: flex;
      justify-content: center;
      padding-bottom: 80px; /* Safe area */
  }

  .settings-container {
      width: 100%;
      max-width: 600px; /* Mobile-first column width */
      display: flex;
      flex-direction: column;
  }

  .header {
      padding: 16px;
      position: sticky;
      top: 0;
      background-color: rgba(255, 255, 255, 0.9);
      backdrop-filter: blur(10px);
      z-index: 10;
      border-bottom: 1px solid var(--border-color);
  }

  .header h1 {
      margin: 0;
      font-size: 20px;
      font-weight: 800;
  }

  /* User Summary */
  .user-summary {
      margin: 20px 16px;
      background-color: var(--bg-secondary);
      border-radius: 20px;
      padding: 20px;
      display: flex;
      align-items: center;
      gap: 16px;
      border: 1px solid var(--border-color);
  }

  .avatar-container {
      width: 60px;
      height: 60px;
      flex-shrink: 0;
  }

  .avatar {
      width: 100%;
      height: 100%;
      border-radius: 50%;
      object-fit: cover;
      background-color: var(--bg-tertiary);
  }

  .user-info {
      flex: 1;
      overflow: hidden;
  }

  .fullname {
      font-size: 18px;
      font-weight: 800;
      margin: 0 0 2px 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
  }

  .username {
      font-size: 14px;
      color: var(--text-secondary);
      margin: 0 0 8px 0;
  }

  .contact-badges {
      display: flex;
      gap: 8px;
  }

  .badge {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 11px;
      background-color: rgba(16, 185, 129, 0.1); /* Green tint */
      color: var(--success-color);
      padding: 2px 8px;
      border-radius: 999px;
      font-weight: 600;
  }

  .badge.secondary {
      background-color: var(--bg-tertiary);
      color: var(--text-secondary);
  }

  .edit-btn {
      padding: 8px 16px;
      border-radius: 999px;
      border: 1px solid var(--border-color);
      background-color: var(--bg-main);
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .edit-btn:hover {
      background-color: var(--bg-hover);
  }

  /* Settings Sections */
  .settings-list {
      display: flex;
      flex-direction: column;
      gap: 24px;
      padding: 0 16px;
  }

  .section-title {
      font-size: 18px;
      font-weight: 800;
      margin: 0 0 12px 4px;
      color: var(--text-main);
  }

  .section-items {
      background-color: var(--bg-main);
      border-radius: 16px;
      overflow: hidden;
      border: 1px solid var(--border-color);
  }

  .setting-item {
      display: flex;
      align-items: center;
      padding: 16px;
      background-color: var(--bg-main);
      border-bottom: 1px solid var(--border-color);
      transition: background-color 0.2s;
  }

  .setting-item:last-child {
      border-bottom: none;
  }

  .setting-item.clickable {
      cursor: pointer;
  }

  .setting-item.clickable:hover {
      background-color: var(--bg-hover);
  }

  .icon-box {
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background-color: var(--bg-secondary);
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--text-main);
      margin-right: 16px;
  }

  .item-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
  }

  .item-label {
      font-size: 15px;
      font-weight: 600;
      color: var(--text-main);
  }

  .item-desc {
      font-size: 13px;
      color: var(--text-secondary);
      margin-top: 2px;
  }

  .item-action {
      margin-left: 8px;
      color: var(--text-secondary);
      display: flex;
      align-items: center;
  }

  /* Toggle Switch */
  .toggle-switch {
      width: 48px;
      height: 28px;
      background-color: var(--bg-tertiary);
      border-radius: 999px;
      position: relative;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .toggle-switch.active {
      background-color: var(--primary-color);
  }

  .toggle-knob {
      width: 24px;
      height: 24px;
      background-color: white;
      border-radius: 50%;
      position: absolute;
      top: 2px;
      left: 2px;
      transition: transform 0.2s cubic-bezier(0.4, 0.0, 0.2, 1);
      box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  }

  .toggle-switch.active .toggle-knob {
      transform: translateX(20px);
  }

  /* Logout */
  .logout-section {
      margin-top: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
  }

  .logout-btn {
      width: 100%;
      padding: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      background-color: rgba(239, 68, 68, 0.1); /* Light red */
      color: var(--danger-color);
      border: none;
      border-radius: 16px;
      font-weight: 700;
      font-size: 16px;
      cursor: pointer;
      transition: background-color 0.2s;
  }

  .logout-btn:hover {
      background-color: rgba(239, 68, 68, 0.2);
  }

  .version-info {
      font-size: 13px;
      color: var(--text-tertiary);
      margin-bottom: 24px;
  }

  @media (max-width: 640px) {
      .settings-container {
          max-width: 100%;
      }
      .user-summary {
          border-radius: 0;
          margin: 0;
          border-left: none;
          border-right: none;
      }
  }
</style>
