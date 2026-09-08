<script lang="ts">
  import { inertia, usePage } from "@inertiajs/svelte";

  import { auth } from "~/shared/stores";

  type Props = {
    variant?: "narrow" | "wide";
  };

  const { variant = "narrow" }: Props = $props();
  const page = usePage();
</script>

<footer class:footer--wide={variant === "wide"}>
  <div class="footer__inner">
    <div class="footer__directory">
      <div class="footer__info">
        <p class="footer__copyright">d20 © {new Date().getFullYear()}</p>
        {#if !page.props.auth.authenticated}
          <div class="footer__account">
            <button
              class="footer__link footer__account-action"
              type="button"
              onclick={() => {
                auth.trigger.open();
                auth.trigger.switchMode({ mode: "register" });
              }}>Sign up</button
            >
            <span aria-hidden="true">·</span>
            <span>
              Have an account?
              <button
                class="footer__link footer__account-action"
                type="button"
                onclick={() => auth.trigger.open()}>Sign in</button
              >
            </span>
          </div>
        {/if}
        <nav aria-label="Footer information">
          <a class="footer__link" href="/terms">Terms</a>
        </nav>
      </div>

      <nav class="footer__group" aria-label="Explore">
        <h2 class="footer__heading">Explore</h2>
        <a class="footer__link" href="/about" use:inertia>About</a>
        <a class="footer__link" href="/rights-holders" use:inertia
          >For publishers and rightholders</a
        >
        <a class="footer__link" href="/developers" use:inertia>For developers</a>
      </nav>

      <nav class="footer__group" aria-label="Help">
        <h2 class="footer__heading">Help</h2>
        <a class="footer__link" href="/help">How to play</a>
        <a class="footer__link" href="/help#faq">FAQ</a>
        <a class="footer__link" href="/contact" use:inertia>Contact / support</a>
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
    padding-block-end: calc(0.5rem + env(safe-area-inset-bottom));
  }

  .footer--wide .footer__inner {
    max-inline-size: 64rem;
    padding-inline: 1.5rem;
  }

  .footer__directory {
    display: grid;
    grid-template-columns: minmax(0, 1.25fr) repeat(2, minmax(0, 1fr));
    padding-block: 1rem;
    border-block-start: 1px solid var(--color-base-300);
  }

  .footer__info,
  .footer__group {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    gap: 0.375rem;
    min-inline-size: 0;
  }

  .footer__info {
    padding-inline-end: 1.5rem;
  }

  .footer__group {
    padding-inline: 1.5rem;
    border-inline-start: 1px solid var(--color-base-300);
  }

  .footer__group:last-child {
    padding-inline-end: 0;
  }

  .footer__copyright {
    margin: 0;
    min-block-size: 1.5rem;
  }

  .footer__link {
    display: inline-flex;
    align-items: center;
    min-block-size: 1.5rem;
    max-inline-size: 100%;
    color: inherit;
    text-decoration: none;
    text-underline-offset: 0.2em;
  }

  .footer__account {
    display: flex;
    align-items: baseline;
    flex-wrap: wrap;
    gap: 0 0.5rem;
  }

  .footer__account-action {
    padding: 0;
    border: 0;
    background: transparent;
    font: inherit;
    text-decoration: underline;
    cursor: pointer;
  }

  .footer__link:hover {
    text-decoration: underline;
  }

  .footer__heading {
    margin: 0;
    min-block-size: 1.5rem;
    font: inherit;
    font-weight: 600;
  }

  .footer__link:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }

  @media (max-width: 48rem) {
    .footer--wide .footer__inner {
      padding-inline: 1rem;
    }

    .footer__directory {
      grid-template-columns: repeat(2, minmax(0, 1fr));
      row-gap: 1rem;
    }

    .footer__info {
      grid-column: 1 / -1;
      padding-inline-end: 0;
      padding-block-end: 1rem;
      border-block-end: 1px solid var(--color-base-300);
    }

    .footer__group {
      padding-inline: 0 1rem;
      border-inline-start: 0;
    }

    .footer__group:last-child {
      padding-inline-start: 1rem;
      border-inline-start: 1px solid var(--color-base-300);
    }
  }
</style>
