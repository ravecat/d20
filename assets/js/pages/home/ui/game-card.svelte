<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import { FavoriteButton } from "~/features/favorite-game";
  import type { GameCatalogEntry } from "~/shared/types/game";

  let {
    entry,
    duplicate = false,
    hero = false,
    saved = false,
  }: {
    entry: GameCatalogEntry;
    duplicate?: boolean;
    hero?: boolean;
    saved?: boolean;
  } = $props();
  const url = $derived(entry.game.imageUrl ?? entry.game.thumbnailUrl);
  const title = $derived(entry.game.name);
  const href = $derived(`/games/${entry.slug}`);
</script>

<article
  aria-label={title || "Untitled game"}
  class={{
    "game-card": true,
    "game-card--hero": hero,
    "game-card--released": entry.stage === "released",
    "game-card--muted": entry.stage === "in_development",
  }}
>
  <div class="game-preview">
    <div class="game-artwork" aria-hidden="true">
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
        <div class="game-preview-fallback"></div>
      {/if}
      <div class="game-preview-overlay"></div>
      {#if title}
        <div class="game-title-scrim"></div>
      {/if}
    </div>
    <a
      class="game-card-link"
      {href}
      tabindex={duplicate ? -1 : undefined}
      aria-label={title || "Open game"}
      use:inertia={{ href }}
    ></a>
    <div class="game-card-header">
      {#if title}
        <h3 class="game-title">{title}</h3>
      {/if}
    </div>
    <div class="game-favorite">
      <FavoriteButton
        {saved}
        favorite={entry.favorite}
        {title}
        tabindex={duplicate ? -1 : undefined}
      />
    </div>
    <div class="game-card-footer">
      {#if entry.game.categories.length > 0}
        <ul class="game-metadata-block" aria-label="Categories">
          {#each entry.game.categories as category (category)}
            <li class="game-metadata-chip">{category}</li>
          {/each}
        </ul>
      {/if}
      {#if entry.stage === "in_development"}
        <span class="game-status-badge">In development</span>
      {/if}
    </div>
  </div>
</article>

<style>
  .game-favorite {
    position: absolute;
    inset: 0;
    z-index: 5;
    display: flex;
    align-items: flex-start;
    justify-content: flex-end;
    padding: inherit;
    font-size: var(--game-title-line-height);
    pointer-events: none;
  }

  .game-card {
    position: relative;
    flex: 1;
    min-inline-size: 0;
    inline-size: 100%;
    aspect-ratio: 2 / 1;
    container-type: inline-size;
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

  .game-card:has(:global(:focus-visible)) {
    scroll-snap-align: center;
  }

  .game-card--muted {
    border-color: color-mix(in oklab, var(--color-base-300) 72%, transparent);
    box-shadow: none;
  }

  .game-card-link {
    position: absolute;
    inset: 0;
    z-index: 3;
    border-radius: inherit;
  }

  .game-card-link:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 40%, transparent);
    outline-offset: -3px;
  }

  .game-card-link:focus-visible::after {
    position: absolute;
    inset: 3px;
    z-index: 3;
    border: 2px solid white;
    border-radius: var(--radius-sm);
    outline: 2px solid var(--color-primary);
    content: "";
    pointer-events: none;
  }

  .game-preview {
    --game-title-font-size: min(8cqi, max(0.75rem, 6cqi));
    --game-title-line-height: calc(var(--game-title-font-size) * 1.2);
    position: absolute;
    inset: 0;
    display: grid;
    grid-template-rows: auto minmax(0, 1fr) auto;
    gap: 0.25em;
    min-inline-size: 0;
    border-radius: inherit;
    padding: 0.5em;
    font-size: 8cqi;
    isolation: isolate;
  }

  .game-artwork {
    position: absolute;
    inset: 0;
    overflow: clip;
    border-radius: inherit;
    background:
      radial-gradient(circle at 24% 28%, oklch(82% 0.18 82) 0 18%, transparent 42%),
      radial-gradient(circle at 78% 38%, oklch(68% 0.2 27) 0 18%, transparent 46%),
      linear-gradient(135deg, oklch(63% 0.17 252), oklch(91% 0.14 96));
  }

  .game-card-header,
  .game-card-footer {
    position: relative;
    z-index: 4;
    display: grid;
    gap: 0.25em;
    align-items: center;
    min-inline-size: 0;
    pointer-events: none;
  }

  .game-card-header {
    z-index: 5;
    grid-row: 1;
    grid-template-columns: minmax(0, 1fr) 44px;
  }

  .game-card-footer {
    grid-row: 3;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: flex-end;
  }

  .game-card--hero {
    aspect-ratio: 2.9 / 1;
  }

  .game-card--hero .game-preview {
    --game-title-font-size: 4cqi;
    padding: 0.75em;
    font-size: 4cqi;
  }

  .game-card--muted .game-artwork::after {
    position: absolute;
    inset: 0;
    z-index: 1;
    background: color-mix(in oklab, var(--color-base-100) 52%, transparent);
    content: "";
    pointer-events: none;
    transition: background-color 180ms ease;
  }

  .game-card--muted:hover .game-artwork::after {
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

  .game-card--released:hover .game-preview-image {
    filter: saturate(1.2) contrast(0.94) brightness(0.96);
    scale: 1.06;
  }

  .game-preview-fallback {
    position: absolute;
    inset: 0;
    z-index: 0;
    display: grid;
    place-items: center;
    color: color-mix(in oklab, var(--color-base-content) 32%, transparent);
    font-size: clamp(2.5rem, 18cqi, 5rem);
    font-weight: 700;
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

  .game-metadata-block {
    display: flex;
    min-inline-size: 0;
    block-size: calc(1.45em + 2px);
    margin: 0;
    padding: 0;
    flex-wrap: wrap;
    align-content: flex-start;
    gap: 0.25em;
    overflow: clip;
    font-size: 0.5em;
    list-style: none;
  }

  .game-metadata-chip,
  .game-status-badge {
    block-size: calc(1.45em + 2px);
    padding: 0.15em 0.35em;
    font-weight: 700;
    line-height: 1.15;
    white-space: nowrap;
  }

  .game-metadata-chip {
    flex: none;
    border: 1px solid rgb(255 255 255 / 0.28);
    border-radius: 0.25em;
    background: oklch(42% 0.12 196 / 0.88);
    color: white;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.45);
    box-shadow: 0 5px 12px rgb(0 0 0 / 0.18);
  }

  .game-metadata-chip:first-child {
    max-inline-size: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .game-title {
    display: -webkit-box;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 4;
    line-clamp: 4;
    min-inline-size: 0;
    overflow: hidden;
    margin: 0;
    color: white;
    font-size: var(--game-title-font-size);
    font-weight: 700;
    line-height: var(--game-title-line-height);
    overflow-wrap: anywhere;
    text-align: start;
    filter: drop-shadow(0 1px 1px rgb(0 0 0 / 0.9));
  }

  @container (width < 12rem) {
    .game-title {
      -webkit-line-clamp: 3;
      line-clamp: 3;
    }
  }

  .game-status-badge {
    grid-column: 2;
    font-size: 0.5em;
    border: 1px solid color-mix(in oklab, var(--color-warning-content) 30%, transparent);
    border-radius: 0.35em;
    background: var(--color-warning);
    color: var(--color-warning-content);
    box-shadow: 0 8px 18px rgb(0 0 0 / 0.2);
  }

  @media (prefers-reduced-motion: reduce) {
    .game-card,
    .game-card--muted .game-artwork::after,
    .game-preview-image {
      transition: none;
    }

    .game-card:hover {
      transform: none;
    }
  }
</style>
