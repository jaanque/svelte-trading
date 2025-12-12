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
    Mail,
    Camera,
    Loader2
  } from "lucide-svelte";
  import type { ComponentType } from "svelte";

  // Mock toggle states
  let notificationsEnabled = true;
  let darkMode = false;
  let privateAccount = false;
  let fileInput: HTMLInputElement;
  let uploading = false;

  async function uploadAvatar(event: Event) {
      const target = event.target as HTMLInputElement;
      if (!target.files || target.files.length === 0) return;

      const file = target.files[0];
      const fileExt = file.name.split('.').pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `${$userProfile?.id}/${fileName}`;

      uploading = true;
      try {
          const { error: uploadError } = await supabase.storage
              .from('avatars')
              .upload(filePath, file);

          if (uploadError) throw uploadError;

          const { data } = supabase.storage.from('avatars').getPublicUrl(filePath);

          const { error: updateError } = await supabase
              .from('profiles')
              .update({ avatar_url: data.publicUrl })
              .eq('id', $userProfile?.id);

          if (updateError) throw updateError;

          // Update auth store
          if ($userProfile) {
              userProfile.set({ ...$userProfile, avatar_url: data.publicUrl });
          }
      } catch (err) {
          console.error('Error uploading avatar:', err);
          alert('Error uploading avatar');
      } finally {
          uploading = false;
      }
  }

  function triggerFileInput() {
      fileInput.click();
  }

  async function handleLogout() {
      await supabase.auth.signOut();
      window.location.href = '/login';
  }

  interface SettingItem {
    icon: ComponentType;
    label: string;
    desc: string;
    type?: 'toggle';
    action?: () => void;
    value?: boolean;
    toggle?: () => void;
  }

  const sections: { title: string; items: SettingItem[] }[] = [
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
                  toggle: () => { notificationsEnabled = !notificationsEnabled; }
              },
              {
                  icon: Moon,
                  label: "Dark Mode",
                  desc: "Toggle application theme",
                  type: "toggle",
                  value: darkMode,
                  toggle: () => { darkMode = !darkMode; }
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

  function handleItemClick(item: SettingItem) {
      if (item.type === 'toggle' && item.toggle) {
          item.toggle();
      } else if (item.action) {
          item.action();
      }
  }

  function handleItemKeydown(e: KeyboardEvent, item: SettingItem) {
      if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          handleItemClick(item);
      }
  }
</script>

