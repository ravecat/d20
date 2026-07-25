<script lang="ts">
  import type { WorkspaceEntry } from "~types/workspace";

  interface Props {
    entries: WorkspaceEntry[];
  }

  const { entries }: Props = $props();

  function gameLabel(slug: string) {
    return slug
      .split("-")
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(" ");
  }

  function runtimeStatus(entry: WorkspaceEntry) {
    if (entry.closing) return "Leaving";
    if (entry.closeError) return "Leave failed";
    if (entry.channelStatus === "stale") return "Reconnecting";
    if (entry.channelStatus === "failed") return "Connection failed";
    if (entry.channelStatus === "ready") return "Connected";
    return "Connecting";
  }
</script>

{#if entries.length > 0}
  <aside class="workspace-dock" aria-label="Workspace sessions">
    <div class="workspace-dock__heading">
      <span>Workspace</span>
      <span class="workspace-dock__count" aria-label={`${entries.length} attached sessions`}>
        {entries.length.toString().padStart(2, "0")}
      </span>
    </div>

    <ul class="workspace-dock__list">
      {#each entries as entry (entry.id)}
        {@const game = gameLabel(entry.slug)}
        <li
          class="workspace-dock__item"
          aria-current={entry.mode === "theater" ? "true" : undefined}
        >
          <div class="workspace-dock__identity">
            <span class="workspace-dock__signal" data-status={entry.channelStatus}></span>
            <span class="workspace-dock__name">{game}</span>
            <span class="workspace-dock__meta">
              {entry.id.slice(0, 8)} · {runtimeStatus(entry)} · {entry.mode}
            </span>
          </div>
        </li>
      {/each}
    </ul>
  </aside>
{/if}

<style>
  .workspace-dock {
    position: fixed;
    z-index: 950;
    inset-inline: max(0.75rem, env(safe-area-inset-left, 0px))
      max(0.75rem, env(safe-area-inset-right, 0px));
    inset-block-end: max(0.75rem, env(safe-area-inset-bottom, 0px));
    display: grid;
    max-block-size: min(17rem, 45dvh);
    grid-template-columns: auto minmax(0, 1fr);
    overflow: hidden;
    border: 1px solid color-mix(in oklab, var(--color-base-content) 22%, transparent);
    border-radius: var(--radius-sm);
    background: color-mix(in oklab, var(--color-base-100) 94%, transparent);
    box-shadow: 0 1rem 3rem rgb(0 0 0 / 0.18);
    color: var(--color-base-content);
    backdrop-filter: blur(12px);
  }

  .workspace-dock__heading {
    display: flex;
    min-inline-size: 8rem;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    border-inline-end: 1px solid color-mix(in oklab, var(--color-base-content) 14%, transparent);
    padding: 0.75rem 0.875rem;
    font-size: 0.7rem;
    font-weight: 750;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  .workspace-dock__count {
    color: color-mix(in oklab, var(--color-base-content) 54%, transparent);
    font-variant-numeric: tabular-nums;
  }

  .workspace-dock__list {
    display: flex;
    min-inline-size: 0;
    gap: 0.5rem;
    margin: 0;
    overflow-x: auto;
    padding: 0.45rem;
    list-style: none;
    scrollbar-width: thin;
  }

  .workspace-dock__item {
    display: flex;
    min-inline-size: min(22rem, 78dvw);
    align-items: center;
    justify-content: space-between;
    gap: 0.75rem;
    border: 1px solid color-mix(in oklab, var(--color-base-content) 12%, transparent);
    border-radius: calc(var(--radius-sm) * 0.75);
    background: var(--color-base-100);
    padding: 0.45rem 0.5rem 0.45rem 0.65rem;
  }

  .workspace-dock__item[aria-current="true"] {
    border-color: color-mix(in oklab, var(--color-base-content) 46%, transparent);
    box-shadow: inset 3px 0 0 var(--color-base-content);
  }

  .workspace-dock__identity {
    display: grid;
    min-inline-size: 0;
    grid-template-columns: auto minmax(0, 1fr);
    column-gap: 0.45rem;
  }

  .workspace-dock__signal {
    inline-size: 0.45rem;
    block-size: 0.45rem;
    align-self: center;
    border-radius: 50%;
    background: var(--color-warning, #d28b26);
  }

  .workspace-dock__signal[data-status="ready"] {
    background: var(--color-success, #2f8f55);
  }

  .workspace-dock__signal[data-status="failed"] {
    background: var(--color-error, #bb3b3b);
  }

  .workspace-dock__name {
    overflow: hidden;
    font-size: 0.75rem;
    font-weight: 700;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .workspace-dock__meta {
    grid-column: 2;
    color: color-mix(in oklab, var(--color-base-content) 56%, transparent);
    font-size: 0.625rem;
    letter-spacing: 0.02em;
    text-transform: capitalize;
  }

  @media (max-width: 48rem) {
    .workspace-dock {
      grid-template-columns: minmax(0, 1fr);
    }

    .workspace-dock__heading {
      min-inline-size: 0;
      border-inline-end: 0;
      border-block-end: 1px solid color-mix(in oklab, var(--color-base-content) 14%, transparent);
      padding-block: 0.5rem;
    }
  }

  @media (max-width: 34rem) {
    .workspace-dock__item {
      min-inline-size: calc(100dvw - 2.5rem);
      align-items: stretch;
      flex-direction: column;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .workspace-dock {
      backdrop-filter: none;
    }
  }
</style>
