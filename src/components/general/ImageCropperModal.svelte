<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import Cropper from 'cropperjs';
  import 'cropperjs/dist/cropper.css';
  import { X, Check, RotateCw, ZoomIn, ZoomOut, RefreshCcw, Loader2 } from 'lucide-svelte';

  export let imageFile: File | null = null;
  export let aspectRatio: number = 1; // Default square
  export let circular: boolean = false; // For visual guidance only (CropperJS crops rects)

  const dispatch = createEventDispatcher();
  let imageElement: HTMLImageElement;
  let cropper: Cropper | null = null;
  let objectUrl: string | null = null;
  let processing = false;

  onMount(() => {
    if (imageFile) {
      objectUrl = URL.createObjectURL(imageFile);
    }
  });

  onDestroy(() => {
    if (cropper) {
      cropper.destroy();
    }
    if (objectUrl) {
      URL.revokeObjectURL(objectUrl);
    }
  });

  function initCropper() {
    if (imageElement && !cropper) {
      cropper = new Cropper(imageElement, {
        aspectRatio: aspectRatio,
        viewMode: 1, // Restrict crop box to image size
        dragMode: 'move',
        autoCropArea: 0.9,
        restore: false,
        guides: true,
        center: true,
        highlight: false,
        cropBoxMovable: true,
        cropBoxResizable: true,
        toggleDragModeOnDblclick: false,
        background: false, // We use our own background
        checkCrossOrigin: false,
      });
    }
  }

  function handleImageLoad() {
    initCropper();
  }

  function rotate() {
    cropper?.rotate(90);
  }

  function zoom(ratio: number) {
    cropper?.zoom(ratio);
  }

  function reset() {
    cropper?.reset();
  }

  function cancel() {
    dispatch('cancel');
  }

  async function save() {
    if (!cropper) return;
    processing = true;

    // Small delay to allow UI to update
    await new Promise(resolve => setTimeout(resolve, 50));

    const canvas = cropper.getCroppedCanvas({
      // Reasonable limits for web profile images
      maxWidth: 1200,
      maxHeight: 1200,
      imageSmoothingQuality: 'high',
    });

    canvas.toBlob((blob) => {
      processing = false;
      if (blob) {
        dispatch('crop', { blob });
      }
    }, imageFile?.type || 'image/jpeg', 0.9);
  }
</script>

