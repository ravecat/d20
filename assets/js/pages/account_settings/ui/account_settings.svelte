<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";
  import appleIconSvg from "~/shared/icons/apple.svg?raw";
  import discordIconSvg from "~/shared/icons/discord.svg?raw";
  import googleIconSvg from "~/shared/icons/google.svg?raw";

  const providerIcons = {
    apple: appleIconSvg,
    discord: discordIconSvg,
    google: googleIconSvg,
  } as const;

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;
  type ProviderId = keyof typeof providerIcons;

  type Provider = {
    available: boolean;
    href: string;
    id: ProviderId;
    linked: boolean;
    name: string;
  };

  type Props = InertiaProps<{
    email: string;
    providers: Provider[];
    username: string;
  }>;

  const { email, providers, username }: Props = $props();

  const availableProviders = $derived(providers.filter(({ available }) => available));
</script>

<svelte:head>
  <title>Account settings · D20</title>
</svelte:head>

<div class="settings-page">
  <header class="settings-page__header">
    <h1>Account settings</h1>
    <p>Manage the username, email address, and password used by your D20 account.</p>
  </header>

  {#if availableProviders.length > 0}
    <section class="settings-card settings-card--providers" aria-labelledby="sign-in-methods-title">
      <div>
        <h2 id="sign-in-methods-title">Sign-in methods</h2>
        <p>Choose how you securely access your D20 account.</p>
      </div>

      <!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
      <ul class="settings-providers">
        {#each availableProviders as provider (provider.id)}
          <li class="settings-provider">
            <span class="settings-provider__identity">
              <span class="settings-provider__icon" aria-hidden="true">
                {@html providerIcons[provider.id]}
              </span>
              <span class="settings-provider__name">{provider.name}</span>
            </span>

            {#if provider.linked}
              <span class="settings-provider__state settings-provider__linked">Linked</span>
            {:else}
              <a
                class="settings-provider__state settings-provider__action"
                href={provider.href}
                aria-label={`Link ${provider.name}`}>Link</a
              >
            {/if}
          </li>
        {/each}
      </ul>
      <!-- eslint-enable svelte/no-at-html-tags -->
    </section>
  {/if}

  <section class="settings-card" aria-labelledby="username-settings-title">
    <div>
      <h2 id="username-settings-title">Username</h2>
      <p>Your username identifies you to other D20 players.</p>
    </div>

    <p class="settings-card__username">{username}</p>
  </section>

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
    --settings-control-block-size: 2.5rem;

    display: grid;
    box-sizing: border-box;
    inline-size: 100%;
    min-block-size: 100%;
    margin-inline: auto;
    padding: 2rem 1rem;
    gap: 1.25rem;
    grid-template-columns: minmax(0, 1fr);
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
    min-inline-size: 0;
    align-content: start;
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

  .settings-card__username {
    overflow-wrap: anywhere;
    color: var(--color-primary);
    font-size: 1.1rem;
    font-weight: 700;
  }

  .settings-providers {
    display: grid;
    inline-size: fit-content;
    max-inline-size: 100%;
    margin: 0;
    padding: 0;
    gap: 0.75rem;
    grid-template-columns: repeat(auto-fit, minmax(min(100%, 13rem), 1fr));
    list-style: none;
  }

  .settings-provider {
    display: grid;
    inline-size: 20rem;
    min-inline-size: 0;
    max-inline-size: 100%;
    block-size: var(--settings-control-block-size);
    align-items: stretch;
    gap: 0.5rem;
    grid-template-columns: minmax(0, 1fr) 4.75rem;
  }

  .settings-provider__identity {
    display: inline-flex;
    box-sizing: border-box;
    min-inline-size: 0;
    block-size: 100%;
    align-items: center;
    gap: 0.65rem;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 16%, transparent);
    border-radius: var(--radius-field);
    background: var(--color-base-200);
    padding-inline: 0.75rem;
  }

  .settings-provider__icon {
    display: inline-flex;
    inline-size: 1.25rem;
    block-size: 1.25rem;
    flex: none;
  }

  .settings-provider__name {
    overflow-wrap: anywhere;
    font-weight: 700;
  }

  .settings-provider__state {
    display: grid;
    box-sizing: border-box;
    inline-size: 4.75rem;
    block-size: 100%;
    place-items: center;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 16%, transparent);
    border-radius: var(--radius-field);
    background: var(--color-base-200);
    font-size: 0.85rem;
    font-weight: 700;
  }

  .settings-provider__linked {
    color: color-mix(in oklab, var(--color-base-content) 58%, transparent);
  }

  .settings-provider__action {
    border-color: color-mix(in oklab, var(--color-primary) 72%, transparent);
    background: color-mix(in oklab, var(--color-primary) 12%, var(--color-base-200));
    color: var(--color-base-content);
    text-decoration: none;
    cursor: pointer;
  }

  .settings-provider__action:hover {
    background: color-mix(in oklab, var(--color-primary) 22%, var(--color-base-200));
  }

  :global(.settings-form) {
    display: grid;
    gap: 0.85rem;
  }

  .settings-form__field {
    display: grid;
    gap: 0.4rem;
  }

  .settings-form__field > label {
    font-weight: 700;
  }

  .settings-form__field input {
    box-sizing: border-box;
    inline-size: 100%;
    block-size: var(--settings-control-block-size);
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
    box-sizing: border-box;
    block-size: var(--settings-control-block-size);
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

  :where(a, button, input):focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (min-width: 48rem) {
    .settings-page {
      grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .settings-page__header,
    .settings-card--providers {
      grid-column: 1 / -1;
    }
  }

  @media (min-width: 64rem) {
    .settings-page {
      grid-template-columns: repeat(3, minmax(0, 1fr));
    }
  }

  @media (max-width: 34rem) {
    .settings-page {
      padding: 1rem 0.5rem;
    }

    .settings-card {
      padding: 1rem;
    }

    .settings-providers {
      inline-size: min(100%, 20rem);
      grid-template-columns: minmax(0, 1fr);
    }
  }
</style>
