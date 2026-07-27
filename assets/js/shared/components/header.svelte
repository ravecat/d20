<script lang="ts">
  import { inertia } from "@inertiajs/svelte";

  type Variant = "default" | "narrow";

  type Props = {
    compact?: boolean;
    overlay?: boolean;
    variant?: Variant;
  };

  const { compact = false, overlay = false, variant = "default" }: Props = $props();
</script>

<header
  class={{
    header: true,
    "header--compact": compact,
    "header--narrow": variant === "narrow",
    "header--overlay": overlay,
  }}
>
  <div class="header__inner">
    <a class="brand" href="/" use:inertia={{ href: "/" }}>
      <span class="brand__mark" aria-hidden="true"></span>
      <span class="brand__label">D20</span>
    </a>
  </div>
</header>

<style>
  .header {
    position: sticky;
    inset-block-start: 0;
    z-index: 20;
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

  .header__inner {
    display: flex;
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 64rem;
    margin-inline: auto;
    padding: 1rem 1.5rem;
    align-items: center;
    gap: 1.5rem;
    transition: padding-block 180ms ease;
  }

  .header--narrow .header__inner {
    max-inline-size: 46.25rem;
  }

  .header--compact .header__inner {
    padding-block: 0.5rem;
  }

  .brand {
    display: inline-flex;
    align-items: center;
    gap: 0.5625rem;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    transition:
      color 160ms ease,
      gap 180ms ease;
  }

  .brand__mark {
    display: block;
    inline-size: 2.612rem;
    block-size: 3rem;
    flex: none;
    background: url("/images/d20.svg") center / contain no-repeat;
    transition:
      inline-size 180ms ease,
      block-size 180ms ease;
  }

  .brand__label {
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1;
    transition:
      font-size 180ms ease,
      letter-spacing 180ms ease;
  }

  .header--compact .brand {
    gap: 0.4rem;
  }

  .header--compact .brand__mark {
    inline-size: 1.742rem;
    block-size: 2rem;
  }

  .header--compact .brand__label {
    font-size: 0.75rem;
    letter-spacing: 0.12em;
  }

  .header--overlay .brand {
    pointer-events: auto;
  }

  .brand:focus-visible {
    outline: none;
  }

  .brand:focus-visible .brand__label {
    text-decoration-line: underline;
    text-decoration-thickness: 0.125rem;
    text-underline-offset: 0.35em;
  }

  @media (max-width: 48rem) {
    .header__inner {
      padding-inline: 1rem;
    }
  }

  @media (max-width: 34rem) {
    .header__inner {
      gap: 1rem;
    }

    .brand__mark {
      inline-size: 2.177rem;
      block-size: 2.5rem;
    }

    .header--compact .brand__mark {
      inline-size: 1.742rem;
      block-size: 2rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .header__inner,
    .brand,
    .brand__mark,
    .brand__label {
      transition: none;
    }
  }
</style>
