<script module lang="ts">
  import Layout from "~components/layout.svelte";

  export const layout = {
    component: Layout,
    props: {
      variant: "catalog",
    },
  };
</script>

<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import type { GameCatalogEntry } from "~types/game";

  type Props = InertiaProps<{
    games: GameCatalogEntry[];
  }>;

  const { games }: Props = $props();
</script>

<main class="home-page">
  <section class="home-shell">
    {#if games.length > 0}
      <div class="home-grid">
        {#each games as entry (entry.slug)}
          {@const imageUrl = entry.game.imageUrl ?? entry.game.thumbnailUrl}
          {@const gameTitle = entry.game.name}
          <a
            class="game-card"
            href={`/games/${entry.slug}`}
            aria-label={gameTitle ? `Open ${gameTitle}` : "Open game"}
            use:inertia={{ href: `/games/${entry.slug}` }}
          >
            <span class="game-preview">
              {#if imageUrl}
                <img
                  class="game-preview-image"
                  src={imageUrl}
                  alt=""
                  width="640"
                  height="320"
                  loading="lazy"
                  decoding="async"
                >
              {:else}
                <span class="game-preview-fallback" aria-hidden="true"></span>
              {/if}

              <span class="game-preview-overlay" aria-hidden="true"></span>
              {#if entry.game.categories.length > 0}
                <span class="game-metadata-blocks">
                  <span class="game-metadata-block game-metadata-block--categories">
                    {#each entry.game.categories as category (category)}
                      <span class="game-metadata-chip game-metadata-chip--category">
                        {category}
                      </span>
                    {/each}
                  </span>
                </span>
              {/if}
              {#if gameTitle}
                <span class="game-title-chip">{gameTitle}</span>
              {/if}
            </span>
          </a>
        {/each}
      </div>
    {:else}
      <div class="home-empty">No games</div>
    {/if}
  </section>
</main>

<style>
  .home-page {
    background: var(--color-base-100);
    color: var(--color-base-content);
  }

  .home-shell {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding: 1.5rem;
  }

  .home-grid {
    display: grid;
    inline-size: 100%;
    grid-template-columns: repeat(auto-fill, minmax(min(14rem, 100%), 1fr));
    gap: 1.25rem;
  }

  .home-empty {
    display: grid;
    min-block-size: 50vh;
    place-items: center;
    color: color-mix(in oklab, var(--color-base-content) 60%, transparent);
    font-size: 0.875rem;
  }

  .game-card {
    display: block;
    overflow: clip;
    border: 1px solid var(--color-base-300);
    border-radius: var(--radius-sm);
    background: var(--color-base-100);
    color: var(--color-base-content);
    box-shadow: 0 1px 2px rgb(0 0 0 / 0.08);
    transition:
      border-color 180ms ease,
      box-shadow 180ms ease,
      transform 180ms ease;
  }

  .game-card:hover {
    border-color: color-mix(in oklab, var(--color-base-content) 25%, transparent);
    box-shadow: 0 10px 24px rgb(0 0 0 / 0.14);
    transform: translateY(-1px);
  }

  .game-card:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 40%, transparent);
    outline-offset: 2px;
  }

  .game-preview {
    position: relative;
    display: block;
    aspect-ratio: 2 / 1;
    inline-size: 100%;
    overflow: clip;
    isolation: isolate;
    container-type: inline-size;
    background:
      radial-gradient(circle at 24% 28%, oklch(82% 0.18 82) 0 18%, transparent 42%),
      radial-gradient(circle at 78% 38%, oklch(68% 0.2 27) 0 18%, transparent 46%),
      linear-gradient(135deg, oklch(63% 0.17 252), oklch(91% 0.14 96));
  }

  .game-preview-image {
    position: absolute;
    inset: 0;
    z-index: 0;
    inline-size: 100%;
    block-size: 100%;
    object-fit: cover;
    object-position: top center;
    filter: saturate(1.12) contrast(0.9) brightness(0.92);
    scale: 1.04;
    transition:
      filter 180ms ease,
      scale 180ms ease;
  }

  .game-card:hover .game-preview-image {
    filter: saturate(1.2) contrast(0.94) brightness(0.96);
    scale: 1.06;
  }

  .game-preview-fallback {
    position: absolute;
    inset: 0;
    z-index: 0;
    display: grid;
    place-items: center;
    font-size: clamp(2.5rem, 18cqi, 5rem);
    font-weight: 700;
    color: color-mix(in oklab, var(--color-base-content) 32%, transparent);
  }

  .game-preview-overlay {
    position: absolute;
    inset: 0;
    z-index: 1;
    background:
      linear-gradient(180deg, rgb(255 255 255 / 0.14), transparent 42%),
      linear-gradient(145deg, transparent 38%, rgb(0 0 0 / 0.2)),
      radial-gradient(circle at 80% 85%, rgb(255 255 255 / 0.2), transparent 34%);
    mix-blend-mode: soft-light;
    pointer-events: none;
  }

  .game-metadata-blocks {
    position: absolute;
    inset-inline: 0.65rem 0.65rem;
    inset-block-end: 0.65rem;
    z-index: 2;
    display: flex;
    pointer-events: none;
  }

  .game-metadata-block {
    display: flex;
    max-block-size: 2.7rem;
    flex-wrap: wrap;
    gap: 0.25rem;
    overflow: clip;
  }

  .game-metadata-chip {
    max-inline-size: min(10rem, 100%);
    overflow: hidden;
    border: 1px solid rgb(255 255 255 / 0.28);
    border-radius: 0.25rem;
    padding: 0.22rem 0.42rem;
    color: white;
    font-size: 0.625rem;
    font-weight: 700;
    line-height: 1.05;
    text-overflow: ellipsis;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.45);
    white-space: nowrap;
    box-shadow: 0 5px 12px rgb(0 0 0 / 0.18);
  }

  .game-metadata-chip--category {
    background: oklch(42% 0.12 196 / 0.88);
  }

  .game-title-chip {
    position: absolute;
    inset-inline-start: 0.75rem;
    inset-block-start: 0.75rem;
    z-index: 2;
    max-inline-size: calc(100% - 1.5rem);
    border: 1px solid rgb(255 255 255 / 0.38);
    border-radius: 0.35rem;
    padding: 0.35rem 0.7rem;
    background: rgb(10 10 10 / 0.68);
    color: white;
    font-size: 0.8125rem;
    font-weight: 700;
    line-height: 1.1;
    overflow-wrap: anywhere;
    text-align: start;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.5);
    backdrop-filter: saturate(1.3);
    box-shadow: 0 8px 18px rgb(0 0 0 / 0.22);
  }

  @media (max-width: 48rem) {
    .home-shell {
      padding-inline: 1rem;
    }
  }
</style>
