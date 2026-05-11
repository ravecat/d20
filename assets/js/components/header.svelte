<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import { current } from "~actions/current";

  const links = [
    { href: "/cursors", label: "CURSORS" },
    { href: "/games", label: "GAMES" },
  ] as const;
</script>

<header class="header">
  <div class="inner">
    <a class="brand" href="/" use:inertia={{ href: "/" }}>
      <span class="icon hero-puzzle-piece" aria-hidden="true"></span>
      <span>D20</span>
    </a>

    <nav aria-label="Primary">
      <ul class="nav-list">
        {#each links as link (link.href)}
          <li>
            <a
              class="nav-link"
              href={link.href}
              use:inertia={{ href: link.href }}
              use:current={link.href}
            >
              {link.label}
            </a>
          </li>
        {/each}
      </ul>
    </nav>
  </div>
</header>

<style>
  .header {
    width: 100%;
  }

  .inner {
    display: flex;
    width: 100%;
    max-width: 46.25rem;
    margin: 0 auto;
    padding: 1.375rem 1.5rem;
    align-items: center;
    justify-content: space-between;
    gap: 1.5rem;
  }

  .brand,
  .nav-link {
    text-transform: uppercase;
    transition: color 160ms ease;
  }

  .brand {
    display: inline-flex;
    align-items: center;
    gap: 0.5625rem;
    letter-spacing: 0.18em;
  }

  .nav-list {
    display: flex;
    margin: 0;
    padding: 0;
    align-items: center;
    gap: 1.375rem;
    list-style: none;
  }

  .nav-link {
    letter-spacing: 0.15em;
  }

  .brand:focus-visible,
  .nav-link:focus-visible {
    outline: 1px solid currentColor;
    outline-offset: 0.375rem;
  }

  @media (max-width: 34rem) {
    .inner {
      padding-inline: 1rem;
      gap: 1rem;
    }

    .nav-list {
      flex-wrap: wrap;
      gap: 1rem;
    }
  }
</style>
