<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
  import D20 from "~components/d20.svelte";

  type Variant = "default" | "catalog";

  type Props = {
    overlay?: boolean;
    variant?: Variant;
  };

  const { overlay = false, variant = "default" }: Props = $props();
</script>

<header
  class={{
    header: true,
    "header--catalog": variant === "catalog",
    "header--overlay": overlay,
  }}
>
  <div class="inner"><a class="brand" href="/" use:inertia={{ href: "/" }}>
    <D20 />
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
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 64rem;
    margin-inline: auto;
    padding: 1rem 1.5rem;
    align-items: center;
    gap: 1.5rem;
  }

  .header--catalog .inner {
    max-inline-size: 46.25rem;
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

  @media (max-width: 48rem) {
    .inner {
      padding-inline: 1rem;
    }
  }

  @media (max-width: 34rem) {
    .inner {
      gap: 1rem;
    }
  }
</style>
