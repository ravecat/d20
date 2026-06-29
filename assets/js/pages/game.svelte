<script lang="ts">
  import { useForm } from "@inertiajs/svelte";
  import SessionPanel from "~components/session_panel.svelte";
  import type { GameMetadata, Session } from "~types/game";
  import type { ModuleConnection, ModuleEntry } from "~types/module";

  type Props = InertiaProps<{
    slug: string;
    game: GameMetadata;
    module: ModuleEntry | null;
    connection: ModuleConnection | null;
    session: Session | null;
  }>;

  const { slug, game, module, connection, session }: Props = $props();
  const sessionForm = useForm<Record<string, string>>({});

  const handleStartSession = () => {
    if ($sessionForm.processing) {
      $sessionForm.cancel();
      return;
    }

    $sessionForm.clearErrors();
    $sessionForm.post(`/games/${slug}/sessions`);
  };
</script>

<main class="bg-base-100 text-base-content">
  <section class="mx-auto w-full max-w-185 px-6 py-6 max-[34rem]:px-4">
    <article class="min-w-0">
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
          >
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

      {#if game.description}
        <p class="game-detail-description">{game.description}</p>
      {/if}

      {#if session && module && connection}
        {#key session.id}
          <SessionPanel {module} {connection} />
        {/key}
      {:else}
        <div class="mt-6">
          <button
            class="inline-flex min-h-10 min-w-28 items-center justify-center gap-2 rounded-sm border border-base-content bg-base-content px-5 py-2 text-sm font-medium text-base-100 transition-colors hover:bg-base-content/85 focus:outline-none focus:ring-2 focus:ring-base-content/40"
            type="button"
            aria-busy={$sessionForm.processing}
            onclick={handleStartSession}
          >
            {#if $sessionForm.processing}
              <span
                class="h-3.5 w-3.5 animate-spin rounded-full border-2 border-base-100/35 border-t-base-100"
                aria-hidden="true"
              ></span>
              Cancel
            {:else}
              Play
            {/if}
          </button>
        </div>
      {/if}

      {#if $sessionForm.errors.startSession}
        <p class="mt-3 text-sm text-error">{$sessionForm.errors.startSession}</p>
      {/if}
    </article>
  </section>
</main>

<style>
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
    display: inline-flex;
    max-inline-size: calc(100% - 2rem);
    align-items: baseline;
    gap: 0.65rem;
    border: 1px solid rgb(255 255 255 / 0.34);
    border-radius: 0.35rem;
    padding: 0.45rem 0.8rem;
    background: rgb(10 10 10 / 0.68);
    color: white;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.5);
    backdrop-filter: blur(10px) saturate(1.25);
    box-shadow: 0 8px 18px rgb(0 0 0 / 0.22);
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
    display: -webkit-box;
    inline-size: 100%;
    overflow: hidden;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 4;
    line-clamp: 4;
    margin-block-start: 1.25rem;
    color: color-mix(in oklab, var(--color-base-content) 75%, transparent);
    font-size: 0.875rem;
    line-height: 1.7;
    text-overflow: ellipsis;
    text-wrap: pretty;
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
      flex-wrap: wrap;
      row-gap: 0.35rem;
    }
  }
</style>
