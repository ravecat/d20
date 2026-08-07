<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";
  import {
    AgeLabel,
    BggRatingLabel,
    ComplexityLabel,
    Lobby,
    PlayTimeLabel,
    PlayerCountLabel,
  } from "~/shared/components";
  import type { AttrConfig, Attrs, GameMetadata, SessionDescriptor } from "~/shared/types";

  type Props = InertiaProps<{
    slug: string;
    canLaunchGame: boolean;
    game: GameMetadata;
    attrs?: Attrs;
    session?: SessionDescriptor | null;
  }>;
  type SessionFormFields = Record<string, string>;
  type SessionFormSlotProps = FormComponentSlotProps<SessionFormFields>;

  const { slug, canLaunchGame = false, game, attrs = {}, session = null }: Props = $props();
  const formId = $props.id();
  const attrFields = $derived(Object.entries(attrs));

  function fieldValue(attr: AttrConfig) {
    return attr.value == null ? "" : String(attr.value);
  }

  function fieldLabel(value: string) {
    const label = value.replace(/_/g, " ");
    return label.charAt(0).toUpperCase() + label.slice(1);
  }
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
            {:else if canLaunchGame}
              <Form method="post" action={`/games/${slug}/sessions`} disableWhileProcessing>
                {#snippet children({ errors, processing }: SessionFormSlotProps)}
                  <div class="game-detail-start">
                    {#if attrFields.length > 0}
                      <div class="game-detail-start__fields">
                        {#each attrFields as [name, attr] (name)}
                          {@const fieldName = attr.name ?? name}
                          {#if attr.type === "enum"}
                            <fieldset class="game-detail-start__field">
                              <legend>{fieldLabel(name)}</legend>
                              <div class="game-detail-start__options">
                                {#each attr.values ?? [] as value, optionIndex (value)}
                                  {@const optionId = `${formId}-${name}-${optionIndex}`}
                                  <label class="game-detail-start__option" for={optionId}>
                                    <input
                                      id={optionId}
                                      type="radio"
                                      name={fieldName}
                                      {value}
                                      defaultChecked={fieldValue(attr) === value}
                                      required={attr.required ?? false}
                                    />
                                    <span>{fieldLabel(value)}</span>
                                  </label>
                                {/each}
                              </div>
                              {#if errors[name]}
                                <p class="game-detail-activation__error">{errors[name]}</p>
                              {/if}
                            </fieldset>
                          {:else if attr.type === "boolean"}
                            {@const optionId = attr.id || `${formId}-${name}`}
                            <input type="hidden" name={fieldName} value="false" />
                            <div class="game-detail-start__field">
                              <label class="game-detail-start__option" for={optionId}>
                                <input
                                  id={optionId}
                                  type="checkbox"
                                  name={fieldName}
                                  value="true"
                                  defaultChecked={fieldValue(attr) === "true"}
                                />
                                <span>{fieldLabel(name)}</span>
                              </label>
                              {#if errors[name]}
                                <p class="game-detail-activation__error">{errors[name]}</p>
                              {/if}
                            </div>
                          {:else}
                            <label class="game-detail-start__field">
                              <span>{fieldLabel(name)}</span>
                              <input
                                id={attr.id}
                                name={fieldName}
                                value={fieldValue(attr)}
                                required={attr.required ?? false}
                              />
                              {#if errors[name]}
                                <p class="game-detail-activation__error">{errors[name]}</p>
                              {/if}
                            </label>
                          {/if}
                        {/each}
                      </div>
                    {/if}

                    <button class="game-detail-action" type="submit" aria-busy={processing}>
                      {#if processing}
                        <span class="game-detail-action__spinner" aria-hidden="true"></span>
                        Starting
                      {:else}
                        Play
                      {/if}
                    </button>

                    {#if errors.session}
                      <p class="game-detail-activation__error">{errors.session}</p>
                    {/if}
                  </div>
                {/snippet}
              </Form>
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

  .game-detail-start {
    display: flex;
    min-inline-size: 0;
    flex-direction: column;
    gap: 1rem;
  }

  .game-detail-start__fields {
    display: grid;
    min-inline-size: 0;
    gap: 0.75rem;
  }

  .game-detail-start__field {
    min-inline-size: 0;
    margin: 0;
    border: 0;
    padding: 0;
  }

  .game-detail-start__field legend,
  .game-detail-start__field > span {
    display: block;
    margin-block-end: 0.5rem;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.75rem;
    font-weight: 600;
    line-height: 1.2;
  }

  .game-detail-start__field > input {
    inline-size: 100%;
    min-block-size: 2.25rem;
    border: 1px solid var(--color-base-300);
    border-radius: var(--radius-sm);
    padding: 0.45rem 0.65rem;
    background: var(--color-base-100);
    color: var(--color-base-content);
    font: inherit;
  }

  .game-detail-start__options {
    display: flex;
    min-inline-size: 0;
    flex-wrap: wrap;
    gap: 0.5rem;
  }

  .game-detail-start__option {
    display: inline-flex;
    min-block-size: 2.25rem;
    min-inline-size: 0;
    align-items: center;
    gap: 0.45rem;
    border: 1px solid var(--color-base-300);
    border-radius: var(--radius-sm);
    padding: 0.4rem 0.65rem;
    color: var(--color-base-content);
    cursor: pointer;
    font-size: 0.8125rem;
    line-height: 1.2;
  }

  .game-detail-start__option input {
    inline-size: 1rem;
    block-size: 1rem;
    flex: none;
    accent-color: var(--color-base-content);
  }

  @container game-detail-activation (min-width: 22rem) {
    .game-detail-activation__metadata {
      flex-wrap: nowrap;
      gap: 0.45em;
      font-size: clamp(0.8rem, 3.75cqi, 0.9rem);
    }
  }

  .game-detail-action {
    display: inline-flex;
    min-block-size: 2.5rem;
    inline-size: 100%;
    min-inline-size: 0;
    align-self: stretch;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border: 1px solid var(--color-base-content);
    border-radius: var(--radius-sm);
    background: var(--color-base-content);
    padding: 0.5rem 1rem;
    color: var(--color-base-100);
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1;
    transition:
      background-color 150ms ease,
      border-color 150ms ease,
      opacity 150ms ease;
  }

  .game-detail-action:hover {
    background: color-mix(in oklab, var(--color-base-content) 86%, transparent);
  }

  .game-detail-action:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 42%, transparent);
    outline-offset: 2px;
  }

  .game-detail-action:disabled {
    cursor: not-allowed;
    opacity: 0.55;
  }

  .game-detail-action__spinner {
    inline-size: 0.875rem;
    block-size: 0.875rem;
    flex: none;
    animation: game-detail-spin 700ms linear infinite;
    border: 2px solid color-mix(in oklab, var(--color-base-100) 35%, transparent);
    border-block-start-color: var(--color-base-100);
    border-radius: 999px;
  }

  .game-detail-activation__error {
    margin: 0;
    color: var(--color-error);
    font-size: 0.8125rem;
    line-height: 1.4;
  }

  @keyframes game-detail-spin {
    to {
      rotate: 360deg;
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

  @media (prefers-reduced-motion: reduce) {
    .game-detail-action,
    .game-detail-action__spinner {
      animation: none;
      transition: none;
    }
  }
</style>
