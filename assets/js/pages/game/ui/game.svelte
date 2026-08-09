<script lang="ts">
  import type { Schema } from "@sjsf/form";
  import {
    AgeLabel,
    BggRatingLabel,
    ComplexityLabel,
    Lobby,
    PlayTimeLabel,
    PlayerCountLabel,
  } from "~/shared/components";
  import type { GameMetadata, SessionDescriptor } from "~/shared/types";
  import LaunchForm from "./launch_form.svelte";

  type Props = InertiaProps<{
    slug: string;
    canLaunchGame: boolean;
    game: GameMetadata;
    schema: Schema | null;
    session?: SessionDescriptor | null;
  }>;

  const { slug, canLaunchGame = false, game, schema, session = null }: Props = $props();
</script>

<div class="game-detail-page">
  <section class="game-detail-shell">
    <article class="game-detail-content">
      <div class="game-detail-preview">
        {#if game.imageUrl ?? game.thumbnailUrl}
          <img
            class="game-detail-preview__image"
            src={game.imageUrl ?? game.thumbnailUrl}
            alt=""
            width="1200"
            height="360"
            loading="eager"
            decoding="async"
            fetchpriority="high"
          />
        {:else}
          <div class="game-detail-preview__fallback" aria-hidden="true"></div>
        {/if}

        <div class="game-detail-preview__shade" aria-hidden="true"></div>
        {#if game.mechanics.length > 0 || game.categories.length > 0}
          <div class="game-detail-metadata">
            {#if game.categories.length > 0}
              <div class="game-detail-metadata__block" aria-label="Categories">
                {#each game.categories as category (category)}
                  <span class="game-detail-metadata__chip game-detail-metadata__chip--category">
                    {category}
                  </span>
                {/each}
              </div>
            {/if}
            {#if game.mechanics.length > 0}
              <div class="game-detail-metadata__block" aria-label="Mechanics">
                {#each game.mechanics as mechanic (mechanic)}
                  <span class="game-detail-metadata__chip game-detail-metadata__chip--mechanic">
                    {mechanic}
                  </span>
                {/each}
              </div>
            {/if}
          </div>
        {/if}
        {#if game.name}
          <div class="game-detail-chip">
            <h1 class="game-detail-chip__title">{game.name}</h1>
          </div>
        {/if}
      </div>

      <div class="game-detail-layout">
        <aside class="game-detail-activation" aria-label="Game activation">
          <div class="game-detail-activation__metadata">
            <PlayerCountLabel {game} />
            <PlayTimeLabel {game} />
            <AgeLabel {game} />
            <ComplexityLabel {game} />
            <BggRatingLabel {game} />
          </div>

          <div class="game-detail-activation__body">
            {#if session}
              {#key session.id}
                <Lobby {session} />
              {/key}
            {:else if canLaunchGame && schema}
              <LaunchForm {slug} {schema} />
            {/if}
          </div>
        </aside>

        <section class="game-detail-description-panel" aria-labelledby="game-detail-description">
          <h2 id="game-detail-description" class="game-detail-description-heading">Description</h2>
          {#if game.description}
            <p class="game-detail-description">{game.description}</p>
          {:else}
            <p class="game-detail-description game-detail-description--empty">
              Description not listed.
            </p>
          {/if}
        </section>
      </div>
    </article>
  </section>
</div>

<style>
  .game-detail-shell {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 64rem;
    margin-inline: auto;
    padding-block: 0 1.5rem;
    padding-inline: 1.5rem;
  }

  .game-detail-page {
    overflow-x: clip;
    background: var(--color-base-100);
    color: var(--color-base-content);
  }

  .game-detail-content {
    min-inline-size: 0;
  }

  .game-detail-shell * {
    box-sizing: border-box;
  }

  .game-detail-preview {
    position: relative;
    display: block;
    aspect-ratio: 3.9 / 1;
    inline-size: 100%;
    min-block-size: 11.5rem;
    overflow: clip;
    isolation: isolate;
    border: 1px solid var(--color-base-300);
    border-radius: var(--radius-sm);
    background:
      radial-gradient(circle at 18% 34%, oklch(82% 0.18 82) 0 16%, transparent 42%),
      radial-gradient(circle at 82% 42%, oklch(68% 0.2 27) 0 18%, transparent 46%),
      linear-gradient(135deg, oklch(64% 0.16 250), oklch(92% 0.13 95));
  }

  .game-detail-preview__image {
    position: absolute;
    inset: 0;
    z-index: 0;
    inline-size: 100%;
    block-size: 100%;
    object-fit: cover;
    object-position: center 38%;
    filter: saturate(1.28) contrast(1.08) brightness(1.04);
  }

  .game-detail-preview__fallback {
    position: absolute;
    inset: 0;
    z-index: 0;
    display: grid;
    place-items: center;
    color: color-mix(in oklab, var(--color-base-content) 32%, transparent);
    font-size: clamp(4rem, 30vw, 9rem);
    font-weight: 700;
    line-height: 1;
  }

  .game-detail-preview__shade {
    position: absolute;
    inset: 0;
    z-index: 1;
    background:
      linear-gradient(90deg, rgb(0 0 0 / 0.5), rgb(0 0 0 / 0.06) 58%),
      linear-gradient(180deg, rgb(255 255 255 / 0.14), transparent 46%);
    pointer-events: none;
  }

  .game-detail-chip {
    position: absolute;
    inset-inline-start: 1rem;
    inset-block-start: 1rem;
    z-index: 2;
    max-inline-size: calc(100% - 2rem);
    color: white;
  }

  .game-detail-chip__title {
    min-inline-size: 0;
    margin: 0;
    font-size: clamp(1.35rem, 5.6vw, 2.1rem);
    font-weight: 700;
    line-height: 1.05;
    overflow-wrap: anywhere;
  }

  .game-detail-description {
    margin: 0;
    color: color-mix(in oklab, var(--color-base-content) 75%, transparent);
    font-size: 0.875rem;
    line-height: 1.7;
    text-wrap: pretty;
    white-space: pre-line;
  }

  .game-detail-description-heading {
    position: absolute;
    inline-size: 1px;
    block-size: 1px;
    margin: -1px;
    border: 0;
    padding: 0;
    overflow: hidden;
    clip: rect(0 0 0 0);
    clip-path: inset(50%);
    white-space: nowrap;
  }

  .game-detail-description--empty {
    color: color-mix(in oklab, var(--color-base-content) 48%, transparent);
  }

  .game-detail-metadata {
    position: absolute;
    inset-inline: 1rem 1rem;
    inset-block-end: 1rem;
    z-index: 2;
    display: flex;
    flex-direction: column;
    gap: 0.4rem;
    pointer-events: none;
  }

  .game-detail-metadata__block {
    display: flex;
    max-block-size: 2.9rem;
    flex-wrap: wrap;
    gap: 0.3rem;
    overflow: clip;
  }

  .game-detail-metadata__chip {
    max-inline-size: min(14rem, 100%);
    overflow: hidden;
    border-radius: 0.25rem;
    padding: 0.24rem 0.5rem;
    color: white;
    font-size: 0.6875rem;
    font-weight: 700;
    line-height: 1.08;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .game-detail-metadata__chip--category {
    background: oklch(42% 0.12 196 / 0.9);
  }

  .game-detail-metadata__chip--mechanic {
    background: oklch(44% 0.15 33 / 0.9);
  }

  .game-detail-layout {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(17rem, 3fr);
    gap: 1.25rem;
    align-items: start;
    margin-block-start: 1rem;
  }

  .game-detail-description-panel,
  .game-detail-activation {
    min-inline-size: 0;
    border-radius: var(--radius-sm);
    background: color-mix(in oklab, var(--color-base-100) 94%, var(--color-base-200));
  }

  .game-detail-description-panel {
    max-block-size: clamp(18rem, calc(100dvb - 18rem), 38rem);
    overflow-y: auto;
    overscroll-behavior: contain;
    scrollbar-gutter: stable;
  }

  .game-detail-activation {
    container: game-detail-activation / inline-size;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .game-detail-activation__metadata {
    display: flex;
    min-inline-size: 0;
    align-items: safe center;
    flex-wrap: wrap;
    justify-content: flex-start;
    gap: 0.55em;
    font-size: 0.8rem;
  }

  .game-detail-activation__metadata:empty {
    display: none;
  }

  @supports selector(:has(*)) {
    .game-detail-activation__metadata:not(:has(> *)) {
      display: none;
    }
  }

  .game-detail-activation__body {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  @container game-detail-activation (min-width: 22rem) {
    .game-detail-activation__metadata {
      flex-wrap: nowrap;
      gap: 0.45em;
      font-size: clamp(0.8rem, 3.75cqi, 0.9rem);
    }
  }

  @media (max-width: 48rem) {
    .game-detail-shell {
      padding-inline: 1rem;
    }

    .game-detail-layout {
      grid-template-columns: minmax(0, 1fr);
      gap: 1rem;
    }

    .game-detail-description-panel {
      max-block-size: none;
      overflow: visible;
    }

    .game-detail-activation__metadata {
      align-items: flex-start;
    }
  }

  @media (max-width: 34rem) {
    .game-detail-preview {
      aspect-ratio: 1.75 / 1;
      min-block-size: 13rem;
    }

    .game-detail-chip {
      inset-inline-start: 0.75rem;
      inset-inline-end: auto;
      inset-block-start: 0.75rem;
      inset-block-end: auto;
      max-inline-size: calc(100% - 1.5rem);
    }
  }
</style>
