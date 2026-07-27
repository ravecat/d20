<script lang="ts">
  import { inertia } from "@inertiajs/svelte";

  type Variant = "default" | "narrow";

  type Props = {
    overlay?: boolean;
    variant?: Variant;
  };

  const { overlay = false, variant = "default" }: Props = $props();
</script>

<header
  class={{
    header: true,
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
  }

  .header--narrow .header__inner {
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

  .brand__mark {
    display: block;
    inline-size: 2.612rem;
    block-size: 3rem;
    flex: none;
    background: url("/images/d20.svg") center / contain no-repeat;
  }

  .brand__label {
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1;
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
  }

  @media (prefers-reduced-motion: reduce) {
    .brand {
      transition: none;
    }
  }

  @supports (
    (animation-timeline: scroll()) and (animation-range: 0% 100%) and
      (scroll-timeline: --app-shell-scroll block) and (timeline-scope: --app-shell-scroll)
  ) {
    .header__inner {
      animation: compact-header-inner auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand {
      animation: compact-header-brand auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand__mark {
      animation: compact-header-mark auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    .brand__label {
      animation: compact-header-label auto linear both;
      animation-timeline: --app-shell-scroll;
      animation-range: 0px 24px;
    }

    @media (prefers-reduced-motion: reduce) {
      .header__inner,
      .brand,
      .brand__mark,
      .brand__label {
        animation: none;
      }
    }
  }

  @keyframes compact-header-inner {
    to {
      padding-block: 0.5rem;
    }
  }

  @keyframes compact-header-brand {
    to {
      gap: 0.4rem;
    }
  }

  @keyframes compact-header-mark {
    to {
      inline-size: 1.742rem;
      block-size: 2rem;
    }
  }

  @keyframes compact-header-label {
    to {
      font-size: 0.75rem;
      letter-spacing: 0.12em;
    }
  }
</style>
