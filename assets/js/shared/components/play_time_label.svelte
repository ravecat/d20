<script module lang="ts">
  import type { GameMetadata } from "~/shared/types";

  function formatPlayTime(game: GameMetadata) {
    const min = positiveInteger(game.minPlayTime);
    const max = positiveInteger(game.maxPlayTime);
    const fallback = positiveInteger(game.playingTime);

    if (min && max && min !== max) return `${min}-${max}`;
    if (min && max) return String(min);
    if (min) return `${min}+`;
    if (max) return `≤${max}`;
    if (fallback) return String(fallback);

    return null;
  }

  function positiveInteger(
    value?: GameMetadata["playingTime"] | GameMetadata["minPlayTime"] | GameMetadata["maxPlayTime"],
  ) {
    return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : null;
  }
</script>

<script lang="ts">
  type Props = {
    game: GameMetadata;
  };

  const { game }: Props = $props();
  const label = $derived(formatPlayTime(game));
</script>

{#if label}
  <div class="game-metadata-label" aria-label="Play time">
    <svg
      class="game-metadata-label__icon"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="1.8"
      stroke-linecap="round"
      stroke-linejoin="round"
      aria-hidden="true"
    >
      <circle cx="12" cy="12" r="9"></circle>
      <path d="M12 7v5l3 2"></path>
    </svg>
    <span>{label}</span>
  </div>
{/if}

<style>
  .game-metadata-label {
    box-sizing: border-box;
    display: inline-flex;
    block-size: 2.2em;
    min-inline-size: 3.1em;
    align-items: center;
    justify-content: center;
    gap: 0.45em;
    border-radius: 0.25rem;
    background: color-mix(in oklab, var(--color-base-200) 78%, transparent);
    padding: 0.3em 0.55em;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: inherit;
    font-weight: 600;
    line-height: 1;
    white-space: nowrap;
  }

  .game-metadata-label__icon {
    inline-size: 1.25em;
    block-size: 1.25em;
    flex: none;
  }
</style>
