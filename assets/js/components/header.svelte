<script lang="ts">
  import { inertia } from "@inertiajs/svelte";

  const { overlay = false }: { overlay?: boolean } = $props();
</script>

<header class={{ header: true, "header--overlay": overlay }}>
  <div class="inner"><a class="brand" href="/" use:inertia={{ href: "/" }}>
    <span class="icon hero-puzzle-piece" aria-hidden="true"></span>
    <span>D20</span>
  </a></div>
</header>

<style>
  .header {
    width: 100%;
  }

  .header--overlay {
    position: absolute;
    inset-block-start: 0;
    inset-inline: 0;
    z-index: 10;
    background: transparent;
    pointer-events: none;
  }

  .inner {
    display: flex;
    width: 100%;
    max-width: 46.25rem;
    margin: 0 auto;
    padding: 1.375rem 1.5rem;
    align-items: center;
    gap: 1.5rem;
  }

  .brand {
    display: inline-flex;
    align-items: center;
    gap: 0.5625rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    transition: color 160ms ease;
  }

  .header--overlay .brand {
    pointer-events: auto;
  }

  .brand:focus-visible {
    outline: 1px solid currentColor;
    outline-offset: 0.375rem;
  }

  @media (max-width: 34rem) {
    .inner {
      padding-inline: 1rem;
      gap: 1rem;
    }
  }
</style>
