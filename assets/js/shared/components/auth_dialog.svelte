<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form, usePage } from "@inertiajs/svelte";
  import { useSelector } from "@xstate/store-svelte";
  import { tick } from "svelte";
  import appleIconSvg from "~/shared/icons/apple.svg?raw";
  import discordIconSvg from "~/shared/icons/discord.svg?raw";
  import facebookIconSvg from "~/shared/icons/facebook.svg?raw";
  import googleIconSvg from "~/shared/icons/google.svg?raw";
  import { auth } from "~/shared/stores";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;
  type Mode = Parameters<typeof auth.trigger.switchMode>[0]["mode"];

  const page = usePage();
  const authState = useSelector(auth, ({ context }) => context);

  let dialog = $state<HTMLDialogElement>();
  let activeEmailInput = $state<HTMLInputElement>();

  $effect(() => {
    if (!dialog) return;

    if ($authState.open && !dialog.open) {
      dialog.showModal();
      void focusActiveEmail();
    } else if (!$authState.open && dialog.open) {
      dialog.close();
    }
  });

  async function switchMode(nextMode: Mode) {
    if (nextMode === $authState.mode) return;

    auth.trigger.switchMode({ mode: nextMode });

    await focusActiveEmail();
  }

  async function focusActiveEmail() {
    await tick();
    activeEmailInput?.focus();
  }
</script>

<dialog
  bind:this={dialog}
  class="auth-dialog"
  aria-labelledby="auth-dialog-title"
  closedby="any"
  onclose={() => auth.trigger.close()}
