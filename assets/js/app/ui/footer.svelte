<script lang="ts">
  import { inertia } from "@inertiajs/svelte";

  type Props = {
    variant?: "narrow" | "wide";
  };

  const { variant = "narrow" }: Props = $props();
</script>

<footer class:footer--wide={variant === "wide"}>
  <div class="footer__inner">
    <div class="footer__directory">
      <nav class="footer__group" aria-label="Explore">
        <div class="footer__desktop">
          <h2 class="footer__heading">Explore</h2>
          <ul class="footer__links">
            <li><a class="footer__link" href="/about" use:inertia>About</a></li>
            <li>
              <a class="footer__link" href="/rights-holders" use:inertia
                >For Publishers and Rightholders</a
              >
            </li>
            <li><a class="footer__link" href="/developers" use:inertia>For developers</a></li>
          </ul>
        </div>
        <details class="footer__mobile" aria-label="Explore">
          <summary class="footer__trigger">
            <h2 class="footer__heading">Explore</h2>
            <svg class="footer__chevron" viewBox="0 0 16 16" aria-hidden="true">
              <path d="m6 3 5 5-5 5" />
            </svg>
          </summary>
          <ul class="footer__links">
            <li><a class="footer__link" href="/about" use:inertia>About</a></li>
            <li>
              <a class="footer__link" href="/rights-holders" use:inertia
                >For Publishers and Rightholders</a
              >
            </li>
            <li><a class="footer__link" href="/developers" use:inertia>For developers</a></li>
          </ul>
        </details>
      </nav>

      <nav class="footer__group" aria-label="Help">
        <div class="footer__desktop">
          <h2 class="footer__heading">Help</h2>
          <ul class="footer__links">
            <li><a class="footer__link" href="/help">How to play</a></li>
            <li><a class="footer__link" href="/help#faq">FAQ</a></li>
            <li><a class="footer__link" href="/contact" use:inertia>Contact / Support</a></li>
          </ul>
        </div>
        <details class="footer__mobile" aria-label="Help">
          <summary class="footer__trigger">
            <h2 class="footer__heading">Help</h2>
            <svg class="footer__chevron" viewBox="0 0 16 16" aria-hidden="true">
              <path d="m6 3 5 5-5 5" />
            </svg>
          </summary>
          <ul class="footer__links">
            <li><a class="footer__link" href="/help">How to play</a></li>
            <li><a class="footer__link" href="/help#faq">FAQ</a></li>
            <li><a class="footer__link" href="/contact" use:inertia>Contact / Support</a></li>
          </ul>
        </details>
      </nav>
    </div>

    <div class="footer__bottom">
      <p class="footer__copyright">© {new Date().getFullYear()} D20</p>
      <nav class="footer__legal" aria-label="Footer information">
        <a class="footer__link" href="/privacy">Privacy</a>
        <a class="footer__link" href="/terms">Terms</a>
      </nav>
    </div>
  </div>
</footer>

<style>
  footer {
    inline-size: 100%;
    color: var(--color-base-content);
    background: var(--color-base-100);
    font-size: 0.8125rem;
    line-height: 1.5;
    overflow-wrap: anywhere;
  }

  .footer__inner {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding-inline: 1rem;
    padding-block: 1rem calc(0.75rem + env(safe-area-inset-bottom));
  }

  .footer--wide .footer__inner {
    max-inline-size: 64rem;
    padding-inline: 1.5rem;
  }

  .footer__directory {
    display: flex;
    gap: 1rem;
    padding-block: 0.5rem;
    border-block: 1px solid var(--color-base-300);
  }

  .footer__group {
    flex: 0 1 12rem;
    min-inline-size: 0;
  }

  .footer__bottom,
  .footer__legal {
    display: flex;
    align-items: baseline;
    justify-content: flex-end;
    flex-wrap: wrap;
    gap: 0.5rem 1rem;
  }

  .footer__bottom {
    padding-block-start: 0.5rem;
  }

  .footer__copyright {
    margin: 0;
    margin-inline-end: auto;
  }

  .footer__link {
    display: inline-flex;
    align-items: center;
    min-block-size: 1.5rem;
    color: inherit;
    text-decoration: none;
    text-underline-offset: 0.2em;
  }

  .footer__link:hover {
    text-decoration: underline;
  }

  .footer__heading {
    margin: 0;
    font: inherit;
    font-weight: 600;
  }

  .footer__mobile {
    display: none;
  }

  .footer__trigger {
    display: flex;
    inline-size: 100%;
    min-block-size: 44px;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.625rem 0;
    cursor: pointer;
  }

  .footer__trigger::-webkit-details-marker {
    display: none;
  }

  .footer__mobile[open] .footer__chevron {
    transform: rotate(90deg);
  }

  .footer__chevron {
    flex: none;
    inline-size: 1rem;
    block-size: 1rem;
    fill: none;
    stroke: currentColor;
    stroke-width: 1.5;
  }

  .footer__links {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .footer__links .footer__link {
    display: flex;
    min-block-size: 0;
    padding-block: 0.25rem;
  }

  .footer__link:focus-visible,
  .footer__trigger:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }

  @media (max-width: 48rem) {
    .footer__desktop {
      display: none;
    }

    .footer__mobile {
      display: block;
    }

    .footer--wide .footer__inner {
      padding-inline: 1rem;
    }

    .footer__directory {
      flex-direction: column;
      gap: 0;
      padding-block: 0;
    }

    .footer__group {
      flex: none;
    }

    .footer__group:not(:last-child) {
      border-block-end: 1px solid var(--color-base-300);
    }

    .footer__links {
      padding-block-end: 0.5rem;
    }

    .footer__links .footer__link {
      box-sizing: border-box;
      min-block-size: 44px;
      padding-inline-start: 0.75rem;
    }
  }
</style>
