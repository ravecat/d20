<script module lang="ts">
  import type { GameMetadata } from "~/shared/types";

  function formatPlayerCount(game: GameMetadata) {
    const min = positiveInteger(game.minPlayers);
    const max = positiveInteger(game.maxPlayers);

    if (min && max && min === max) return String(min);
    if (min && max) return `${min}-${max}`;
    if (min) return `${min}+`;
    if (max) return `≤${max}`;

    return null;
  }

  function positiveInteger(value?: GameMetadata["minPlayers"] | GameMetadata["maxPlayers"]) {
    return typeof value === "number" && Number.isInteger(value) && value > 0 ? value : null;
  }
</script>

<script lang="ts">
  type Props = {
    game: GameMetadata;
  };

  const { game }: Props = $props();
  const label = $derived(formatPlayerCount(game));
</script>

{#if label}
  <div class="game-metadata-label" aria-label="Players">
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
      <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path>
      <circle cx="9" cy="7" r="4"></circle>
      <path d="M22 21v-2a4 4 0 0 0-3-3.87"></path>
      <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
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
