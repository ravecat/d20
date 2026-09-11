<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import type { GameCatalogEntry } from "~/shared/types/game";

  type Props = InertiaProps<{
    playableGames: GameCatalogEntry[];
    games: GameCatalogEntry[];
  }>;

  const { playableGames, games }: Props = $props();

  const playableSlides = $derived.by(() =>
    playableGames.length > 1
      ? [...playableGames, ...playableGames, ...playableGames.slice(0, 1)]
      : playableGames,
  );
  const heroGames = $derived(games.slice(0, Math.ceil(games.length / 4)));
  const compactGames = $derived(games.slice(heroGames.length));
  const heroSlides = $derived(
    heroGames.length > 1 ? [...heroGames, ...heroGames, ...heroGames.slice(0, 1)] : heroGames,
  );
  const compactSlides = $derived(
    compactGames.length > 1
      ? [...compactGames, ...compactGames, ...compactGames.slice(0, 1)]
      : compactGames,
  );
</script>

<div class="home-page">
  <div class="home-shell">
    <h1 class="visually-hidden">Games</h1>

    {#if playableGames.length > 0}
      <section class="home-section" aria-labelledby="playable-heading">
        <h2 id="playable-heading" class="section-heading">Playable</h2>

        <div class="carousel-group">
          <div
            class="carousel-viewport carousel--compact"
            style={`--slide-count: ${playableGames.length}`}
            data-single={playableGames.length === 1 || undefined}
          >
            <ul class="carousel-track">
              {#each playableSlides as entry, index (`${entry.id}-${index}`)}
                {@const url = entry.game.imageUrl ?? entry.game.thumbnailUrl}
                {@const title = entry.game.name}
                {@const href = `/games/${entry.slug}`}
                <li
                  class="carousel-slide"
                  aria-hidden={index >= playableGames.length || undefined}
                  inert={index >= playableGames.length || undefined}
                >
                  <a
                    class="game-card game-card--released"
                    {href}
                    aria-label={title || "Open game"}
                    use:inertia={{ href }}
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
                          <ul class="game-metadata-block" aria-label="Categories">
                            {#each entry.game.categories as category (category)}
                              <li class="game-metadata-chip">{category}</li>
                            {/each}
                          </ul>
                        </div>
                      {/if}
                      {#if title}
                        <h3 class="game-title">{title}</h3>
                      {/if}
                    </div>
                  </a>
                </li>
              {/each}
            </ul>
          </div>
        </div>
      </section>
    {/if}

    {#if games.length > 0}
      <section class="home-section" aria-labelledby="games-heading">
        <h2 id="games-heading" class="section-heading">Games</h2>

        <div class="carousel-group carousel-group--games">
          <div
            class="carousel-viewport carousel--hero"
            style={`--slide-count: ${heroGames.length}`}
            data-single={heroGames.length === 1 || undefined}
          >
            <ul class="carousel-track" aria-label="Featured games">
              {#each heroSlides as entry, index (`${entry.id}-${index}`)}
                {@const url = entry.game.imageUrl ?? entry.game.thumbnailUrl}
                {@const title = entry.game.name}
                {@const href = `/games/${entry.slug}`}
                <li class="carousel-slide" aria-hidden={index >= heroGames.length || undefined}>
                  <a
                    class={{
                      "game-card": true,
                      "game-card--hero": true,
                      "game-card--released": entry.stage === "released",
                      "game-card--muted": entry.stage === "in_development",
                      "game-card--in-development": entry.stage === "in_development",
                    }}
                    {href}
                    tabindex={index >= heroGames.length ? -1 : undefined}
                    aria-label={title || "Open game"}
                    use:inertia={{ href }}
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
                          <ul class="game-metadata-block" aria-label="Categories">
                            {#each entry.game.categories as category (category)}
                              <li class="game-metadata-chip">{category}</li>
                            {/each}
                          </ul>
                        </div>
                      {/if}
                      {#if entry.stage === "in_development"}
                        <span class="game-status-badge">In development</span>
                      {/if}
                      {#if title}
                        <h3 class="game-title">{title}</h3>
                      {/if}
                    </div>
                  </a>
                </li>
              {/each}
            </ul>
          </div>

          {#if compactGames.length > 0}
            <div
              class="carousel-viewport carousel--compact"
              style={`--slide-count: ${compactGames.length}`}
              data-single={compactGames.length === 1 || undefined}
            >
              <ul class="carousel-track" aria-label="More games">
                {#each compactSlides as entry, index (`${entry.id}-${index}`)}
                  {@const url = entry.game.imageUrl ?? entry.game.thumbnailUrl}
                  {@const title = entry.game.name}
                  {@const href = `/games/${entry.slug}`}
                  <li
                    class="carousel-slide"
                    aria-hidden={index >= compactGames.length || undefined}
                  >
                    <a
                      class={{
                        "game-card": true,
                        "game-card--released": entry.stage === "released",
                        "game-card--muted": entry.stage === "in_development",
                        "game-card--in-development": entry.stage === "in_development",
                      }}
                      {href}
                      tabindex={index >= compactGames.length ? -1 : undefined}
                      aria-label={title || "Open game"}
                      use:inertia={{ href }}
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
                            <ul class="game-metadata-block" aria-label="Categories">
                              {#each entry.game.categories as category (category)}
                                <li class="game-metadata-chip">{category}</li>
                              {/each}
                            </ul>
                          </div>
                        {/if}
                        {#if entry.stage === "in_development"}
                          <span class="game-status-badge">In development</span>
                        {/if}
                        {#if title}
                          <h3 class="game-title">{title}</h3>
                        {/if}
                      </div>
                    </a>
                  </li>
                {/each}
              </ul>
            </div>
          {/if}
        </div>
      </section>
    {/if}
  </div>
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
    padding-block: 0.6667rem;
    padding-inline: 1rem;
  }

  .visually-hidden {
    position: absolute;
    inline-size: 1px;
    block-size: 1px;
    margin: -1px;
    padding: 0;
    overflow: hidden;
    border: 0;
    clip-path: inset(50%);
    white-space: nowrap;
  }

  .home-section + .home-section {
    margin-block-start: 0.6667rem;
  }

  .section-heading {
    display: flex;
    margin: 0 0 0.6667rem;
    align-items: center;
    gap: 0.75rem;
    color: color-mix(in oklab, var(--color-base-content) 58%, transparent);
    font-size: 0.75rem;
    font-weight: 400;
    line-height: 1.2;
  }

  .section-heading::after {
    position: relative;
    inset-block-start: 1px;
    block-size: 0;
    flex: 1;
    border-block-start: 1px solid currentColor;
    content: "";
    opacity: 0.31;
  }

  /*
   * Carousel behavior is owned entirely by this CSS. Each lane receives the
   * slide count as `--slide-count`; the track holds the ordered sequence followed by one
   * duplicate sequence and a final first-card copy for centered two-item rows.
   * Translating by `--slide-count` slide widths wraps the loop seamlessly, independently
   * of that extra tail. A second animation interpolates the final 1.1s of each 6.1s
   * cycle. Its reset coincides with the sequence step so the combined position
   * stays continuous, including at the duplicate-to-canonical wrap.
   */
  .carousel-group {
    --cycle: 6.1s;
  }

  .carousel-group--games {
    display: grid;
    gap: 0.5rem;
  }

  .carousel-viewport {
    --slide-basis: clamp(9.5rem, 42cqw, 16rem);
    --slide-gap: 0.5rem;

    container-type: inline-size;
    inline-size: 100%;
    min-inline-size: 0;
    overflow: clip;
  }

  .carousel--compact:not([data-single]) {
    --slide-basis: max(
      clamp(9.5rem, 42cqw, 16rem),
      calc(100cqw / var(--slide-count) - var(--slide-gap))
    );
  }

  .carousel--hero {
    --slide-basis: 100cqw;
    --slide-gap: 0rem;
  }

  .carousel--compact:not([data-single]) .carousel-track {
    position: relative;
    inset-inline-start: calc(50cqw - 1.5 * var(--slide-basis) - var(--slide-gap));
  }

  .carousel-track {
    display: flex;
    inline-size: max-content;
    margin: 0;
    padding: 0;
    list-style: none;
    animation:
      carousel-dwell calc(var(--cycle) * var(--slide-count)) steps(var(--slide-count), jump-end)
        infinite,
      carousel-slide var(--cycle) infinite;
  }

  .carousel-viewport[data-single] .carousel-track {
    animation: none;
  }

  .carousel-group:hover .carousel-track,
  .carousel-group:focus-within .carousel-track {
    animation-play-state: paused;
  }

  .carousel-viewport:has(:focus-visible) {
    overflow: hidden;
    /* Reserve room around keyboard targets so partially visible cards scroll into view. */
    scroll-padding-inline: 25%;
  }

  .carousel-group:has(:focus-visible) .carousel-track {
    /* Reveal canonical links even when autoplay moved them before the scroll origin.
     * Pointer focus must keep the clicked card still until navigation completes.
     * Keep the CSS clocks paused; clipping clears scroll when keyboard focus leaves. */
    /* Keep the CSS compiler from merging away the independent translate reset. */
    transform: initial !important;
    translate: none !important;
    inset-inline-start: 0 !important;
  }

  .carousel-slide {
    box-sizing: border-box;
    flex: 0 0 auto;
    min-inline-size: 0;
    inline-size: calc(var(--slide-basis) + var(--slide-gap));
    padding-inline-end: var(--slide-gap);
  }

  .game-card {
    scroll-margin-inline: max(0px, calc((100cqw - var(--slide-basis)) / 2));
    display: block;
    inline-size: 100%;
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
    outline-offset: -3px;
  }

  .game-card:focus-visible .game-preview::before {
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

  .game-card--hero .game-preview {
    aspect-ratio: 2.9 / 1;
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

  .game-metadata-blocks {
    position: absolute;
    inset-inline: 0.65rem;
    inset-block-end: 0.65rem;
    z-index: 2;
    display: flex;
    pointer-events: none;
  }

  .game-metadata-block {
    display: flex;
    min-inline-size: 0;
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
    background: oklch(42% 0.12 196 / 0.88);
    color: white;
    font-size: 0.625rem;
    font-weight: 700;
    line-height: 1.05;
    text-overflow: ellipsis;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.45);
    white-space: nowrap;
    box-shadow: 0 5px 12px rgb(0 0 0 / 0.18);
  }

  .game-card:not(.game-card--hero) .game-metadata-block {
    flex-wrap: nowrap;
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

  .game-card--in-development .game-title {
    max-inline-size: calc(100% - 7.25rem);
  }

  .game-card:not(.game-card--hero) .game-title {
    max-block-size: 2.2em;
    overflow: hidden;
  }

  .game-card--hero .game-title {
    inset-inline-start: 1.25rem;
    inset-block-start: 1.1rem;
    font-size: clamp(1.05rem, 3cqi, 1.6rem);
  }

  .game-card--hero .game-metadata-blocks {
    inset-inline: 1.25rem;
    inset-block-end: 1.1rem;
  }

  .game-card--hero .game-metadata-chip {
    font-size: 0.75rem;
  }

  .game-status-badge {
    position: absolute;
    inset-block-start: 0.75rem;
    inset-inline-end: 0.75rem;
    z-index: 2;
    border: 1px solid color-mix(in oklab, var(--color-warning-content) 30%, transparent);
    border-radius: 0.35rem;
    padding: 0.3rem 0.4rem;
    background: var(--color-warning);
    color: var(--color-warning-content);
    font-size: 0.5625rem;
    font-weight: 700;
    line-height: 1.1;
    white-space: nowrap;
    box-shadow: 0 8px 18px rgb(0 0 0 / 0.2);
  }

  .game-card--hero .game-status-badge {
    inset-block-start: 1.1rem;
    inset-inline-end: 1.25rem;
    font-size: 0.6875rem;
  }

  @container (max-width: 30rem) {
    .game-card--hero .game-preview {
      aspect-ratio: 1.9 / 1;
    }
  }

  @container (max-width: 11rem) {
    .game-card--in-development .game-title {
      max-inline-size: calc(100% - 1.5rem);
    }

    .game-card--in-development:not(.game-card--hero) .game-metadata-blocks {
      display: none;
    }

    .game-status-badge {
      inset-block-start: auto;
      inset-block-end: 0.3rem;
    }
  }

  @keyframes carousel-dwell {
    to {
      transform: translateX(calc(-100% * var(--slide-count) / (2 * var(--slide-count) + 1)));
    }
  }

  @keyframes carousel-slide {
    0%,
    81.967213% {
      translate: 0;
      animation-timing-function: ease-in-out;
    }

    100% {
      translate: calc(-100% / (2 * var(--slide-count) + 1));
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .carousel-track {
      animation: none;
    }

    .game-card,
    .game-card--muted .game-preview::after,
    .game-preview-image {
      transition: none;
    }

    .game-card:hover {
      transform: none;
    }
  }
</style>
