<script lang="ts">
  import { Form, usePage } from "@inertiajs/svelte";
  import { auth } from "~/shared/stores/auth";
  import type { GameInterest } from "~/shared/types/game";

  const { interest }: { interest: GameInterest } = $props();
  const countDescriptionId = $props.id();
  const page = usePage();

  function beforeSubmit() {
    if (interest.requested) return false;

    if (!page.props.auth.authenticated) {
      auth.trigger.open({
        prompt: {
          email: null,
          identifier: "",
          kind: "info",
          message: "Log in to request this game.",
          reauthenticate: false,
          returnTo: page.url,
        },
      });
      return false;
    }
  }
</script>

<Form action={interest.action} method="post" errorBag="interest" onBefore={beforeSubmit}>
  {#snippet children({ processing, errors })}
    {@const message = errors.message ?? page.props.errors.interest?.message}
    <button
      type="submit"
      disabled={processing || interest.requested}
      aria-busy={processing}
      aria-describedby={countDescriptionId}
    >
      <span class="interest-form__count" aria-hidden="true">
        {interest.count}
        <svg
          class="interest-form__star"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
          stroke-linecap="round"
          stroke-linejoin="round"
          aria-hidden="true"
          focusable="false"
        >
          <path
            d="M12 3.5l2.75 5.57 6.15.9-4.45 4.34 1.05 6.13L12 17.55l-5.5 2.89 1.05-6.13L3.1 9.97l6.15-.9L12 3.5z"
          ></path>
        </svg>
      </span>
      <span
        >{interest.requested ? "Requested" : processing ? "Saving..." : "I want this game!"}</span
      >
    </button>
    <span id={countDescriptionId} hidden>
      {interest.count}
      {interest.count === 1 ? "player has" : "players have"} requested this game.
    </span>
    {#if !interest.requested && !processing && message}
      <p role="alert">{message}</p>
    {/if}
  {/snippet}
</Form>

<style>
  button {
    box-sizing: border-box;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    inline-size: 100%;
    min-block-size: 2.5rem;
    padding: 0.5rem 1rem;
    border: 1px solid var(--color-base-content);
    border-radius: var(--radius-sm);
    background: var(--color-base-content);
    color: var(--color-base-100);
    font: inherit;
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1.25;
    cursor: pointer;
  }

  button:hover:not(:disabled) {
    background: color-mix(in oklab, var(--color-base-content) 86%, transparent);
  }

  button:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 42%, transparent);
    outline-offset: 0.125rem;
  }

  button:disabled {
    cursor: not-allowed;
    opacity: 0.55;
  }

  .interest-form__count {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    flex: none;
    font-variant-numeric: tabular-nums;
  }

  .interest-form__star {
    inline-size: 1.25em;
    block-size: 1.25em;
  }

  p {
    margin-block: 0.5rem 0;
    font-size: 0.8125rem;
  }

  [role="alert"] {
    color: var(--color-error);
  }
</style>
