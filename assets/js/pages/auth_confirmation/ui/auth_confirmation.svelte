<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Props = InertiaProps<{
    confirmed: boolean;
    email: string;
    reauthenticate: boolean;
    token: string;
  }>;

  const { confirmed, email, reauthenticate, token }: Props = $props();
</script>

<svelte:head>
  <title>{confirmed ? "Log in" : "Confirm account"} · D20</title>
</svelte:head>

<div class="confirmation-page">
  <section class="confirmation-card" aria-labelledby="confirmation-title">
    <h1 id="confirmation-title">{confirmed ? "Log in" : "Confirm your account"}</h1>
    <p class="confirmation-card__email">{email}</p>
    <p>
      {#if confirmed}
        Use this magic link to continue to D20.
      {:else}
        Confirm this email address to finish creating your D20 account.
      {/if}
    </p>

    <Form class="confirmation-form" method="post" action="/users/log-in" disableWhileProcessing>
      {#snippet children({ errors, processing }: FormSlotProps)}
        <input type="hidden" name="user[token]" value={token} />
        {#if !confirmed}
          <input type="hidden" name="_action" value="confirmed" />
        {/if}

        {#if !reauthenticate}
          <label class="confirmation-form__remember">
            <input type="checkbox" name="user[remember_me]" value="true" />
            <span>Keep me signed in</span>
          </label>
        {/if}

        {#if errors.token}
          <p class="confirmation-form__error" role="alert">{errors.token}</p>
        {/if}

        <button type="submit" disabled={processing}>
          {processing
            ? confirmed
              ? "Logging in..."
              : "Confirming..."
            : confirmed
              ? "Log in"
              : "Confirm account"}
        </button>
      {/snippet}
    </Form>

    {#if !confirmed}
      <p class="confirmation-card__tip">You can add a password later from account settings.</p>
    {/if}
  </section>
</div>

<style>
  .confirmation-page {
    box-sizing: border-box;
    inline-size: min(100%, 36rem);
    min-block-size: 100%;
    margin-inline: auto;
    padding: 2rem 1rem;
  }

  .confirmation-card {
    display: grid;
    gap: 1rem;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 18%, transparent);
    border-radius: var(--radius-box);
    background: var(--color-base-100);
    padding: 1.5rem;
    box-shadow: 0 1rem 3rem rgb(0 0 0 / 0.16);
  }

  .confirmation-card h1,
  .confirmation-card p {
    margin: 0;
  }

  .confirmation-card h1 {
    font-size: clamp(1.35rem, 4vw, 1.85rem);
  }

  .confirmation-card__email {
    overflow-wrap: anywhere;
    color: var(--color-primary);
    font-weight: 700;
  }

  :global(.confirmation-form) {
    display: grid;
    gap: 1rem;
  }

  .confirmation-form__remember {
    display: inline-flex;
    inline-size: fit-content;
    align-items: center;
    gap: 0.55rem;
    font-size: 0.85rem;
    cursor: pointer;
  }

  .confirmation-form__remember input {
    inline-size: 1rem;
    block-size: 1rem;
    margin: 0;
  }

  :global(.confirmation-form button) {
    min-block-size: 3rem;
    border: 0;
    border-radius: var(--radius-field);
    background: var(--color-primary);
    padding-inline: 1rem;
    color: var(--color-primary-content);
    font: inherit;
    font-weight: 700;
    cursor: pointer;
  }

  :global(.confirmation-form button:disabled) {
    cursor: wait;
    opacity: 0.68;
  }

  .confirmation-form__error {
    color: var(--color-error);
    font-size: 0.8rem;
  }

  .confirmation-card__tip {
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 18%, transparent);
    border-radius: var(--radius-field);
    padding: 0.85rem;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.85rem;
  }

  :where(button, input):focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (max-width: 34rem) {
    .confirmation-page {
      padding: 1rem 0.5rem;
    }

    .confirmation-card {
      padding: 1rem;
    }
  }
</style>
