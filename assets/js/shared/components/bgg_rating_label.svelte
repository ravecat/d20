<script module lang="ts">
  import type { GameMetadata } from "~/shared/types";

  function formatRating(game: GameMetadata) {
    const rating = validRating(game.rating);

    return rating ? `${formatNumber(rating)}/10` : null;
  }

  function validRating(value?: GameMetadata["rating"]) {
    return typeof value === "number" && Number.isFinite(value) && value > 0 && value <= 10
      ? value
      : null;
  }

  function formatNumber(value: number) {
    return value.toFixed(1).replace(/\.0$/, "");
  }
</script>

<script lang="ts">
  type Props = {
    game: GameMetadata;
  };

  const { game }: Props = $props();
  const label = $derived(formatRating(game));
</script>

{#if label}
  <div class="game-metadata-label" aria-label="BGG rating">
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
      <path
        d="M12 3.5l2.75 5.57 6.15.9-4.45 4.34 1.05 6.13L12 17.55l-5.5 2.89 1.05-6.13L3.1 9.97l6.15-.9L12 3.5z"
      ></path>
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
