<script lang="ts">
  import type { Snippet } from "svelte";
  import Dialog from "./dialog.svelte";
  import Frame from "./frame.svelte";
  import { createWorkspace } from "../model/workspace";

  interface Props {
    children?: Snippet;
  }

  const { children }: Props = $props();

  const workspace = createWorkspace();

  const expandedId = $derived.by(() => {
    const { layout, sessions } = $workspace;

    switch (layout.mode) {
      case "auto":
        return sessions[0]?.id;
      case "focused":
        return sessions.some((session) => session.id === layout.id) ? layout.id : sessions[0]?.id;
      case "compact":
        return undefined;
      default: {
        const exhaustive: never = layout;
        return exhaustive;
      }
    }
  });
</script>

{@render children?.()}

<div class="workspace">
  <section class="workspace__tiles" aria-label="Open game sessions">
    {#each $workspace.sessions as session (session.id)}
      {@const expanded = session.id === expandedId}
      <div
        class="workspace__window"
        class:workspace__window--expanded={expanded}
        class:workspace__window--compact={!expanded}
      >
        <Dialog label={`Game session ${session.id}`}>
          {#snippet children({ fullscreen, toggle })}
            {@const visible = expanded || fullscreen}

            <div class="workspace__game" class:workspace__game--compact={!visible} inert={!visible}>
              <Frame module={session.module} connection={session.connection} />
            </div>

            <div class="workspace__chrome" class:workspace__chrome--compact={!visible}>
              {#if !visible}
                <button
                  class="workspace__compact-restore"
                  type="button"
                  aria-label={`Expand Game session ${session.id}`}
                  aria-describedby={`workspace-status-${session.id} workspace-session-${session.id}`}
                  onclick={() => workspace.focus(session.id)}
                ></button>
                <span
                  class="workspace__compact-status"
                  id={`workspace-status-${session.id}`}
                  data-phase={session.phase}
                  data-transport-status={$workspace.status}
                >
                  <span class="workspace__status-dot" aria-hidden="true"></span>
                  <strong>
                    {#if $workspace.status === "failed"}
                      Failed
                    {:else if $workspace.status !== "ready"}
                      Reconnecting
                    {:else if session.phase === "finished"}
                      Finished
                    {:else}
                      Live
                    {/if}
                  </strong>
                </span>
                <span class="workspace__session-label" id={`workspace-session-${session.id}`}>
                  <span class="workspace__session-label-text">Session {session.id}</span>
                </span>
              {:else if $workspace.status !== "ready"}
                <div class="workspace__status" role="status">
                  <span class="workspace__spinner" aria-hidden="true"></span>
                  <strong>
                    {#if $workspace.status === "stale"}
                      Reconnecting to game
                    {:else if $workspace.status === "failed"}
                      Connection to game failed
                    {:else}
                      Connecting to game
                    {/if}
                  </strong>
                </div>
              {/if}

              <div
                class="workspace__window-controls"
                class:workspace__window-controls--compact={!visible}
                role="group"
                aria-label={`Game session ${session.id} window controls`}
              >
                <button
                  class="workspace__window-control workspace__window-control--close"
                  type="button"
                  aria-label={`Close Game session ${session.id}`}
                  onclick={() => workspace.close(session.id)}
                >
                  <svg viewBox="0 0 16 16" aria-hidden="true">
                    <path d="m1 1 14 14M15 1 1 15" />
                  </svg>
                </button>

                <button
                  class="workspace__window-control workspace__window-control--fullscreen"
                  type="button"
                  aria-label={fullscreen
                    ? `Exit Game session ${session.id} fullscreen`
                    : `Enter Game session ${session.id} fullscreen`}
                  onclick={toggle}
                >
                  {#if fullscreen}
                    <svg viewBox="0 0 16 16" aria-hidden="true">
                      <path d="M1 6h5V1M15 6h-5V1M1 10h5v5M15 10h-5v5" />
                    </svg>
                  {:else}
                    <svg viewBox="0 0 16 16" aria-hidden="true">
                      <path d="M6 1H1v5M10 1h5v5M6 15H1v-5M10 15h5v-5" />
                    </svg>
                  {/if}
                </button>

                {#if expanded && !fullscreen}
                  <button
                    class="workspace__window-control workspace__window-control--layout"
                    type="button"
                    aria-label={`Compact Game session ${session.id}`}
                    onclick={() => workspace.compact()}
                  >
                    <svg viewBox="0 0 16 16" aria-hidden="true">
                      <path d="M1 15h14" />
                    </svg>
                  </button>
                {/if}
              </div>
            </div>
          {/snippet}
        </Dialog>
      </div>
    {/each}
  </section>
</div>

<style>
  .workspace {
    position: relative;
    z-index: 900;
  }

  .workspace__tiles {
    position: fixed;
    z-index: 900;
    inset-inline-end: max(0.75rem, env(safe-area-inset-right, 0px));
    inset-block-end: max(0.75rem, env(safe-area-inset-bottom, 0px));
    display: grid;
    inline-size: min(32rem, calc(100dvi - 1.5rem));
    max-block-size: calc(100dvb - 1.5rem);
    grid-template-columns: minmax(0, 1fr);
    grid-auto-rows: auto;
    gap: 0.375rem;
    overflow: auto;
    pointer-events: none;
    scrollbar-width: thin;
  }

  .workspace__window {
    position: relative;
    z-index: 1;
    min-inline-size: 0;
    min-block-size: 0;
    pointer-events: auto;
  }

  .workspace__window--compact {
    --dialog-surface-background: var(--color-base-content);
    --dialog-surface-color: var(--color-base-100);
    --dialog-surface-shadow: none;
  }

  .workspace__window--expanded {
    position: fixed;
    z-index: 2;
    inset-block-start: max(0.5rem, env(safe-area-inset-top, 0px));
    inset-inline-end: max(0.5rem, env(safe-area-inset-right, 0px));
    inset-block-end: max(0.5rem, env(safe-area-inset-bottom, 0px));
    inset-inline-start: max(0.5rem, env(safe-area-inset-left, 0px));
  }

  .workspace__game {
    position: absolute;
    inset: 0;
  }

  .workspace__game--compact {
    display: none;
    pointer-events: none;
  }

  @supports (content-visibility: hidden) {
    .workspace__game--compact {
      display: block;
      content-visibility: hidden;
    }
  }

  .workspace__chrome {
    display: contents;
  }

  .workspace__chrome--compact {
    box-sizing: border-box;
    position: relative;
    display: flex;
    block-size: auto;
    min-inline-size: 0;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem;
  }

  .workspace__compact-restore {
    position: absolute;
    z-index: 0;
    inset: 0;
    border: 0;
    background: transparent;
    appearance: none;
    padding: 0;
    cursor: pointer;
  }

  .workspace__compact-restore:focus-visible {
    outline: none;
  }

  .workspace__chrome--compact:has(> .workspace__compact-restore:focus-visible) {
    outline: 2px solid currentColor;
    outline-offset: -2px;
  }

  .workspace__compact-status {
    box-sizing: border-box;
    position: relative;
    z-index: 1;
    display: inline-flex;
    min-inline-size: 5.25rem;
    block-size: 1.875rem;
    flex: none;
    align-items: center;
    justify-content: center;
    gap: 0.3rem;
    border: 1px solid color-mix(in oklab, currentColor 32%, transparent);
    border-radius: var(--radius-sm);
    background: white;
    padding: 0.25rem 0.4rem;
    color: var(--color-base-content);
    font-size: 0.75rem;
    line-height: 1;
    pointer-events: none;
    text-transform: uppercase;
  }

  .workspace__status-dot {
    inline-size: 0.45rem;
    block-size: 0.45rem;
    flex: none;
    border-radius: 50%;
    background: color-mix(in oklab, var(--color-base-content) 48%, transparent);
  }

  :where(.workspace__compact-status[data-transport-status="ready"][data-phase="in_progress"])
    .workspace__status-dot {
    background: var(--color-success);
    animation: workspace-status-pulse 1.2s ease-in-out infinite;
  }

  :where(
      .workspace__compact-status:not([data-transport-status="ready"]):not(
          [data-transport-status="failed"]
        )
    )
    .workspace__status-dot {
    background: var(--color-warning);
    animation: workspace-status-pulse 0.8s ease-in-out infinite;
  }

  :where(.workspace__compact-status[data-transport-status="failed"]) .workspace__status-dot {
    background: var(--color-error);
  }

  .workspace__session-label {
    position: relative;
    z-index: 1;
    container-type: inline-size;
    flex: 1;
    min-inline-size: 0;
    overflow: hidden;
    color: white;
    pointer-events: none;
    white-space: nowrap;
  }

  @supports (overflow: clip) {
    .workspace__session-label {
      overflow: clip;
    }
  }

  .workspace__session-label-text {
    display: block;
    inline-size: max-content;
    animation: workspace-session-pan 5.8333s ease-in-out infinite alternate;
  }

  .workspace__compact-restore:hover ~ .workspace__session-label .workspace__session-label-text {
    animation-play-state: paused;
  }

  .workspace__window-controls {
    position: absolute;
    inset-block-start: 0.4rem;
    inset-inline-end: 0.4rem;
    z-index: 2;
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  .workspace__window-controls--compact {
    position: static;
    flex: none;
    flex-direction: row;
    translate: none;
  }

  .workspace__window-control--close {
    order: 1;
  }

  .workspace__window-control--layout {
    order: 2;
  }

  .workspace__window-control--fullscreen {
    order: 3;
  }

  .workspace__window-controls--compact .workspace__window-control--fullscreen {
    order: 2;
  }

  .workspace__window-controls--compact .workspace__window-control--close {
    order: 3;
  }

  .workspace__window-control {
    box-sizing: border-box;
    display: grid;
    inline-size: 1.875rem;
    block-size: 1.875rem;
    place-items: center;
    border: 1px solid rgb(255 255 255 / 0.32);
    border-radius: var(--radius-sm);
    background: rgb(0 0 0 / 0.76);
    padding: 0.25rem;
    color: white;
    cursor: pointer;
  }

  .workspace__window-control:hover:not(:disabled) {
    background: rgb(0 0 0 / 0.92);
  }

  .workspace__window-controls--compact .workspace__window-control {
    border-color: color-mix(in oklab, var(--color-base-content) 32%, transparent);
    background: var(--color-base-100);
    color: var(--color-base-content);
  }

  .workspace__window-controls--compact .workspace__window-control:hover:not(:disabled) {
    background: color-mix(in oklab, var(--color-base-100) 88%, var(--color-base-content));
  }

  .workspace__window-control:focus-visible {
    outline: 2px solid white;
    outline-offset: 2px;
  }

  .workspace__window-control:disabled {
    cursor: not-allowed;
    opacity: 0.5;
  }

  .workspace__window-control svg {
    inline-size: 0.9375rem;
    block-size: 0.9375rem;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 1.5;
  }

  .workspace__status {
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

  .workspace__spinner {
    inline-size: 1.5rem;
    block-size: 1.5rem;
    border: 2px solid color-mix(in oklab, currentColor 25%, transparent);
    border-block-start-color: currentColor;
    border-radius: 50%;
    animation: workspace-spin 0.8s linear infinite;
  }

  @keyframes workspace-spin {
    to {
      rotate: 1turn;
    }
  }

  @keyframes workspace-status-pulse {
    50% {
      opacity: 0.25;
    }
  }

  @keyframes workspace-session-pan {
    0%,
    12% {
      translate: 0;
    }

    88%,
    100% {
      translate: min(0px, calc(100cqi - 100%));
    }
  }

  @media (max-width: 48rem) {
    .workspace__tiles {
      inset-inline-start: max(0.75rem, env(safe-area-inset-left, 0px));
      inline-size: auto;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .workspace__spinner,
    .workspace__status-dot,
    .workspace__session-label-text {
      animation: none;
    }
  }
</style>
