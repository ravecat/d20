<script lang="ts">
  import GameWindow from "./game_window.svelte";
  import type { WorkspaceStore } from "~/shared/stores";
  import type { WorkspaceEntry } from "~/shared/types";

  interface Props {
    workspace: WorkspaceStore;
  }

  const { workspace }: Props = $props();

  function gameLabel(slug: string) {
    return slug
      .split("-")
      .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
      .join(" ");
  }

  function entryLabel(entry: WorkspaceEntry) {
    return `${gameLabel(entry.slug)} session ${entry.id}`;
  }

  function statusMessage(entry: WorkspaceEntry) {
    if (entry.closeError) return entry.closeError;
    if (entry.closing) return `Closing ${gameLabel(entry.slug)}`;
    if (entry.channelStatus === "stale") return `Reconnecting to ${gameLabel(entry.slug)}`;
    if (entry.channelStatus === "failed") return `Connection to ${gameLabel(entry.slug)} failed`;
    return `Connecting to ${gameLabel(entry.slug)}`;
  }
</script>

<div class="workspace">
  <section class="workspace__tiles" aria-label="Open game sessions">
    {#each $workspace.entries as entry (entry.id)}
      {@const label = entryLabel(entry)}
      <GameWindow
        {label}
        mode={entry.mode}
        module={entry.module}
        connection={entry.connection}
        status={entry.channelStatus}
        closing={entry.closing}
        closeError={entry.closeError}
        statusMessage={statusMessage(entry)}
        onCompact={() => workspace.compact(entry.id)}
        onExpand={() => workspace.focus(entry.id)}
        onClose={() => workspace.close(entry.id)}
      />
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

  .workspace__tiles :global(dialog) {
    pointer-events: auto;
  }

  @media (max-width: 48rem) {
    .workspace__tiles {
      inset-inline-start: max(0.75rem, env(safe-area-inset-left, 0px));
      inline-size: auto;
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>
