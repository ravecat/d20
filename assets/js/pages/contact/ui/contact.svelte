<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
</script>

<svelte:head>
  <title>Contact / Support</title>
</svelte:head>

<article class="contact-page">
  <h1 class="contact-page__title">Contact / Support</h1>
  <p>
    Need help with D20 or have feedback? Email
    <a href="mailto:support@d20.ravecat.io">support@d20.ravecat.io</a>.
  </p>

  <section class="contact-page__section">
    <h2>Technical problems and feedback</h2>
    <p>
      Tell us which game or page you were using, what you expected, and what happened instead.
      Include your browser name and version. For feedback, describe what you would like to improve
      and how it would help you play.
    </p>
    <p>If you share a screenshot, remove personal information and sign-in details first.</p>
  </section>

  <section class="contact-page__section">
    <h2>Accounts and privacy</h2>
    <p>
      Use the support address above for account-access or privacy questions, including when you
      cannot sign in. Describe the problem without sending passwords, one-time sign-in links, or
      provider access tokens.
    </p>
  </section>

  <section class="contact-page__section">
    <h2>Publishers and rights holders</h2>
    <p>
      For game proposals, attribution, or concerns about rights in existing content, email
      <a href="mailto:rights@d20.ravecat.io">rights@d20.ravecat.io</a>.
    </p>
    <a href="/rights-holders" use:inertia>For Publishers and Rightholders</a>
  </section>
</article>

<style>
  .contact-page {
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    margin-inline: auto;
    padding: 1.5rem 1rem 2.5rem;
    color: var(--color-base-content);
    font-size: 1rem;
    line-height: 1.65;
    overflow-wrap: anywhere;
  }

  .contact-page__title {
    margin: 0;
    font-size: clamp(1.75rem, 1.25rem + 2vw, 2.5rem);
    font-weight: 650;
    letter-spacing: -0.055em;
    line-height: 1.1;
    text-wrap: balance;
  }

  .contact-page__section {
    margin-block-start: 2rem;
  }

  .contact-page__section h2 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1.4;
  }

  .contact-page p {
    max-inline-size: 65ch;
    margin-block: 1rem;
  }

  .contact-page a {
    color: inherit;
    text-decoration: underline;
    text-underline-offset: 0.2em;
  }

  .contact-page a:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
</style>
