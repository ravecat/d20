<script lang="ts">
  import type { VisitOptions } from "@inertiajs/core";
  import { Form, usePage } from "@inertiajs/svelte";
  import { auth } from "~/shared/stores/auth";
  import type { FavoriteDescriptor } from "~/shared/types/game";

  let {
    favorite,
    saved,
    title,
    tabindex = 0,
  }: {
    favorite: FavoriteDescriptor;
    saved: boolean;
    title?: string | null;
    tabindex?: number;
  } = $props();

  const page = usePage();
  const options: VisitOptions = {
    only: ["favorites", "auth", "errors"],
    preserveState: true,
    preserveScroll: true,
  };

  function beforeSubmit() {
    if (!page.props.auth.authenticated) {
      auth.trigger.open();
      return false;
    }
  }
</script>

<Form
  action={favorite.action}
  method={saved ? "delete" : "put"}
  {options}
  onBefore={beforeSubmit}
  onError={(errors) => {
    if (errors.authentication) auth.trigger.open();
  }}
>
  {#snippet children({ processing })}
    {#if !saved}
      <input type="hidden" name="slug" value={favorite.slug} />
    {/if}
    <input type="hidden" name="response_to" value={page.url} />
    <button
      type="submit"
      class="favorite-button"
      class:favorite-button--saved={saved}
      aria-label={saved
        ? title
          ? `Remove ${title} from favorites`
          : "Remove from favorites"
        : title
          ? `Add ${title} to favorites`
          : "Add to favorites"}
      aria-pressed={saved}
      aria-busy={processing}
      aria-disabled={processing}
      onclick={(event) => {
        if (processing) event.preventDefault();
      }}
      {tabindex}
    >
      <svg class="favorite-button__star" viewBox="0 0 24 24" aria-hidden="true">
        <path d="m12 3 2.8 5.7 6.3.9-4.6 4.5 1.1 6.3-5.6-3-5.6 3 1.1-6.3L3 9.6l6.2-.9Z" />
      </svg>
    </button>
  {/snippet}
</Form>

<style>
  .favorite-button {
    position: relative;
    display: flex;
    inline-size: 1em;
    block-size: 1em;
    min-inline-size: 0;
    min-block-size: 0;
    align-items: flex-start;
    justify-content: flex-end;
    border: 0;
    background: transparent;
    padding: 0;
    fill: none;
    stroke: #eab308;
    cursor: pointer;
    pointer-events: auto;
    font-size: inherit;
  }

  .favorite-button--saved {
    fill: #eab308;
  }

  .favorite-button:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: -2px;
    fill: #eab308;
  }

  .favorite-button[aria-disabled="true"] {
    cursor: wait;
  }

  .favorite-button__star {
    inline-size: 1em;
    block-size: 1em;
    flex: none;
    stroke-width: 1.8;
    stroke-linejoin: round;
  }

  @media (hover: hover) {
    .favorite-button:hover {
      fill: #eab308;
    }
  }
</style>
