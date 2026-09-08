<script lang="ts">
  import { inertia } from "@inertiajs/svelte";
</script>

<svelte:head>
  <title>About D20</title>
</svelte:head>

<article class="about-page">
  <h1 class="about-page__title">About D20</h1>
  <p>
    D20 is a fan project creating digital versions of well-known board games. We want to make the
    joy of a great game easier to share, wherever your friends are.
  </p>

  <section class="about-page__section">
    <h2>A seat for every player</h2>
    <p>
      Love board games? You're in good company. Tell us what you'd love to play, share your
      feedback, and help shape a place you'll want to bring your friends.
    </p>
    <a href="/contact" use:inertia>Share your ideas</a>
  </section>

  <section class="about-page__section">
    <h2>Bring your game to more people</h2>
    <p>
      Publishers and game designers, let's give your games a new place to shine. We'd love to work
      with you on digital adaptations that capture what makes them special and welcome new players
      to the table.
    </p>
    <a href="/rights-holders" use:inertia>Talk about your game</a>
  </section>

  <section class="about-page__section">
    <h2>Let's build something fun</h2>
    <p>
      Developers and designers, there's room for your ideas here. Help turn clever rules into smooth
      play, create welcoming interfaces, and bring more great games to the browser. Let's make
      someone's next game night a little brighter.
    </p>
    <p><a href="/contact" use:inertia>Join the project</a></p>
    <a href="/developers" use:inertia>For developers</a>
  </section>
</article>

<style>
  .about-page {
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

  .about-page__title {
    margin: 0;
    font-size: clamp(1.75rem, 1.25rem + 2vw, 2.5rem);
    font-weight: 650;
    letter-spacing: -0.055em;
    line-height: 1.1;
    text-wrap: balance;
  }

  .about-page__section {
    margin-block-start: 2rem;
  }

  .about-page__section h2 {
    margin: 0;
    font-size: 1.25rem;
    font-weight: 600;
    line-height: 1.4;
  }

  .about-page p {
    max-inline-size: 65ch;
    margin-block: 1rem;
  }

  .about-page a {
    color: inherit;
    text-decoration: underline;
    text-underline-offset: 0.2em;
  }

  .about-page a:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
</style>