<div class="settings-page">
  <div class="settings-container">
      <div class="header">
          <h1>Settings</h1>
      </div>

      <!-- User Summary Card -->
      {#if $userProfile}
      <div class="user-summary">
          <div class="avatar-container" on:click={triggerFileInput} role="button" tabindex="0" on:keydown={(e) => e.key === 'Enter' && triggerFileInput()}>
               <img
                  src={$userProfile.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${$userProfile.username}`}
                  alt={$userProfile.username}
                  class="avatar"
               />
               <div class="avatar-overlay">
                    {#if uploading}
                        <Loader2 class="animate-spin" size={24} color="white" />
                    {:else}
                        <Camera size={24} color="white" />
                    {/if}
               </div>
               <input
                    type="file"
                    accept="image/*"
                    bind:this={fileInput}
                    on:change={uploadAvatar}
                    style="display: none;"
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
                              on:click={() => handleItemClick(item)}
                              on:keydown={(e) => handleItemKeydown(e, item)}
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
      padding: 40px 24px 80px 24px; /* Generous padding: Top, Right, Bottom, Left */
      box-sizing: border-box;
  }

  .settings-container {
      width: 100%;
      max-width: 800px; /* Wider container to utilize page */
      display: flex;
      flex-direction: column;
      gap: 24px;
  }

  .header {
      margin-bottom: 8px;
  }

  .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 800;
      color: var(--text-main);
  }

  /* User Summary */
  .user-summary {
      background-color: var(--bg-secondary);
      border-radius: 24px;
      padding: 24px;
      display: flex;
      align-items: center;
      gap: 20px;
      border: 1px solid var(--border-color);
      box-shadow: 0 2px 8px rgba(0,0,0,0.02);
  }

  .avatar-container {
      width: 72px;
      height: 72px;
      flex-shrink: 0;
      position: relative;
      cursor: pointer;
  }

  .avatar {
      width: 100%;
      height: 100%;
      border-radius: 50%;
      object-fit: cover;
      background-color: var(--bg-tertiary);
      border: 2px solid white;
  }

  .avatar-overlay {
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background-color: rgba(0, 0, 0, 0.4);
      border-radius: 50%;
      display: flex;
      justify-content: center;
      align-items: center;
      opacity: 0;
      transition: opacity 0.2s;
      border: 2px solid transparent; /* To match avatar border sizing if needed */
  }

  .avatar-container:hover .avatar-overlay {
      opacity: 1;
  }

  .user-info {
      flex: 1;
      overflow: hidden;
  }

  .fullname {
      font-size: 20px;
      font-weight: 800;
      margin: 0 0 4px 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      color: var(--text-main);
  }

  .username {
      font-size: 15px;
      color: var(--text-secondary);
      margin: 0 0 12px 0;
  }

  .contact-badges {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
  }

  .badge {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      background-color: rgba(16, 185, 129, 0.1); /* Green tint */
      color: var(--success-color);
      padding: 4px 10px;
      border-radius: 999px;
      font-weight: 600;
  }

  .badge.secondary {
      background-color: var(--bg-tertiary);
      color: var(--text-secondary);
  }

  .edit-btn {
      padding: 10px 20px;
      border-radius: 999px;
      border: 1px solid var(--border-color);
      background-color: var(--bg-main);
      font-weight: 700;
      font-size: 14px;
      cursor: pointer;
      transition: all 0.2s;
      color: var(--text-main);
  }

  .edit-btn:hover {
      background-color: var(--bg-hover);
      border-color: var(--text-secondary);
  }

  /* Settings Sections */
  .settings-list {
      display: flex;
      flex-direction: column;
      gap: 32px;
  }

  .section-title {
      font-size: 18px;
      font-weight: 800;
      margin: 0 0 16px 8px;
      color: var(--text-main);
  }

  .section-items {
      background-color: var(--bg-main);
      border-radius: 24px;
      overflow: hidden;
      border: 1px solid var(--border-color);
      box-shadow: 0 2px 12px rgba(0,0,0,0.03);
  }

  .setting-item {
      display: flex;
      align-items: center;
      padding: 20px;
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
      width: 44px;
      height: 44px;
      border-radius: 12px;
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
      font-size: 16px;
      font-weight: 600;
      color: var(--text-main);
  }

  .item-desc {
      font-size: 14px;
      color: var(--text-secondary);
      margin-top: 4px;
  }

  .item-action {
      margin-left: 12px;
      color: var(--text-secondary);
      display: flex;
      align-items: center;
  }

  /* Toggle Switch */
  .toggle-switch {
      width: 52px;
      height: 32px;
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
      width: 26px;
      height: 26px;
      background-color: white;
      border-radius: 50%;
      position: absolute;
      top: 3px;
      left: 3px;
      transition: transform 0.2s cubic-bezier(0.4, 0.0, 0.2, 1);
      box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  }

  .toggle-switch.active .toggle-knob {
      transform: translateX(20px);
  }

  /* Logout */
  .logout-section {
      margin-top: 24px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
  }

  .logout-btn {
      width: 100%;
      padding: 18px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
      background-color: rgba(239, 68, 68, 0.05);
      color: var(--danger-color);
      border: 1px solid rgba(239, 68, 68, 0.1);
      border-radius: 20px;
      font-weight: 700;
      font-size: 16px;
      cursor: pointer;
      transition: all 0.2s;
  }

  .logout-btn:hover {
      background-color: rgba(239, 68, 68, 0.15);
      border-color: rgba(239, 68, 68, 0.2);
  }

  .version-info {
      font-size: 13px;
      color: var(--text-tertiary);
      margin-bottom: 24px;
  }

  @media (max-width: 640px) {
      .settings-page {
          padding: 24px 16px 80px 16px; /* Slightly less padding on small screens */
      }
      .settings-container {
          max-width: 100%;
      }
      .user-summary {
          flex-direction: column;
          align-items: flex-start;
          text-align: left;
      }
      .edit-btn {
          width: 100%;
          justify-content: center;
      }
  }
</style>
