<script lang="ts">
  import { createEventDispatcher } from "svelte";
  import { X, Loader2 } from "lucide-svelte";
  import { supabase } from "../../lib/supabase";
  import { userProfile } from "../../lib/authStore";

  export let targetUser: any;
  export let userShares: number; // The amount of shares the user currently holds
  export let onClose: () => void;

  const dispatch = createEventDispatcher();

  let sellShares = "";
  let receiveTokens = "";
  let loading = false;
  let errorMsg = "";
  let successMsg = "";

  // Derived values
  $: price = targetUser.price || 50;

  // Validation
  $: sharesVal = parseFloat(sellShares) || 0;
  $: tokensVal = parseFloat(receiveTokens) || 0;
  $: isValid = sharesVal > 0 && sharesVal <= userShares;

  function updateFromShares(e: Event) {
      const val = parseFloat((e.target as HTMLInputElement).value);
      if (!isNaN(val)) {
          receiveTokens = (val * price).toFixed(2);
      } else {
          receiveTokens = "";
      }
  }

  function updateFromTokens(e: Event) {
      const val = parseFloat((e.target as HTMLInputElement).value);
      if (!isNaN(val)) {
          // Snap shares to integer
          const rawShares = val / price;
          const snappedShares = Math.floor(rawShares);
          sellShares = snappedShares.toFixed(0);
      } else {
          sellShares = "";
      }
  }

  async function handleSell() {
    const exactShares = Math.floor(sharesVal);

    if (exactShares <= 0) {
        errorMsg = "Minimum sale is 1 share.";
        return;
    }

    // Check if trying to sell more than owned (redundant with isValid but safe)
    if (exactShares > userShares) {
        errorMsg = "Cannot sell more shares than you own.";
        return;
    }

    loading = true;
    errorMsg = "";
    successMsg = "";

    try {
      const { error } = await supabase.rpc("sell_shares", {
        p_target_user_id: targetUser.id,
        p_amount_shares: exactShares
      });

      if (error) throw error;

      successMsg = `Successfully sold ${exactShares} shares of ${targetUser.username}!`;
      setTimeout(() => {
          onClose();
          dispatch("success");
      }, 2000);

    } catch (err: any) {
      console.error("Sell error:", err);
      errorMsg = err.message || "Failed to process sale.";
    } finally {
      loading = false;
    }
  }
</script>

<div class="modal-overlay" on:click|self={onClose} role="button" tabindex="0" on:keydown={(e) => e.key === 'Escape' && onClose()}>
  <div class="modal-content" role="dialog" aria-modal="true">
    <div class="modal-header">
      <h2>Sell shares of ${targetUser.username?.toUpperCase()}</h2>
      <button class="close-btn" on:click={onClose}>
        <X size={24} />
      </button>
    </div>

    <div class="modal-body">
      {#if successMsg}
        <div class="success-message">
            {successMsg}
        </div>
      {:else}
        <div class="info-row">
            <span class="label">Current Price</span>
            <span class="value">{price.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} Tokens/Share</span>
        </div>

        <div class="info-row">
            <span class="label">Your Shares</span>
            <span class="value">{userShares.toLocaleString(undefined, {minimumFractionDigits: 0, maximumFractionDigits: 4})}</span>
        </div>

        <div class="input-grid">
            <div class="input-group">
                <label for="shares">Shares to Sell</label>
                <input
                    type="number"
                    id="shares"
                    bind:value={sellShares}
                    on:input={updateFromShares}
                    placeholder="0"
                    min="1"
                    max={userShares}
                    step="1"
                />
            </div>
            <div class="input-group">
                <label for="tokens">Tokens (approx)</label>
                <input
                    type="number"
                    id="tokens"
                    bind:value={receiveTokens}
                    on:input={updateFromTokens}
                    placeholder="0"
                    min="0"
                    step="any"
                />
            </div>
        </div>

        {#if errorMsg}
            <div class="error-message">{errorMsg}</div>
        {/if}
        {#if sharesVal > 0 && sharesVal > userShares}
            <div class="error-message">You cannot sell more shares than you own.</div>
        {/if}
      {/if}
    </div>

    {#if !successMsg}
        <div class="modal-footer">
        <button class="btn-cancel" on:click={onClose}>Cancel</button>
        <button
            class="btn-confirm"
            disabled={!isValid || loading}
            on:click={handleSell}
        >
            {#if loading}
                <Loader2 class="animate-spin" size={18} /> Processing...
            {:else}
                Confirm Sale
            {/if}
        </button>
        </div>
    {/if}
  </div>
</div>

<style>
  .modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
  }

  .modal-content {
    background-color: white;
    width: 90%;
    max-width: 400px;
    border-radius: 16px;
    overflow: hidden;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }

  .modal-header {
    padding: 16px 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--border-color, #eee);
  }

  .modal-header h2 {
    margin: 0;
    font-size: 20px;
    font-weight: 700;
  }

  .close-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 4px;
    color: var(--text-secondary, #555);
  }

  .modal-body {
    padding: 24px;
  }

  .info-row {
    display: flex;
    justify-content: space-between;
    margin-bottom: 12px;
    font-size: 15px;
  }

  .label {
    color: var(--text-secondary, #555);
  }

  .value {
    font-weight: 600;
    color: var(--text-main, #000);
  }

  .input-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin: 20px 0;
  }

  .input-group label {
    display: block;
    margin-bottom: 8px;
    font-weight: 600;
    font-size: 14px;
  }

  .input-group input {
    width: 100%;
    padding: 12px;
    border: 1px solid var(--border-color, #ccc);
    border-radius: 8px;
    font-size: 16px;
    box-sizing: border-box;
  }

  .input-group input:focus {
      outline: none;
      border-color: var(--primary-color, #1d9bf0);
      box-shadow: 0 0 0 1px var(--primary-color, #1d9bf0);
  }

  .error-message {
    color: #f4212e;
    font-size: 14px;
    margin-top: 12px;
    text-align: center;
  }

  .success-message {
      color: #00ba7c;
      text-align: center;
      font-weight: 600;
      padding: 20px;
  }

  .modal-footer {
    padding: 16px 24px;
    border-top: 1px solid var(--border-color, #eee);
    display: flex;
    justify-content: flex-end;
    gap: 12px;
  }

  .btn-cancel {
    padding: 10px 20px;
    border-radius: 9999px;
    border: 1px solid var(--border-color, #ccc);
    background: white;
    font-weight: 600;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  .btn-cancel:hover {
      background-color: var(--bg-hover, #f7f9f9);
  }

  .btn-confirm {
    padding: 10px 20px;
    border-radius: 9999px;
    border: none;
    background: #0f1419;
    color: white;
    font-weight: 700;
    cursor: pointer;
    transition: opacity 0.2s;
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .btn-confirm:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-confirm:not(:disabled):hover {
      opacity: 0.9;
  }
</style>
