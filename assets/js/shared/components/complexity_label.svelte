<script module lang="ts">
  import type { GameMetadata } from "~/shared/types";

  function formatComplexity(game: GameMetadata) {
    const complexity = validComplexity(game.complexity);

    return complexity ? `${formatNumber(complexity)}/5` : null;
  }

  function validComplexity(value?: GameMetadata["complexity"]) {
    return typeof value === "number" && Number.isFinite(value) && value > 0 && value <= 5
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
  const label = $derived(formatComplexity(game));
</script>

{#if label}
  <div class="game-metadata-label" aria-label="Complexity">
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
      <path d="M6 19v-5"></path>
      <path d="M12 19v-9"></path>
      <path d="M18 19V5"></path>
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
