<script lang="ts">
    export let user: {
        id: string;
        username: string;
        full_name: string;
        avatar_url: string;
    };
    export let onClick: (() => void) | undefined = undefined;
</script>

<a
  href={`/profile?u=${user.username}`}
  class="user-card"
  on:click={(e) => {
    if (onClick) {
        e.preventDefault();
        onClick();
    }
  }}
>
    <div class="card-header">
        <div class="avatar-container">
            <img
                src={user.avatar_url || `https://api.dicebear.com/9.x/avataaars/svg?seed=${user.username}`}
                alt={user.username}
                class="avatar"
            />
        </div>
    </div>
    <div class="card-body">
        <h3 class="fullname">{user.full_name || "Unknown"}</h3>
        <p class="username">${user.username.toUpperCase()}</p>
        <slot />
    </div>
</a>

<style>
    .user-card {
        display: flex;
        flex-direction: column;
        background-color: var(--bg-secondary);
        border-radius: 16px;
        overflow: hidden;
        text-decoration: none;
        transition: transform 0.2s, box-shadow 0.2s, background-color 0.2s;
        border: 1px solid var(--border-color);
        height: 100%;
    }

    .user-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 10px 20px -5px rgba(0, 0, 0, 0.1);
        background-color: var(--bg-hover);
        border-color: var(--primary-color);
    }

    .card-header {
        display: flex;
        justify-content: center;
        padding-top: 24px;
    }

    .avatar-container {
        width: 80px;
        height: 80px;
        border-radius: 50%;
        padding: 3px;
        background: linear-gradient(135deg, var(--primary-color), var(--accent-color, #70c1ff));
    }

    .avatar {
        width: 100%;
        height: 100%;
        border-radius: 50%;
        object-fit: cover;
        border: 3px solid var(--bg-secondary);
        background-color: var(--bg-tertiary);
        transition: border-color 0.2s;
    }

    .user-card:hover .avatar {
        border-color: var(--bg-hover);
    }

    .card-body {
        padding: 16px;
        text-align: center;
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    .fullname {
        font-size: 16px;
        font-weight: 700;
        color: var(--text-main);
        margin: 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .username {
        font-size: 14px;
        color: var(--text-secondary);
        margin: 0;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
</style>
