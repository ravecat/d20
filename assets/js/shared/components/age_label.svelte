<script module lang="ts">
  import type { GameMetadata } from "~/shared/types/game";

  function formatAge(game: GameMetadata) {
    const age = positiveInteger(game.minAge);

    return age ? `${age}+` : null;
  }

  function positiveInteger(value?: GameMetadata["minAge"]) {
    return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : null;
  }
</script>

<script lang="ts">
  type Props = {
    game: GameMetadata;
  };

  const { game }: Props = $props();
  const label = $derived(formatAge(game));
</script>

{#if label}
  <div class="game-metadata-label" aria-label="Age"><span>{label}</span></div>
{/if}

<style>
  .game-metadata-label {
    box-sizing: border-box;
    display: inline-flex;
    block-size: 2.2em;
    min-inline-size: 3.1em;
    align-items: center;
    justify-content: center;
    border-radius: 0.25rem;
    background: color-mix(in oklab, var(--color-base-200) 78%, transparent);
    padding: 0.3em 0.55em;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: inherit;
    font-weight: 600;
    line-height: 1;
    white-space: nowrap;
  }
</style>