>
  <section class="auth-panel">
    <header class="auth-panel__title-row">
      <h1 id="auth-dialog-title" class="auth-panel__title">
        {#if $authState.prompt?.reauthenticate}
          Confirm it is you
        {:else if $authState.mode === "register"}
          Create your free account
        {:else}
          Log in
        {/if}
      </h1>

      <button
        class="auth-panel__close"
        type="button"
        aria-label="Close"
        onclick={() => auth.trigger.close()}
      >
        <svg aria-hidden="true" focusable="false" viewBox="0 0 24 24">
          <path d="M5 5l14 14M19 5 5 19" />
        </svg>
      </button>
    </header>

    <p class="auth-panel__description">
      {#if $authState.prompt?.reauthenticate}
        Sign in again to continue to the protected account action.
      {:else}
        Save your game history and achievements. Continue game sessions across devices and watch
        replays of completed games.
      {/if}
    </p>

    {#if $authState.prompt?.message}
      <aside class="auth-panel__notice" role="status">{$authState.prompt.message}</aside>
    {/if}

    {#if page.props.auth.local}
      <aside class="auth-panel__notice" role="status">
        Sent development emails are available in the <a href="/dev/mailbox">local mailbox</a>.
      </aside>
    {/if}

    <div class="auth-panel__content">
      {#if $authState.mode === "register"}
        {#if $authState.registrationCompleted}
          <div class="auth-panel__result" role="status" aria-live="polite">
            <p class="auth-panel__result-title">Check your email</p>
            <p>Open the confirmation link to finish creating your account and log in.</p>
          </div>
        {:else}
          <Form
            class="auth-form"
            method="post"
            action="/users/register"
            disableWhileProcessing
            onSuccess={() => auth.trigger.registrationSucceeded()}
          >
            {#snippet children({ errors, processing }: FormSlotProps)}
              <input
                type="hidden"
                name="return_to"
                value={$authState.prompt?.returnTo ?? page.url}
              />
              <input type="hidden" name="response_to" value={page.url} />

              <div class="auth-form__field">
                <label class="auth-panel__sr-only" for="auth-dialog-registration-email">
                  Email address
                </label>
                <input
                  bind:this={activeEmailInput}
                  value={$authState.email}
                  oninput={(event) =>
                    auth.trigger.updateEmail({ email: event.currentTarget.value })}
                  id="auth-dialog-registration-email"
                  name="user[email]"
                  type="email"
                  inputmode="email"
                  placeholder="Email address"
                  autocomplete="username"
                  enterkeyhint="send"
                  spellcheck="false"
                  required
                  aria-invalid={errors.email ? "true" : undefined}
                  aria-describedby={errors.email
                    ? "auth-dialog-registration-email-error"
                    : undefined}
                />
                {#if errors.email}
                  <p
                    id="auth-dialog-registration-email-error"
                    class="auth-form__error"
                    role="alert"
                  >
                    {errors.email}
                  </p>
                {/if}
              </div>

              <button class="auth-form__submit" type="submit" disabled={processing}>
                {processing ? "Creating account..." : "Create account"}
              </button>

              {#if errors.delivery}
                <div class="auth-form__failure" role="alert">
                  <p>{errors.delivery}</p>
                  <button type="button" onclick={() => switchMode("login")}>
                    Log in to request another link
                  </button>
                </div>
              {/if}
            {/snippet}
          </Form>
        {/if}

        <div class="auth-panel__separator" aria-hidden="true"><span>or</span></div>

        <!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
        <div class="auth-providers" aria-label="Other registration methods">
          <button class="auth-providers__button" type="button" disabled>
            <span class="auth-providers__identity">
              <span class="provider-icon" aria-hidden="true">{@html googleIconSvg}</span>
              <span>Register with Google</span>
            </span>
            <span class="auth-providers__status">Coming soon</span>
          </button>

          <button class="auth-providers__button" type="button" disabled>
            <span class="auth-providers__identity">
              <span class="provider-icon" aria-hidden="true">{@html facebookIconSvg}</span>
              <span>Register with Facebook</span>
            </span>
            <span class="auth-providers__status">Coming soon</span>
          </button>

          <button class="auth-providers__button" type="button" disabled>
            <span class="auth-providers__identity">
              <span class="provider-icon" aria-hidden="true">{@html appleIconSvg}</span>
              <span>Register with Apple</span>
            </span>
            <span class="auth-providers__status">Coming soon</span>
          </button>

          <button class="auth-providers__button" type="button" disabled>
            <span class="auth-providers__identity">
              <span class="provider-icon" aria-hidden="true">{@html discordIconSvg}</span>
              <span>Register with Discord</span>
            </span>
            <span class="auth-providers__status">Coming soon</span>
          </button>
        </div>
        <!-- eslint-enable svelte/no-at-html-tags -->

        <p class="auth-panel__mode-switch">
          Already have an account?
          <button type="button" onclick={() => switchMode("login")}>Log in</button>
        </p>
      {:else}
        <section class="auth-method" aria-label="Magic link login">
          {#if $authState.magicLinkCompleted}
            <div class="auth-panel__result" role="status" aria-live="polite">
              <p class="auth-panel__result-title">Check your email</p>
              <p>If your email is in our system, a login link will arrive shortly.</p>
            </div>
          {:else}
            <Form
              class="auth-form"
              method="post"
              action="/users/log-in"
              disableWhileProcessing
              onSuccess={() => auth.trigger.magicLinkSucceeded()}
            >
              {#snippet children({ errors, processing }: FormSlotProps)}
                <input
                  type="hidden"
                  name="return_to"
                  value={$authState.prompt?.returnTo ?? page.url}
                />
                <input type="hidden" name="response_to" value={page.url} />

                <div class="auth-form__field">
                  <label class="auth-panel__sr-only" for="auth-dialog-magic-link-email">
                    Email address
                  </label>
                  <input
                    bind:this={activeEmailInput}
                    value={$authState.email}
                    oninput={(event) =>
                      auth.trigger.updateEmail({ email: event.currentTarget.value })}
                    id="auth-dialog-magic-link-email"
                    name="user[email]"
                    type="email"
                    inputmode="email"
                    placeholder="Email address"
                    autocomplete="username"
                    enterkeyhint="send"
                    spellcheck="false"
                    readonly={$authState.prompt?.reauthenticate ?? false}
                    required
                    aria-invalid={errors.email ? "true" : undefined}
                    aria-describedby={errors.email
                      ? "auth-dialog-magic-link-email-error"
                      : undefined}
                  />
                  {#if errors.email}
                    <p
                      id="auth-dialog-magic-link-email-error"
                      class="auth-form__error"
                      role="alert"
                    >
                      {errors.email}
                    </p>
                  {/if}
                </div>

                <button class="auth-form__submit" type="submit" disabled={processing}>
                  {processing ? "Sending link..." : "Email me a login link"}
                </button>
              {/snippet}
            </Form>
          {/if}
        </section>

        <div class="auth-panel__separator" aria-hidden="true"><span>or</span></div>

        <section class="auth-method" aria-label="Email and password login">
          <Form class="auth-form" method="post" action="/users/log-in" disableWhileProcessing>
            {#snippet children({ errors, processing }: FormSlotProps)}
              <input
                type="hidden"
                name="return_to"
                value={$authState.prompt?.returnTo ?? page.url}
              />
              <input type="hidden" name="response_to" value={page.url} />

              <div class="auth-form__field">
                <label class="auth-panel__sr-only" for="auth-dialog-password-login-email">
                  Email address
                </label>
                <input
                  value={$authState.email}
                  oninput={(event) =>
                    auth.trigger.updateEmail({ email: event.currentTarget.value })}
                  id="auth-dialog-password-login-email"
                  name="user[email]"
                  type="email"
                  inputmode="email"
                  placeholder="Email address"
                  autocomplete="username"
                  spellcheck="false"
                  readonly={$authState.prompt?.reauthenticate ?? false}
                  required
                />
              </div>

              <div class="auth-form__field">
                <label class="auth-panel__sr-only" for="auth-dialog-password-login-password">
                  Password
                </label>
                <div class="auth-form__password">
                  <input
                    id="auth-dialog-password-login-password"
                    name="user[password]"
                    type={$authState.passwordVisible ? "text" : "password"}
                    placeholder="Password"
                    autocomplete="current-password"
                    required
                    aria-invalid={errors.credentials ? "true" : undefined}
                    aria-describedby={errors.credentials
                      ? "auth-dialog-password-login-error"
                      : undefined}
                  />
                  <button
                    type="button"
                    aria-label={$authState.passwordVisible ? "Hide password" : "Show password"}
                    aria-pressed={$authState.passwordVisible}
                    onclick={() => auth.trigger.togglePassword()}
                  >
                    {$authState.passwordVisible ? "Hide" : "Show"}
                  </button>
                </div>
                {#if errors.credentials}
                  <p id="auth-dialog-password-login-error" class="auth-form__error" role="alert">
                    {errors.credentials}
                  </p>
                {/if}
              </div>

              {#if !$authState.prompt?.reauthenticate}
                <label class="auth-form__remember">
                  <input type="checkbox" name="user[remember_me]" value="true" />
                  <span>Keep me signed in</span>
                </label>
              {/if}

              <button class="auth-form__submit" type="submit" disabled={processing}>
                {processing
                  ? "Logging in..."
                  : $authState.prompt?.reauthenticate
                    ? "Confirm and continue"
                    : "Log in"}
              </button>
            {/snippet}
          </Form>
        </section>

        {#if !$authState.prompt?.reauthenticate}
          <div class="auth-panel__separator" aria-hidden="true"><span>or</span></div>

          <!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
          <div class="auth-providers" aria-label="Other login methods">
            <button class="auth-providers__button" type="button" disabled>
              <span class="auth-providers__identity">
                <span class="provider-icon" aria-hidden="true">{@html googleIconSvg}</span>
                <span>Log in with Google</span>
              </span>
              <span class="auth-providers__status">Coming soon</span>
            </button>

            <button class="auth-providers__button" type="button" disabled>
              <span class="auth-providers__identity">
                <span class="provider-icon" aria-hidden="true">{@html facebookIconSvg}</span>
                <span>Log in with Facebook</span>
              </span>
              <span class="auth-providers__status">Coming soon</span>
            </button>

            <button class="auth-providers__button" type="button" disabled>
              <span class="auth-providers__identity">
                <span class="provider-icon" aria-hidden="true">{@html appleIconSvg}</span>
                <span>Log in with Apple</span>
              </span>
              <span class="auth-providers__status">Coming soon</span>
            </button>

            <button class="auth-providers__button" type="button" disabled>
              <span class="auth-providers__identity">
                <span class="provider-icon" aria-hidden="true">{@html discordIconSvg}</span>
                <span>Log in with Discord</span>
              </span>
              <span class="auth-providers__status">Coming soon</span>
            </button>
          </div>
          <!-- eslint-enable svelte/no-at-html-tags -->

          <p class="auth-panel__mode-switch">
            New to D20?
            <button type="button" onclick={() => switchMode("register")}>Create account</button>
          </p>
        {/if}
      {/if}
    </div>
  </section>
</dialog>

<style>
  .auth-dialog {
    box-sizing: border-box;
    inline-size: min(calc(100% - 2rem), 34rem);
    block-size: fit-content;
    max-inline-size: none;
    max-block-size: calc(100dvh - 2rem);
    margin: auto;
    overflow: hidden;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 18%, transparent);
    border-radius: var(--radius-box);
    background: var(--color-base-100);
    padding: 1.5rem;
    color: var(--color-base-content);
    box-shadow: 0 1.5rem 5rem rgb(0 0 0 / 0.38);
  }

  .auth-dialog[open] {
    display: flex;
    flex-direction: column;
  }

  .auth-dialog::backdrop {
    background: rgb(0 0 0 / 0.68);
  }

  .auth-panel {
    display: flex;
    box-sizing: border-box;
    inline-size: 100%;
    block-size: fit-content;
    min-block-size: 0;
    max-block-size: 100%;
    flex: 0 1 auto;
    flex-direction: column;
    gap: 0.75rem;
    overflow: hidden;
    border: 0;
    border-radius: 0;
    background: transparent;
    padding: 0;
    box-shadow: none;
  }

  .auth-panel__title-row {
    display: flex;
    min-inline-size: 0;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
  }

  .auth-panel__title {
    margin: 0;
    font-size: clamp(1.35rem, 4vw, 1.85rem);
    line-height: 1.15;
  }

  .auth-panel__close {
    display: grid;
    inline-size: 1.75rem;
    block-size: 1.75rem;
    flex: none;
    place-items: center;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 22%, transparent);
    border-radius: var(--radius-field);
    background: transparent;
    padding: 0;
    color: inherit;
    cursor: pointer;
  }

  .auth-panel__close svg {
    inline-size: 1.2rem;
    block-size: 1.2rem;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-width: 2.25;
  }

  .auth-panel__description,
  .auth-panel__notice {
    margin: 0;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.9rem;
    line-height: 1.5;
  }

  .auth-panel__notice a {
    color: var(--color-primary);
    font-weight: 700;
  }

  .auth-panel__content {
    flex: 0 1 auto;
    min-block-size: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
  }

  :global(.auth-form),
  .auth-method {
    display: grid;
    gap: 0.85rem;
  }

  .auth-form__field {
    display: grid;
    gap: 0.4rem;
  }

  .auth-form__field > input,
  .auth-form__password input {
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

  .auth-form__field input[aria-invalid="true"] {
    border-color: var(--color-error);
  }

  .auth-form__password {
    position: relative;
  }

  .auth-form__password input {
    padding-inline-end: 4.5rem;
  }

  .auth-form__password button {
    position: absolute;
    inset-block: 0;
    inset-inline-end: 0.3rem;
    margin-block: auto;
    border: 0;
    background: transparent;
    padding-inline: 0.65rem;
    color: color-mix(in oklab, var(--color-base-content) 70%, transparent);
    font: inherit;
    font-size: 0.75rem;
    font-weight: 700;
    cursor: pointer;
  }

  .auth-form__remember {
    display: inline-flex;
    inline-size: fit-content;
    align-items: center;
    gap: 0.55rem;
    font-size: 0.8rem;
    cursor: pointer;
  }

  .auth-form__remember input {
    inline-size: 1rem;
    block-size: 1rem;
    margin: 0;
  }

  .auth-form__error,
  .auth-form__failure {
    margin: 0;
    color: var(--color-error);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  .auth-form__submit {
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

  .auth-form__submit:disabled {
    cursor: wait;
    opacity: 0.68;
  }

  .auth-form__failure {
    display: grid;
    gap: 0.65rem;
    border: var(--border) solid color-mix(in oklab, var(--color-error) 55%, transparent);
    border-radius: var(--radius-field);
    background: color-mix(in oklab, var(--color-error) 9%, transparent);
    padding: 0.85rem;
  }

  .auth-form__failure p {
    margin: 0;
  }

  .auth-form__failure button,
  .auth-panel__mode-switch button {
    border: 0;
    background: transparent;
    padding: 0;
    color: var(--color-primary);
    font: inherit;
    font-weight: 700;
    cursor: pointer;
  }

  .auth-form__failure button {
    justify-self: start;
  }

  .auth-panel__separator {
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    align-items: center;
    gap: 0.75rem;
    margin-block: 1rem;
    color: color-mix(in oklab, var(--color-base-content) 58%, transparent);
    font-size: 0.75rem;
    text-transform: uppercase;
  }

  .auth-panel__separator::before,
  .auth-panel__separator::after {
    block-size: var(--border);
    background: color-mix(in oklab, var(--color-base-content) 18%, transparent);
    content: "";
  }

  .auth-providers {
    display: grid;
    gap: 0.6rem;
  }

  .auth-providers__button {
    display: flex;
    min-block-size: 2.8rem;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    border: var(--border) solid color-mix(in oklab, var(--color-base-content) 16%, transparent);
    border-radius: var(--radius-field);
    background: var(--color-base-200);
    padding-inline: 0.9rem;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font: inherit;
    font-size: 0.85rem;
    text-align: start;
    cursor: not-allowed;
  }

  .auth-providers__identity {
    display: inline-flex;
    min-inline-size: 0;
    align-items: center;
    gap: 0.65rem;
  }

  .provider-icon {
    display: inline-flex;
    inline-size: 1.25rem;
    block-size: 1.25rem;
    flex: none;
  }

  .auth-providers__status {
    flex: none;
    font-size: 0.65rem;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  .auth-panel__mode-switch {
    margin: 1.1rem 0 0;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.8rem;
    text-align: center;
  }

  .auth-panel__result {
    display: grid;
    gap: 0.55rem;
    border: var(--border) solid color-mix(in oklab, var(--color-success) 58%, transparent);
    border-radius: var(--radius-field);
    background: color-mix(in oklab, var(--color-success) 10%, transparent);
    padding: 0.9rem;
    line-height: 1.45;
  }

  .auth-panel__result p {
    margin: 0;
  }

  .auth-panel__result-title {
    color: var(--color-success);
    font-weight: 800;
  }

  .auth-panel__sr-only {
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

  .auth-panel__content :where(button, input):focus-visible {
    outline-offset: -0.1875rem;
  }

  @media (max-width: 34rem) {
    .auth-dialog {
      inline-size: calc(100% - 1rem);
      max-block-size: calc(100dvh - 1rem);
      padding: 1rem;
    }

    .auth-providers__button {
      align-items: flex-start;
      flex-direction: column;
      justify-content: center;
      gap: 0.2rem;
      padding-block: 0.65rem;
    }
  }
</style>
