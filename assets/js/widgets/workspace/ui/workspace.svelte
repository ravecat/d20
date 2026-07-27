<script lang="ts">
  import type { Snippet } from "svelte";
  import Dialog from "./dialog.svelte";
  import Frame from "./frame.svelte";
  import type { WorkspaceLayout, WorkspaceSessionDescriptor } from "../model/workspace";
  import { createWorkspace } from "../model/workspace";

  interface Props {
    children?: Snippet;
  }

  const { children }: Props = $props();

  const workspace = createWorkspace();

  function isExpanded(
    layout: WorkspaceLayout,
    sessions: WorkspaceSessionDescriptor[],
    id: string,
    index: number,
  ) {
    switch (layout.mode) {
      case "auto":
        return index === 0;
      case "focused":
        return sessions.some((session) => session.id === layout.id)
          ? id === layout.id
          : index === 0;
      case "compact":
        return false;
      default: {
        const exhaustive: never = layout;
        return exhaustive;
      }
    }
  }
</script>

{@render children?.()}

<div class="workspace">
  <section class="workspace__tiles" aria-label="Open game sessions">
    {#each $workspace.sessions as session, index (session.id)}
      {@const expanded = isExpanded($workspace.layout, $workspace.sessions, session.id, index)}
      <div class="workspace__window" class:workspace__window--expanded={expanded}>
        <Dialog label={`Game session ${session.id}`} onClose={() => workspace.close(session.id)}>
          <Frame module={session.module} connection={session.connection} />

          {#if $workspace.status !== "ready"}
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
        </Dialog>

        <button
          class="workspace__layout-control"
          type="button"
          aria-label={`${expanded ? "Compact" : "Expand"} Game session ${session.id}`}
          onclick={() => (expanded ? workspace.compact() : workspace.focus(session.id))}
        >
          {#if expanded}
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M3 5h18v14H3zM12 19v-7h9" />
            </svg>
          {:else}
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M3 5h18v14H3zM6 8h12v8H6z" />
            </svg>
          {/if}
        </button>
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
    inline-size: 50vw;
    block-size: max(25dvh, 8rem);
    grid-template-columns: repeat(auto-fit, minmax(min(19rem, 100%), 1fr));
    grid-auto-rows: minmax(8rem, 1fr);
    gap: 0.75rem;
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

  .workspace__window--expanded {
    position: fixed;
    z-index: 2;
    inset-block-start: max(0.5rem, env(safe-area-inset-top, 0px));
    inset-inline-end: max(0.5rem, env(safe-area-inset-right, 0px));
    inset-block-end: max(0.5rem, env(safe-area-inset-bottom, 0px));
    inset-inline-start: max(0.5rem, env(safe-area-inset-left, 0px));
  }

  .workspace__layout-control {
    position: absolute;
    z-index: 1001;
    inset-block-start: 5rem;
    inset-inline-end: 0.4rem;
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

  .workspace__layout-control:hover {
    background: rgb(0 0 0 / 0.92);
  }

  .workspace__layout-control:focus-visible {
    outline: 2px solid white;
    outline-offset: 2px;
  }

  .workspace__layout-control svg {
    inline-size: 100%;
    block-size: 100%;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 1.75;
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

  @media (max-width: 48rem) {
    .workspace__tiles {
      inset-inline-start: max(0.75rem, env(safe-area-inset-left, 0px));
      inline-size: auto;
      grid-template-columns: minmax(0, 1fr);
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .workspace__spinner {
      animation: none;
    }
  }
</style>
