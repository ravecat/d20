<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Props = InertiaProps<{
    discord: {
      available: boolean;
      linked: boolean;
    };
    email: string;
    google: {
      available: boolean;
      linked: boolean;
    };
    username: string | null;
  }>;

  const { discord, email, google, username }: Props = $props();
</script>

<svelte:head>
  <title>Account settings · D20</title>
</svelte:head>

<div class="settings-page">
  <header class="settings-page__header">
    <h1>Account settings</h1>
    <p>Manage the username, email address, and password used by your D20 account.</p>
  </header>

  <section class="settings-card" aria-labelledby="sign-in-methods-title">
    <div>
      <h2 id="sign-in-methods-title">Sign-in methods</h2>
      <p>Choose how you securely access your D20 account.</p>
    </div>

    <div class="settings-method">
      <div>
        <p class="settings-method__name">Google</p>
        <p class="settings-method__status">
          {google.linked
            ? google.available
              ? "Linked"
              : "Linked - unavailable"
            : google.available
              ? "Not linked"
              : "Unavailable"}
        </p>
      </div>

      {#if !google.linked && google.available}
        <a class="settings-method__action" href="/users/settings/auth/google">Link Google</a>
      {:else if !google.linked}
        <button class="settings-method__action" type="button" disabled>Link Google</button>
      {/if}
    </div>

    <div class="settings-method">
      <div>
        <p class="settings-method__name">Discord</p>
        <p class="settings-method__status">
          {discord.linked
            ? discord.available
              ? "Linked"
              : "Linked - unavailable"
            : discord.available
              ? "Not linked"
              : "Unavailable"}
        </p>
      </div>

      {#if !discord.linked && discord.available}
        <a class="settings-method__action" href="/users/settings/auth/discord">Link Discord</a>
      {:else if !discord.linked}
        <button class="settings-method__action" type="button" disabled>Link Discord</button>
      {/if}
    </div>
  </section>

  <section class="settings-card" aria-labelledby="username-settings-title">
    <div>
      <h2 id="username-settings-title">Username</h2>
      {#if username}
        <p>Your username identifies you to other D20 players and cannot be changed.</p>
      {:else}
        <p>Choose the permanent username other D20 players will see.</p>
      {/if}
    </div>

    {#if username}
      <p class="settings-card__username">{username}</p>
    {:else}
      <Form class="settings-form" method="put" action="/users/settings" disableWhileProcessing>
        {#snippet children({ errors, processing }: FormSlotProps)}
          <input type="hidden" name="action" value="claim_username" />

          <div class="settings-form__field">
            <label for="settings-username">Username</label>
            <p id="settings-username-hint" class="settings-form__hint">
              Use 3-32 letters, numbers, underscores, or hyphens. Start and end with a letter or
              number.
            </p>
            <input
              id="settings-username"
              name="user[username]"
              type="text"
              autocomplete="username"
              autocapitalize="none"
              spellcheck="false"
              minlength="3"
              maxlength="32"
              pattern="[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?"
              enterkeyhint="done"
              required
              oninput={(event) => {
                event.currentTarget.value = event.currentTarget.value.trim().toLowerCase();
              }}
              aria-invalid={errors.username ? "true" : undefined}
              aria-describedby={errors.username
                ? "settings-username-hint settings-username-error"
                : "settings-username-hint"}
            />
            {#if errors.username}
              <p id="settings-username-error" class="settings-form__error" role="alert">
                {errors.username}
              </p>
            {/if}
          </div>

          <button type="submit" disabled={processing}>
            {processing ? "Saving username..." : "Save username"}
          </button>
        {/snippet}
      </Form>
    {/if}
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

  .settings-card__username {
    overflow-wrap: anywhere;
    color: var(--color-primary);
    font-size: 1.1rem;
    font-weight: 700;
  }

  .settings-method {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .settings-method > div {
    display: grid;
    gap: 0.2rem;
  }

  .settings-method__name {
    font-weight: 700;
  }

  .settings-method__status {
    color: color-mix(in oklab, var(--color-base-content) 68%, transparent);
    font-size: 0.85rem;
  }

  .settings-method__action {
    display: inline-grid;
    min-block-size: 2.75rem;
    place-items: center;
    border: 0;
    border-radius: var(--radius-field);
    background: var(--color-primary);
    padding-inline: 1rem;
    color: var(--color-primary-content);
    font: inherit;
    font-weight: 700;
    text-decoration: none;
    cursor: pointer;
  }

  .settings-method__action:disabled {
    background: var(--color-base-200);
    color: color-mix(in oklab, var(--color-base-content) 55%, transparent);
    cursor: not-allowed;
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

  .settings-form__hint {
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.8rem;
    line-height: 1.45;
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

  :where(a, button, input):focus-visible {
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
