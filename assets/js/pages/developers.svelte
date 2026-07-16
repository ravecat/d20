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
  type Specification = {
    game: string;
    referenceUrl: string;
    rawUrl: string;
  };

  const specifications: Specification[] = [
    {
      game: "Qwinto",
      referenceUrl: "/developers/specs/qwinto",
      rawUrl: "/developers/specs/qwinto/raw",
    },
    {
      game: "Koala Rescue Club",
      referenceUrl: "/developers/specs/koala-rescue-club",
      rawUrl: "/developers/specs/koala-rescue-club/raw",
    },
    {
      game: "Next Station London",
      referenceUrl: "/developers/specs/next-station-london",
      rawUrl: "/developers/specs/next-station-london/raw",
    },
  ];
</script>

<svelte:head>
  <title>For developers</title>
</svelte:head>

<div class="developers-page">
  <article class="developers-shell">
    <header class="developers-intro">
      <h1>For developers</h1>
      <p class="developers-intro__summary">
        Build a compatible game client from the same contracts used by D20. These AsyncAPI
        specifications describe how clients connect to sessions, send commands, and receive
        authoritative game projections.
      </p>
    </header>

    <ul class="spec-list" aria-label="Game specifications" role="list">
      {#each specifications as specification (specification.game)}
        <li class="spec-list__item">
          <span class="spec-list__game">{specification.game}</span>
          <span class="spec-list__actions">
            <a href={specification.referenceUrl} aria-label={`Open ${specification.game} reference`}
              >Open reference</a
            >
            <a href={specification.rawUrl} aria-label={`View ${specification.game} YAML`}>YAML</a>
          </span>
        </li>
      {/each}
    </ul>
  </article>
</div>

<style>
  .developers-page {
    min-block-size: 100%;
    background: var(--color-base-100);
    color: var(--color-base-content);
  }

  .developers-shell {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding: 1.5rem 1.5rem 2.5rem;
  }

  .developers-intro {
    margin-block-end: 2rem;
  }

  .developers-intro h1 {
    margin: 0;
    font-size: clamp(1.75rem, 5vw, 2.5rem);
    font-weight: 650;
    letter-spacing: -0.055em;
    line-height: 0.98;
    text-wrap: balance;
  }

  .developers-intro__summary {
    margin: 1rem 0 0;
    color: color-mix(in oklab, var(--color-base-content) 68%, transparent);
    font-size: 0.875rem;
    line-height: 1.75;
    text-wrap: pretty;
  }

  .spec-list {
    margin: 0;
    padding: 0;
    border-block-start: 1px solid var(--color-base-300);
    list-style: none;
  }

  .spec-list__item {
    display: flex;
    padding-block: 0.875rem;
    align-items: baseline;
    gap: 1rem;
    border-block-end: 1px solid color-mix(in oklab, var(--color-base-300) 78%, transparent);
    white-space: nowrap;
  }

  .spec-list__game {
    min-inline-size: 0;
    margin-inline-end: auto;
    font-size: 0.875rem;
    font-weight: 650;
    line-height: 1.4;
  }

  .spec-list__actions {
    display: flex;
    flex: none;
    gap: 1rem;
  }

  .spec-list__actions a {
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.6875rem;
    line-height: 1.4;
    text-decoration: underline;
    text-decoration-color: color-mix(in oklab, currentColor 42%, transparent);
    text-underline-offset: 0.25em;
  }

  .spec-list__actions a:hover {
    color: var(--color-base-content);
    text-decoration-color: currentColor;
  }

  .spec-list__actions a:focus-visible {
    border-radius: 0.125rem;
    outline: 2px solid currentColor;
    outline-offset: 0.25rem;
  }

  @media (max-width: 36rem) {
    .developers-shell {
      padding: 1rem 1rem 2rem;
    }

    .developers-intro {
      margin-block-end: 1.75rem;
    }

    .developers-intro h1 {
      font-size: clamp(1.75rem, 10vw, 2.25rem);
    }

    .spec-list__item {
      gap: 0.5rem;
    }

    .spec-list__game {
      font-size: 0.75rem;
    }

    .spec-list__actions {
      gap: 0.625rem;
    }

    .spec-list__actions a {
      font-size: 0.625rem;
    }
  }
</style>
