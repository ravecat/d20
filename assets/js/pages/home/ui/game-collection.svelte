<script lang="ts">
  import type { Snippet } from "svelte";
  import type { GameCatalogEntry } from "~/shared/types/game";
  import GameCard from "./game-card.svelte";

  let {
    games,
    header,
    variant = "browse",
    favorites = [],
  }: {
    games: GameCatalogEntry[];
    header: Snippet;
    variant?: "compact" | "browse";
    favorites?: number[];
  } = $props();
  const headingId = $props.id();
  const lanes = $derived.by(() => {
    if (variant === "browse") {
      const heroCount = Math.ceil(games.length / 4);
      return [
        { entries: games.slice(0, heroCount), hero: true, label: "Featured games" },
        { entries: games.slice(heroCount), hero: false, label: "More games" },
      ];
    }
    const rows =
      games.length > 6
        ? [games.slice(0, Math.ceil(games.length / 2)), games.slice(Math.ceil(games.length / 2))]
        : [games];
    return rows.map((entries, index) => ({
      entries,
      hero: false,
      label: rows.length > 1 ? `Row ${index + 1}` : undefined,
    }));
  });
</script>

{#if games.length > 0}
  <section class="home-section" aria-labelledby={headingId}>
    <h2 id={headingId} class="section-heading">
      <span>
        {@render header()}
      </span>
    </h2>
    <div class="carousel-group">
      {#each lanes as lane (lane.label)}
        {#if lane.entries.length > 0}
          {@const slides =
            lane.entries.length > 1
              ? [...lane.entries, ...lane.entries, ...lane.entries.slice(0, 1)]
              : lane.entries}
          <div
            class={{
              "carousel-viewport": true,
              "carousel--hero": lane.hero,
              "carousel--compact": !lane.hero,
            }}
            style={`--slide-count: ${lane.entries.length}`}
            data-single={lane.entries.length === 1 || undefined}
          >
            <ul class="carousel-track" aria-label={lane.label}>
              {#each slides as entry, index (`${entry.id}-${index}`)}
                <li class="carousel-slide" aria-hidden={index >= lane.entries.length || undefined}>
                  <GameCard
                    {entry}
                    duplicate={index >= lane.entries.length}
                    hero={lane.hero}
                    saved={favorites.includes(entry.favorite.bggId)}
                  />
                </li>
              {/each}
            </ul>
          </div>
        {/if}
      {/each}
    </div>
  </section>
{/if}

<style>
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

  .section-heading :global(a) {
    text-decoration: underline;
    text-underline-offset: 0.2em;
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
    display: grid;
    gap: 0.5rem;
  }

  .carousel-viewport {
    container-type: inline-size;
    inline-size: 100%;
    min-inline-size: 0;
    overflow: clip;
  }

  .carousel--compact:not([data-single]) .carousel-track {
    position: relative;
    inset-inline-start: calc(
      50cqw - 1.5 * max(clamp(9.5rem, 42cqw, 16rem), calc(100cqw / var(--slide-count) - 0.5rem)) -
        0.5rem
    );
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

  .carousel-viewport:has(:global(:focus-visible)) {
    overflow: hidden;
    scroll-snap-type: x mandatory;
  }

  .carousel-group:has(:global(:focus-visible)) .carousel-track {
    /* Reveal canonical links even when autoplay moved them before the scroll origin.
     * Pointer focus must keep the clicked card still until navigation completes.
     * Keep the CSS clocks paused; clipping clears scroll when keyboard focus leaves. */
    /* Keep the CSS compiler from merging away the independent translate reset. */
    transform: initial !important;
    translate: none !important;
    inset-inline-start: 0 !important;
  }

  .carousel-slide {
    position: relative;
    display: flex;
    box-sizing: border-box;
    flex: 0 0 auto;
    min-inline-size: 0;
    inline-size: calc(clamp(9.5rem, 42cqw, 16rem) + 0.5rem);
    padding-inline-end: 0.5rem;
  }

  .carousel--compact:not([data-single]) .carousel-slide {
    inline-size: calc(
      max(clamp(9.5rem, 42cqw, 16rem), calc(100cqw / var(--slide-count) - 0.5rem)) + 0.5rem
    );
  }

  .carousel--hero .carousel-slide {
    inline-size: 100cqw;
    padding-inline-end: 0;
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
  }
</style>
