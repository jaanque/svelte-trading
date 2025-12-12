<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import Cropper from 'cropperjs';
  import 'cropperjs/dist/cropper.css';
  import { X, Check, RotateCw, ZoomIn, ZoomOut, RefreshCcw } from 'lucide-svelte';

  export let imageFile: File | null = null;
  export let aspectRatio: number = 1; // Default square
  export let circular: boolean = false; // For visual guidance only (CropperJS crops rects)

  const dispatch = createEventDispatcher();
  let imageElement: HTMLImageElement;
  let cropper: Cropper | null = null;
  let objectUrl: string | null = null;

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
        autoCropArea: 0.8,
        restore: false,
        guides: true,
        center: true,
        highlight: false,
        cropBoxMovable: true,
        cropBoxResizable: true,
        toggleDragModeOnDblclick: false,
        background: false // We use our own background
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

  function save() {
    if (!cropper) return;

    const canvas = cropper.getCroppedCanvas({
      // You might want to limit max size here for performance/storage
      maxWidth: 1024,
      maxHeight: 1024,
      imageSmoothingQuality: 'high',
    });

    canvas.toBlob((blob) => {
      if (blob) {
        dispatch('crop', { blob });
      }
    }, imageFile?.type || 'image/jpeg', 0.9);
  }
</script>

<div class="cropper-overlay">
  <div class="cropper-modal">
    <div class="cropper-header">
      <h3>Edit Image</h3>
      <button class="btn-icon" on:click={cancel}><X size={24} /></button>
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
      {/if}
    </div>

    <div class="cropper-controls">
      <button class="control-btn" on:click={() => zoom(0.1)} title="Zoom In"><ZoomIn size={20} /></button>
      <button class="control-btn" on:click={() => zoom(-0.1)} title="Zoom Out"><ZoomOut size={20} /></button>
      <button class="control-btn" on:click={rotate} title="Rotate"><RotateCw size={20} /></button>
      <button class="control-btn" on:click={reset} title="Reset"><RefreshCcw size={20} /></button>
    </div>

    <div class="cropper-footer">
      <button class="btn-cancel" on:click={cancel}>Cancel</button>
      <button class="btn-save" on:click={save}>
        <Check size={18} />
        <span>Save & Upload</span>
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
    background-color: rgba(0, 0, 0, 0.85);
    z-index: 9999;
    display: flex;
    justify-content: center;
    align-items: center;
    padding: 20px;
    box-sizing: border-box;
  }

  .cropper-modal {
    background-color: var(--bg-main, #fff);
    width: 100%;
    max-width: 600px;
    border-radius: 16px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    max-height: 90vh;
    box-shadow: 0 4px 20px rgba(0,0,0,0.5);
  }

  .cropper-header {
    padding: 16px 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--border-color, #eee);
  }

  .cropper-header h3 {
    margin: 0;
    font-size: 18px;
    font-weight: 700;
  }

  .btn-icon {
    background: none;
    border: none;
    cursor: pointer;
    padding: 4px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-secondary, #666);
  }
  .btn-icon:hover {
    background-color: var(--bg-hover, #f5f5f5);
  }

  .cropper-body {
    flex: 1;
    background-color: #000;
    position: relative;
    overflow: hidden;
    min-height: 300px;
    max-height: 500px; /* Limit height */
  }

  .img-container {
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
  }

  .source-image {
    display: block;
    max-width: 100%;
    max-height: 100%;
  }

  .cropper-controls {
    display: flex;
    justify-content: center;
    gap: 16px;
    padding: 12px;
    background-color: var(--bg-secondary, #f9f9f9);
    border-bottom: 1px solid var(--border-color, #eee);
  }

  .control-btn {
    background: none;
    border: 1px solid var(--border-strong, #ddd);
    width: 40px;
    height: 40px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    color: var(--text-main, #333);
    transition: all 0.2s;
  }

  .control-btn:hover {
    background-color: var(--bg-hover, #eee);
    border-color: var(--text-secondary, #999);
  }

  .cropper-footer {
    padding: 16px 20px;
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    background-color: var(--bg-main, #fff);
  }

  .btn-cancel {
    padding: 10px 20px;
    border: 1px solid var(--border-color, #ddd);
    background: transparent;
    border-radius: 99px;
    font-weight: 600;
    cursor: pointer;
    color: var(--text-secondary, #666);
  }
  .btn-cancel:hover {
    background-color: var(--bg-hover, #f5f5f5);
  }

  .btn-save {
    padding: 10px 24px;
    background-color: var(--primary-color, #000);
    color: white;
    border: none;
    border-radius: 99px;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    transition: opacity 0.2s;
  }
  .btn-save:hover {
    opacity: 0.9;
  }

  /* Circular visual guide override */
  :global(.circular-guide .cropper-view-box),
  :global(.circular-guide .cropper-face) {
    border-radius: 50%;
  }
</style>