<div class="cropper-overlay" role="dialog" aria-modal="true">
  <div class="cropper-modal card">
    <div class="cropper-header">
      <h3>Edit Media</h3>
      <button class="btn-icon-close" on:click={cancel} aria-label="Close">
        <X size={20} />
      </button>
    </div>

    <div class="cropper-body">
      {#if objectUrl}
        <div class="img-container {circular ? 'circular-guide' : ''}">
          <!-- svelte-ignore a11y-img-redundant-alt -->
          <img
            bind:this={imageElement}
            src={objectUrl}
            alt="Image to crop"
            on:load={handleImageLoad}
            class="source-image"
          />
        </div>
      {:else}
        <div class="loading-state">
           <Loader2 class="animate-spin" size={32} />
        </div>
      {/if}
    </div>

    <div class="cropper-toolbar">
      <div class="toolbar-group">
        <button class="tool-btn" on:click={() => zoom(0.1)} title="Zoom In">
          <ZoomIn size={18} />
        </button>
        <button class="tool-btn" on:click={() => zoom(-0.1)} title="Zoom Out">
          <ZoomOut size={18} />
        </button>
      </div>

      <div class="toolbar-divider"></div>

      <div class="toolbar-group">
        <button class="tool-btn" on:click={rotate} title="Rotate 90°">
          <RotateCw size={18} />
        </button>
        <button class="tool-btn" on:click={reset} title="Reset">
          <RefreshCcw size={18} />
        </button>
      </div>
    </div>

    <div class="cropper-footer">
      <button class="btn-cancel" on:click={cancel} disabled={processing}>Cancel</button>
      <button class="btn-save" on:click={save} disabled={processing}>
        {#if processing}
          <Loader2 class="animate-spin" size={18} />
          <span>Saving...</span>
        {:else}
          <Check size={18} />
          <span>Apply</span>
        {/if}
      </button>
    </div>
  </div>
</div>

<style>
  .cropper-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background-color: rgba(0, 0, 0, 0.75);
    backdrop-filter: blur(8px);
    z-index: 9999;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 16px;
    box-sizing: border-box;
    animation: fade-in 0.2s ease-out;
  }

  @keyframes fade-in {
    from { opacity: 0; }
    to { opacity: 1; }
  }

  .cropper-modal {
    background-color: var(--bg-main, #fff);
    width: 100%;
    max-width: 520px; /* Optimal for profile pictures */
    border-radius: 20px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    max-height: 85vh;
    box-shadow: 0 20px 50px rgba(0,0,0,0.3);
    animation: slide-up 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    border: 1px solid var(--border-color, #e1e8ed);
  }

  @keyframes slide-up {
    from { transform: translateY(20px); opacity: 0; }
    to { transform: translateY(0); opacity: 1; }
  }

  .cropper-header {
    padding: 16px 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--border-color, #eff3f4);
    background-color: var(--bg-main, #fff);
  }

  .cropper-header h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 800;
    color: var(--text-main, #0f1419);
  }

  .btn-icon-close {
    background: transparent;
    border: none;
    cursor: pointer;
    padding: 8px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-main, #0f1419);
    transition: background-color 0.2s;
  }
  .btn-icon-close:hover {
    background-color: var(--bg-hover, rgba(15, 20, 25, 0.1));
  }

  .cropper-body {
    flex: 1;
    background-color: #111; /* Dark background for image editing specifically */
    position: relative;
    overflow: hidden;
    min-height: 300px;
    /* max-height is handled by flex modal */
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .img-container {
    width: 100%;
    height: 100%;
    /* Ensure image fits */
    max-height: 60vh;
  }

  .source-image {
    display: block;
    max-width: 100%;
    max-height: 100%;
  }

  .loading-state {
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100%;
    width: 100%;
  }

  /* Toolbar */
  .cropper-toolbar {
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 12px;
    padding: 12px;
    background-color: var(--bg-secondary, #f7f9f9);
    border-bottom: 1px solid var(--border-color, #eff3f4);
  }

  .toolbar-group {
    display: flex;
    gap: 4px;
    background-color: var(--bg-main, #fff);
    border-radius: 12px;
    padding: 4px;
    border: 1px solid var(--border-color, #cfd9de);
  }

  .toolbar-divider {
    width: 1px;
    height: 24px;
    background-color: var(--border-strong, #cfd9de);
    margin: 0 4px;
  }

  .tool-btn {
    background: transparent;
    border: none;
    width: 36px;
    height: 36px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--text-secondary, #536471);
    transition: all 0.2s;
  }

  .tool-btn:hover {
    background-color: var(--bg-hover, rgba(15, 20, 25, 0.1));
    color: var(--primary-color, #1d9bf0);
  }

  /* Footer */
  .cropper-footer {
    padding: 16px 20px;
    display: flex;
    justify-content: space-between; /* Spread out cancel and save */
    gap: 12px;
    background-color: var(--bg-main, #fff);
  }

  .btn-cancel {
    padding: 10px 24px;
    border: 1px solid var(--border-strong, #cfd9de);
    background: transparent;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    cursor: pointer;
    color: var(--text-main, #0f1419);
    transition: background-color 0.2s;
  }
  .btn-cancel:hover {
    background-color: var(--bg-hover, rgba(15, 20, 25, 0.1));
  }

  .btn-save {
    padding: 10px 24px;
    background-color: var(--text-main, #0f1419); /* Black primary button */
    color: var(--bg-main, #fff);
    border: 1px solid transparent;
    border-radius: 9999px;
    font-weight: 700;
    font-size: 15px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: opacity 0.2s;
    margin-left: auto; /* Push to right if we want, but justify-between handles it */
  }
  .btn-save:hover {
    opacity: 0.9;
  }
  .btn-save:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  /* Circular visual guide override */
  :global(.circular-guide .cropper-view-box),
  :global(.circular-guide .cropper-face) {
    border-radius: 50%;
  }

  /* Make the crop box outline cleaner */
  :global(.cropper-view-box) {
    outline: 2px solid var(--primary-color, #1d9bf0) !important;
    outline-color: rgba(255, 255, 255, 0.8) !important;
  }

  :global(.cropper-line) {
    background-color: rgba(255, 255, 255, 0.5) !important;
  }

  :global(.cropper-point) {
    background-color: var(--primary-color, #1d9bf0) !important;
    width: 8px !important;
    height: 8px !important;
  }
</style>
