<script lang="ts">
  import { inertia } from "@inertiajs/svelte";

  type Variant = "narrow" | "wide";

  type Props = {
    variant?: Variant;
  };

  const { variant = "narrow" }: Props = $props();
</script>

<footer
  class={{
    footer: true,
    "footer--wide": variant === "wide",
  }}
>
  <div class="footer__inner">
    <a class="footer__link" href="/developers" use:inertia={{ href: "/developers" }}
      >for developers</a
    >
  </div>
</footer>

<style>
  .footer {
    width: 100%;
    overflow: hidden;
  }

  .footer__inner {
    display: flex;
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding-inline: 1rem;
    padding-block: 0.625rem max(0.625rem, env(safe-area-inset-bottom));
    align-items: center;
    justify-content: flex-end;
  }

  .footer--wide .footer__inner {
    max-inline-size: 64rem;
    padding-inline: 1.5rem;
  }

  .footer__link {
    color: color-mix(in oklab, var(--color-base-content) 58%, transparent);
    font-size: 0.6875rem;
    letter-spacing: 0.08em;
    line-height: 1;
    text-decoration: underline;
    text-decoration-color: color-mix(in oklab, currentColor 50%, transparent);
    text-underline-offset: 0.2em;
    text-transform: uppercase;
    transition: color 160ms ease;
  }

  .footer__link:focus-visible {
    outline: 1px solid currentColor;
    outline-offset: 0.25rem;
  }

  @media (max-width: 48rem) {
    .footer--wide .footer__inner {
      padding-inline: 1rem;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .footer__link {
      transition: none;
    }
  }
</style>
