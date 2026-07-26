<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import type { GameCatalogEntry } from "~/shared/types";

  type Props = InertiaProps<{
    games: GameCatalogEntry[];
  }>;

  const { games }: Props = $props();
</script>

<div class="home-page">
  <section class="home-shell">
    {#if games.length > 0}
      <ul class="home-grid">
        {#each games as entry (entry.slug)}
          {@const url = entry.game.imageUrl ?? entry.game.thumbnailUrl}
          {@const title = entry.game.name}
          <li class="game-card-item">
            <a
              class={{
                "game-card": true,
                "game-card--active": entry.status === "active",
                "game-card--muted": entry.status !== "active",
                "game-card--in-progress": entry.status === "in_progress",
              }}
              href={`/games/${entry.slug}`}
              aria-labelledby={title ? `game-title-${entry.slug}` : undefined}
              aria-label={title ? undefined : "Open game"}
              use:inertia={{ href: `/games/${entry.slug}` }}
            >
              <div class="game-preview">
                {#if url}
                  <img
                    class="game-preview-image"
                    src={url}
                    alt=""
                    width="640"
                    height="320"
                    loading="lazy"
                    decoding="async"
                  />
                {:else}
                  <div class="game-preview-fallback" aria-hidden="true"></div>
                {/if}

                <div class="game-preview-overlay" aria-hidden="true"></div>
                {#if title}
                  <div class="game-title-scrim" aria-hidden="true"></div>
                {/if}
                {#if entry.game.categories.length > 0}
                  <div class="game-metadata-blocks">
                    <ul
                      class="game-metadata-block game-metadata-block--categories"
                      aria-label="Categories"
                    >
                      {#each entry.game.categories as category (category)}
                        <li class="game-metadata-chip game-metadata-chip--category">{category}</li>
                      {/each}
                    </ul>
                  </div>
                {/if}
                {#if entry.status === "in_progress"}
                  <span class="game-status-badge">Soon</span>
                {/if}
                {#if title}
                  <h2 id={`game-title-${entry.slug}`} class="game-title">{title}</h2>
                {/if}
              </div>
            </a>
          </li>
        {/each}
      </ul>
    {:else}
      <p class="home-empty">No games</p>
    {/if}
  </section>
</div>

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
    margin: 0;
    padding: 0;
    grid-template-columns: repeat(auto-fill, minmax(min(14rem, 100%), 1fr));
    gap: 1.25rem;
    list-style: none;
  }

  .game-card-item {
    min-inline-size: 0;
  }

  .home-empty {
    display: grid;
    min-block-size: 50vh;
    margin: 0;
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

  .game-card--muted {
    border-color: color-mix(in oklab, var(--color-base-300) 72%, transparent);
    box-shadow: none;
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

  .game-card--muted .game-preview::after {
    position: absolute;
    inset: 0;
    z-index: 1;
    background: color-mix(in oklab, var(--color-base-100) 52%, transparent);
    content: "";
    pointer-events: none;
    transition: background-color 180ms ease;
  }

  .game-card--muted:hover .game-preview::after {
    background: color-mix(in oklab, var(--color-base-100) 42%, transparent);
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

  .game-card--active:hover .game-preview-image {
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

  .game-title-scrim {
    position: absolute;
    inset: 0;
    z-index: 2;
    background: linear-gradient(90deg, rgb(0 0 0 / 0.38), rgb(0 0 0 / 0.08) 48%, transparent 68%);
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
    margin: 0;
    padding: 0;
    flex-wrap: wrap;
    gap: 0.25rem;
    overflow: clip;
    list-style: none;
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

  .game-title {
    position: absolute;
    inset-inline-start: 0.75rem;
    inset-block-start: 0.75rem;
    z-index: 2;
    max-inline-size: calc(100% - 1.5rem);
    margin: 0;
    color: white;
    font-size: 0.8125rem;
    font-weight: 700;
    line-height: 1.1;
    overflow-wrap: anywhere;
    text-align: start;
    text-shadow:
      0 1px 2px rgb(0 0 0 / 0.9),
      0 0 10px rgb(0 0 0 / 0.5);
  }

  .game-card--in-progress .game-title {
    max-inline-size: calc(100% - 6rem);
  }

  .game-status-badge {
    position: absolute;
    inset-block-start: 0.75rem;
    inset-inline-end: 0.75rem;
    z-index: 2;
    border: 1px solid color-mix(in oklab, var(--color-warning-content) 30%, transparent);
    border-radius: 0.35rem;
    padding: 0.35rem 0.55rem;
    background: var(--color-warning);
    color: var(--color-warning-content);
    font-size: 0.6875rem;
    font-weight: 700;
    line-height: 1.1;
    white-space: nowrap;
    box-shadow: 0 8px 18px rgb(0 0 0 / 0.2);
  }

  @media (max-width: 48rem) {
    .home-shell {
      padding-inline: 1rem;
    }
  }
</style>
