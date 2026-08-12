<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Props = InertiaProps<{
    email: string;
    reauthenticate: boolean;
    token: string;
  }>;

  const { email, reauthenticate, token }: Props = $props();
</script>

<svelte:head>
  <title>Log in · D20</title>
</svelte:head>

<div class="confirmation-page">
  <h1 class="confirmation-page__title">Log in</h1>
  <p class="confirmation-page__email">{email}</p>
  <p class="confirmation-page__description">Use this magic link to continue to D20.</p>

  <Form class="confirmation-form" method="post" action="/users/log-in" disableWhileProcessing>
    {#snippet children({ errors, processing }: FormSlotProps)}
      <input type="hidden" name="user[token]" value={token} />

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
        {processing ? "Logging in..." : "Log in"}
      </button>
    {/snippet}
  </Form>
</div>

<style>
  .confirmation-page {
    box-sizing: border-box;
    display: grid;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    min-block-size: 100%;
    margin-inline: auto;
    padding: 2rem 1rem 3rem;
    align-content: start;
    gap: 1rem;
    color: var(--color-base-content);
  }

  .confirmation-page__title,
  .confirmation-page__email,
  .confirmation-page__description {
    margin: 0;
  }

  .confirmation-page__title {
    font-size: clamp(1.35rem, 4vw, 1.85rem);
  }

  .confirmation-page__email {
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
    margin: 0;
    color: var(--color-error);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  :where(button, input):focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (max-width: 34rem) {
    .confirmation-page {
      padding-block: 1rem 2rem;
    }
  }
</style>
