<script lang="ts">
  import Dialog from "~components/dialog.svelte";
  import Frame from "~components/frame.svelte";
  import type { ModuleConnection, ModuleEntry } from "~types/module";
  import type { WorkspaceChannelStatus, WorkspaceMode } from "~types/workspace";

  interface Props {
    connection: ModuleConnection;
    closeError: string | null;
    closing: boolean;
    label: string;
    mode: WorkspaceMode;
    module: ModuleEntry;
    onCompact: () => void;
    onClose: () => void;
    onExpand: () => void;
    status: WorkspaceChannelStatus;
    statusMessage: string;
  }

  const {
    connection,
    closeError,
    closing,
    label,
    mode,
    module,
    onCompact,
    onClose,
    onExpand,
    status,
    statusMessage,
  }: Props = $props();
</script>

<Dialog {label} {mode} {closing} {onCompact} {onClose} {onExpand}>
  <Frame {module} {connection} />

  {#if status !== "ready" || closing || closeError}
    <div class="game-window__status" role={closeError ? "alert" : "status"}>
      <span class="game-window__spinner" aria-hidden="true"></span>
      <strong>{statusMessage}</strong>
      {#if closeError}
        <button type="button" onclick={onClose}>Try again</button>
      {/if}
    </div>
  {/if}
</Dialog>

<style>
  .game-window__status {
    position: absolute;
    inset: 0;
    z-index: 1;
    display: grid;
    place-content: center;
    justify-items: center;
    gap: 0.75rem;
    background: color-mix(in oklab, var(--color-base-100) 88%, transparent);
    padding: 1rem;
    color: var(--color-base-content);
    text-align: center;
    backdrop-filter: blur(3px);
  }

  .game-window__spinner {
    inline-size: 1.5rem;
    block-size: 1.5rem;
    border: 2px solid color-mix(in oklab, currentColor 25%, transparent);
    border-block-start-color: currentColor;
    border-radius: 50%;
    animation: game-window-spin 0.8s linear infinite;
  }

  .game-window__status button {
    min-block-size: 2.25rem;
    border: 1px solid currentColor;
    border-radius: var(--radius-sm);
    background: transparent;
    padding-inline: 0.75rem;
    color: inherit;
    font: inherit;
    cursor: pointer;
  }

  .game-window__status button:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }

  @keyframes game-window-spin {
    to {
      rotate: 1turn;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .game-window__spinner {
      animation: none;
    }
  }
</style>
