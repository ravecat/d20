<script lang="ts">
  import type { Snippet } from "svelte";

  interface Props {
    children: Snippet;
    label: string;
  }

  type Mode = "compact" | "theater";

  const { children, label }: Props = $props();

  let mode = $state<Mode>("theater");
  let dialog = $state<HTMLDialogElement>();
  let fullscreenElement = $state<HTMLDivElement>();
  let fullscreen = $state(false);

  function show(nextMode: Mode) {
    mode = nextMode;
  }

  function handleCancel(event: Event) {
    event.preventDefault();

    if (!fullscreen) show("compact");
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

  $effect(() => {
    if (!dialog) return;

    if (dialog.open) dialog.close();

    if (mode === "theater") {
      dialog.showModal();
    } else {
      dialog.show();
    }

    return () => {
      if (dialog?.open) dialog.close();
    };
  });
</script>

<svelte:document onfullscreenchange={synchronizeFullscreen} />

<dialog
  bind:this={dialog}
  class="dialog"
  class:dialog--compact={mode === "compact"}
  class:dialog--theater={mode === "theater"}
  aria-label={label}
  closedby={mode === "theater" ? "any" : undefined}
  oncancel={handleCancel}
>
  <div bind:this={fullscreenElement} class="dialog__fullscreen">
    {@render children()}

    <div class="dialog__controls">
      {#if !fullscreen}
        {#if mode === "theater"}
          <button
            class="dialog__control"
            type="button"
            aria-label="Compact game view"
            onclick={() => show("compact")}
          >
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M3 5h18v14H3zM12 19v-7h9" />
            </svg>
          </button>
        {:else}
          <button
            class="dialog__control"
            type="button"
            aria-label="Theater game view"
            onclick={() => show("theater")}
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
        aria-label={fullscreen ? "Exit fullscreen" : "Enter fullscreen"}
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
    position: fixed;
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
    background: rgb(0 0 0 / 0.42);
  }

  .dialog--theater {
    inset: 0;
    inline-size: min(96dvw, 72rem);
    block-size: min(90dvh, 42rem);
    margin: auto;
  }

  .dialog--compact {
    inset-block-start: auto;
    inset-inline-start: auto;
    inset-inline-end: max(0.75rem, env(safe-area-inset-right));
    inset-block-end: max(0.75rem, env(safe-area-inset-bottom));
    inline-size: min(24rem, calc(100dvw - 1.5rem));
    block-size: min(14rem, calc(100dvh - 1.5rem));
  }

  .dialog__fullscreen {
    position: relative;
    inline-size: 100%;
    block-size: 100%;
    overflow: clip;
    border-radius: var(--radius-sm);
    background: white;
    box-shadow: 0 1.5rem 4rem rgb(0 0 0 / 0.34);
  }

  .dialog__fullscreen:fullscreen {
    border-radius: 0;
  }

  .dialog__controls {
    position: absolute;
    inset-block-start: 0.5rem;
    inset-inline-end: 0.5rem;
    z-index: 1;
    display: flex;
    gap: 0.375rem;
  }

  .dialog__control {
    display: grid;
    inline-size: 2.5rem;
    block-size: 2.5rem;
    place-items: center;
    border: 1px solid rgb(255 255 255 / 0.32);
    border-radius: var(--radius-sm);
    background: rgb(0 0 0 / 0.72);
    padding: 0.5rem;
    color: white;
    cursor: pointer;
  }

  .dialog__control:hover:not(:disabled) {
    background: rgb(0 0 0 / 0.88);
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

  @media (max-width: 34rem) {
    .dialog--theater {
      inline-size: calc(100dvw - 1rem);
      block-size: calc(100dvh - 1rem);
    }

    .dialog--compact {
      inset-inline-end: max(0.5rem, env(safe-area-inset-right));
      inset-block-end: max(0.5rem, env(safe-area-inset-bottom));
      inline-size: calc(100dvw - 1rem);
      block-size: min(13rem, 40dvh);
    }
  }
</style>
