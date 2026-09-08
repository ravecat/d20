<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
</script>

<svelte:head>
  <title>For Publishers and Rightholders</title>
</svelte:head>

<article class="rights-page">
  <h1 class="rights-page__title">For Publishers and Rightholders</h1>
  <p>
    Want to bring a game to D20 or raise a concern about existing game content? Email
    <a href="mailto:rights@d20.ravecat.io">rights@d20.ravecat.io</a>.
  </p>

  <section class="rights-page__section">
    <h2>Propose a game</h2>
    <p>
      If you are a publisher, designer, or rights holder, tell us about the game you would like to
      adapt or make available on D20. Include the game title, an official product or rules link,
      your role, and what you would like to discuss.
    </p>
    <p>Share only materials you are authorized to share.</p>
  </section>

  <section class="rights-page__section">
    <h2>Raise a rights concern</h2>
    <p>
      Identify the game and D20 page involved, point to the text, artwork, attribution, or other
      content concerned, and describe your request. Explain your relationship to the relevant rights
      and include a way to contact you.
    </p>
  </section>

  <section class="rights-page__section">
    <h2>Need help playing?</h2>
    <p>For technical problems, account access, or general feedback, contact Support.</p>
    <a href="/contact" use:inertia>Contact / Support</a>
  </section>
</article>

<style>
  .rights-page {
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

  .rights-page__title {
    margin: 0;
    font-size: clamp(1.75rem, 1.25rem + 2vw, 2.5rem);
    font-weight: 650;
    letter-spacing: -0.055em;
    line-height: 1.1;
    text-wrap: balance;
  }

  .rights-page__section {
    margin-block-start: 2rem;
  }

  .rights-page__section h2 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1.4;
  }

  .rights-page p {
    max-inline-size: 65ch;
    margin-block: 1rem;
  }

  .rights-page a {
    color: inherit;
    text-decoration: underline;
    text-underline-offset: 0.2em;
  }

  .rights-page a:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
</style>
