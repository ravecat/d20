<script lang="ts">
  import type { Snippet } from "svelte";
  import type { Attachment } from "svelte/attachments";
  import type { WorkspaceMode } from "~types/workspace";

  interface Props {
    children: Snippet;
    closing: boolean;
    label: string;
    mode: WorkspaceMode;
    onCompact: () => void;
    onClose: () => void;
    onExpand: () => void;
  }

  const { children, closing, label, mode, onCompact, onClose, onExpand }: Props = $props();

  let fullscreenElement: HTMLDivElement | undefined;
  let fullscreen = $state(false);

  function handleCancel(event: Event) {
    event.preventDefault();

    if (!fullscreen && mode === "theater") onCompact();
  }

  function handleClose(event: Event) {
    const dialog = event.currentTarget;
    if (dialog instanceof HTMLDialogElement && !dialog.open && mode === "theater") onCompact();
  }

  function synchronizeFullscreen() {
    fullscreen = document.fullscreenElement === fullscreenElement;
  }

  async function toggleFullscreen() {
    if (!fullscreenElement) return;

    try {
      if (document.fullscreenElement === fullscreenElement) {
        await document.exitFullscreen();
      } else {
        await fullscreenElement.requestFullscreen({ navigationUI: "hide" });
      }
    } catch {
      return;
    }
  }

  function showDialog(currentMode: WorkspaceMode): Attachment<HTMLDialogElement> {
    return (dialog) => {
      if (currentMode === "theater") {
        dialog.showModal();
      } else {
        dialog.show();
      }

      return () => {
        if (dialog.open) dialog.close();
      };
    };
  }

  const captureFullscreenElement: Attachment<HTMLDivElement> = (element) => {
    fullscreenElement = element;

    return () => {
      if (fullscreenElement === element) fullscreenElement = undefined;
    };
  };
</script>

<svelte:document onfullscreenchange={synchronizeFullscreen} />

<dialog
  {@attach showDialog(mode)}
  class="dialog"
  class:dialog--compact={mode === "compact"}
  class:dialog--theater={mode === "theater"}
  aria-label={label}
  closedby={mode === "theater" ? "any" : undefined}
  oncancel={handleCancel}
  onclose={handleClose}
>
  <div {@attach captureFullscreenElement} class="dialog__surface">
    {@render children()}

    <div class="dialog__controls" aria-label={`${label} window controls`}>
      {#if !fullscreen}
        {#if mode === "compact"}
          <button
            class="dialog__control"
            type="button"
            aria-label={`Expand ${label}`}
            onclick={onExpand}
          >
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M3 5h18v14H3zM6 8h12v8H6z" />
            </svg>
          </button>
        {/if}
      {/if}

      <button
        class="dialog__control"
        type="button"
        aria-label={`Close ${label}`}
        aria-busy={closing}
        disabled={closing}
        onclick={onClose}
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="m6 6 12 12M18 6 6 18" />
        </svg>
      </button>

      <button
        class="dialog__control"
        type="button"
        aria-label={fullscreen ? `Exit ${label} fullscreen` : `Enter ${label} fullscreen`}
        onclick={toggleFullscreen}
      >
        {#if fullscreen}
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5" />
          </svg>
        {:else}
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path d="M9 4H4v5M15 4h5v5M9 20H4v-5M15 20h5v-5" />
          </svg>
        {/if}
      </button>
    </div>
  </div>
</dialog>

<style>
  .dialog {
    z-index: 1000;
    box-sizing: border-box;
    max-inline-size: none;
    max-block-size: none;
    margin: 0;
    overflow: visible;
    border: 0;
    background: transparent;
    padding: 0;
    color: inherit;
  }

  .dialog::backdrop {
    background: rgb(10 12 14 / 0.54);
    backdrop-filter: blur(2px);
  }

  .dialog--theater {
    position: fixed;
    inset-block-start: max(0.5rem, env(safe-area-inset-top, 0px));
    inset-inline-end: max(0.5rem, env(safe-area-inset-right, 0px));
    inset-block-end: max(0.5rem, env(safe-area-inset-bottom, 0px));
    inset-inline-start: max(0.5rem, env(safe-area-inset-left, 0px));
    inline-size: auto;
    block-size: auto;
  }

  .dialog--compact {
    position: relative;
    inset: auto;
    inline-size: 100%;
    min-inline-size: 0;
    block-size: clamp(12rem, 28dvh, 18rem);
  }

  .dialog__surface {
    position: relative;
    box-sizing: border-box;
    inline-size: 100%;
    block-size: 100%;
    overflow: auto;
    border: 1px solid color-mix(in oklab, var(--color-base-content) 16%, transparent);
    border-radius: var(--radius-sm);
    background: var(--color-base-100);
    box-shadow: 0 1.5rem 4rem rgb(0 0 0 / 0.34);
  }

  .dialog__surface:fullscreen {
    border: 0;
    border-radius: 0;
  }

  .dialog__controls {
    position: absolute;
    inset-block-start: 0.4rem;
    inset-inline-end: 0.4rem;
    z-index: 2;
    display: flex;
    gap: 0.3rem;
  }

  .dialog__control {
    box-sizing: border-box;
    display: grid;
    inline-size: 2rem;
    block-size: 2rem;
    place-items: center;
    border: 1px solid rgb(255 255 255 / 0.32);
    border-radius: var(--radius-sm);
    background: rgb(0 0 0 / 0.76);
    padding: 0.4rem;
    color: white;
    cursor: pointer;
  }

  .dialog__control:hover:not(:disabled) {
    background: rgb(0 0 0 / 0.92);
  }

  .dialog__control:focus-visible {
    outline: 2px solid white;
    outline-offset: 2px;
  }

  .dialog__control:disabled {
    cursor: not-allowed;
    opacity: 0.5;
  }

  .dialog__control svg {
    inline-size: 100%;
    block-size: 100%;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 1.75;
  }

  @media (prefers-reduced-motion: reduce) {
    .dialog::backdrop {
      backdrop-filter: none;
    }
  }
</style>
