<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Props = InertiaProps<{
    email: string;
  }>;

  const { email }: Props = $props();
</script>

<svelte:head>
  <title>Account settings · D20</title>
</svelte:head>

<div class="settings-page">
  <header class="settings-page__header">
    <h1>Account settings</h1>
    <p>Manage the email address and password used by your D20 account.</p>
  </header>

  <section class="settings-card" aria-labelledby="email-settings-title">
    <div>
      <h2 id="email-settings-title">Email address</h2>
      <p>We will send a confirmation link to the new address.</p>
    </div>

    <Form class="settings-form" method="put" action="/users/settings" disableWhileProcessing>
      {#snippet children({ errors, processing }: FormSlotProps)}
        <input type="hidden" name="action" value="update_email" />

        <div class="settings-form__field">
          <label class="settings-page__sr-only" for="settings-email">Email address</label>
          <input
            id="settings-email"
            name="user[email]"
            type="email"
            inputmode="email"
            value={email}
            placeholder="Email address"
            autocomplete="username"
            spellcheck="false"
            required
            aria-invalid={errors.email ? "true" : undefined}
            aria-describedby={errors.email ? "settings-email-error" : undefined}
          />
          {#if errors.email}
            <p id="settings-email-error" class="settings-form__error" role="alert">
              {errors.email}
            </p>
          {/if}
        </div>

        <button type="submit" disabled={processing}>
          {processing ? "Sending confirmation..." : "Change email"}
        </button>
      {/snippet}
    </Form>
  </section>

  <section class="settings-card" aria-labelledby="password-settings-title">
    <div>
      <h2 id="password-settings-title">Password</h2>
      <p>Add or replace the password you can use alongside magic links.</p>
    </div>

    <Form class="settings-form" method="put" action="/users/settings" disableWhileProcessing>
      {#snippet children({ errors, processing }: FormSlotProps)}
        <input type="hidden" name="action" value="update_password" />

        <div class="settings-form__field">
          <label class="settings-page__sr-only" for="settings-new-password">New password</label>
          <input
            id="settings-new-password"
            name="user[password]"
            type="password"
            placeholder="New password"
            autocomplete="new-password"
            required
            aria-invalid={errors.password ? "true" : undefined}
            aria-describedby={errors.password ? "settings-new-password-error" : undefined}
          />
          {#if errors.password}
            <p id="settings-new-password-error" class="settings-form__error" role="alert">
              {errors.password}
            </p>
          {/if}
        </div>

        <div class="settings-form__field">
          <label class="settings-page__sr-only" for="settings-password-confirmation">
            Confirm new password
          </label>
          <input
            id="settings-password-confirmation"
            name="user[password_confirmation]"
            type="password"
            placeholder="Confirm new password"
            autocomplete="new-password"
            required
            aria-invalid={errors.passwordConfirmation ? "true" : undefined}
            aria-describedby={errors.passwordConfirmation
              ? "settings-password-confirmation-error"
              : undefined}
          />
          {#if errors.passwordConfirmation}
            <p id="settings-password-confirmation-error" class="settings-form__error" role="alert">
              {errors.passwordConfirmation}
            </p>
          {/if}
        </div>

        <button type="submit" disabled={processing}>
          {processing ? "Saving password..." : "Save password"}
        </button>
      {/snippet}
    </Form>
  </section>
</div>

<style>
  .settings-page {
    display: grid;
    box-sizing: border-box;
    inline-size: min(100%, 46rem);
    min-block-size: 100%;
    margin-inline: auto;
    padding: 2rem 1rem;
    gap: 1.25rem;
  }

  .settings-page__header,
  .settings-card > div {
    display: grid;
    gap: 0.4rem;
  }

  .settings-page__header h1,
  .settings-page__header p,
  .settings-card h2,
  .settings-card p {
    margin: 0;
  }

  .settings-page__header h1 {
    font-size: clamp(1.5rem, 4vw, 2rem);
  }

  .settings-page__header p,
  .settings-card > div p {
    color: color-mix(in oklab, var(--color-base-content) 68%, transparent);
    font-size: 0.9rem;
    line-height: 1.5;
  }

  .settings-card {
    display: grid;
    gap: 1rem;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 18%, transparent);
    border-radius: var(--radius-box);
    background: var(--color-base-100);
    padding: 1.5rem;
    box-shadow: 0 0.75rem 2rem rgb(0 0 0 / 0.1);
  }

  .settings-card h2 {
    font-size: 1.15rem;
  }

  :global(.settings-form) {
    display: grid;
    gap: 0.85rem;
  }

  .settings-form__field {
    display: grid;
    gap: 0.4rem;
  }

  .settings-form__field input {
    box-sizing: border-box;
    inline-size: 100%;
    min-block-size: 3rem;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 28%, transparent);
    border-radius: var(--radius-field);
    background: var(--color-base-200);
    padding-inline: 0.9rem;
    color: var(--color-base-content);
    font: inherit;
    font-size: 1rem;
  }

  .settings-form__field input[aria-invalid="true"] {
    border-color: var(--color-error);
  }

  .settings-form__error {
    margin: 0;
    color: var(--color-error);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  :global(.settings-form button) {
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

  :global(.settings-form button:disabled) {
    cursor: wait;
    opacity: 0.68;
  }

  .settings-page__sr-only {
    position: absolute;
    inline-size: 1px;
    block-size: 1px;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
  }

  :where(button, input):focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (max-width: 34rem) {
    .settings-page {
      padding: 1rem 0.5rem;
    }

    .settings-card {
      padding: 1rem;
    }
  }
</style>
