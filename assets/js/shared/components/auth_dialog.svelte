<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form, usePage } from "@inertiajs/svelte";
  import { useSelector } from "@xstate/store-svelte";
  import { onMount, tick } from "svelte";
  import appleIconSvg from "~/shared/icons/apple.svg?raw";
  import discordIconSvg from "~/shared/icons/discord.svg?raw";
  import facebookIconSvg from "~/shared/icons/facebook.svg?raw";
  import googleIconSvg from "~/shared/icons/google.svg?raw";
  import InlineNotification from "./inline_notification.svelte";
  import { auth } from "~/shared/stores/auth";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;
  type Mode = Parameters<typeof auth.trigger.switchMode>[0]["mode"];

  const page = usePage();
  const authState = useSelector(auth, ({ context }) => context);

  let dialog = $state<HTMLDialogElement>();
  let activeEmailInput = $state<HTMLInputElement>();
  let passwordVisible = $state(false);

  onMount(() => {
    dialog?.showModal();
  });

  async function switchMode(nextMode: Mode) {
    passwordVisible = false;
    auth.trigger.switchMode({ mode: nextMode });
    await tick();
    activeEmailInput?.focus();
  }

  const reauthenticate = $derived($authState.prompt?.reauthenticate ?? false);
  const providerIntent = $derived(reauthenticate ? "&intent=reauthenticate" : "");
  const googleAuthUrl = $derived(
    `/auth/google?return_to=${encodeURIComponent($authState.prompt?.returnTo ?? page.url)}${providerIntent}`,
  );
  const appleAuthUrl = $derived(
    `/auth/apple?return_to=${encodeURIComponent($authState.prompt?.returnTo ?? page.url)}${providerIntent}`,
  );
  const discordAuthUrl = $derived(
    `/auth/discord?return_to=${encodeURIComponent($authState.prompt?.returnTo ?? page.url)}${providerIntent}`,
  );
  const facebookAuthUrl = $derived(
    `/auth/facebook?return_to=${encodeURIComponent($authState.prompt?.returnTo ?? page.url)}${providerIntent}`,
  );
  const hasAvailableProvider = $derived(
    Object.values(page.props.auth.providers).some(({ available }) => available),
  );
</script>

<!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
{#snippet provider(
  action: "Sign up" | "Sign in",
  name: string,
  iconSvg: string,
  available: boolean,
  authUrl: string,
)}
  {#if available}
    <a class="auth-providers__button" href={authUrl}>
      <span class="auth-providers__identity">
        <span class="provider-icon" aria-hidden="true">{@html iconSvg}</span>
        <span>{action} with {name}</span>
      </span>
    </a>
  {/if}
{/snippet}
<!-- eslint-enable svelte/no-at-html-tags -->

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
        onclick={() => dialog?.close()}
      >
        <svg aria-hidden="true" focusable="false" viewBox="0 0 24 24">
          <path d="M5 5l14 14M19 5 5 19" />
        </svg>
      </button>
    </header>

    <div class="auth-panel__content">
      <p class="auth-panel__description">
        {#if $authState.prompt?.reauthenticate}
          Sign in again to continue to the protected account action.
        {:else}
          Save your game history and achievements. Share game sessions across devices and watch
          replays of completed games.
        {/if}
      </p>

      {#if $authState.prompt?.message}
        <InlineNotification kind={$authState.prompt.kind}>
          {$authState.prompt.message}
        </InlineNotification>
      {/if}

      {#if $authState.mode === "register"}
        {#if $authState.registrationCompleted}
          <InlineNotification kind="info">
            Check your email. Open the confirmation link to finish creating your account and log in.
            {#if page.props.auth.local}
              Open the <a href="/dev/mailbox">local mailbox</a>.
            {/if}
          </InlineNotification>
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
                <!-- svelte-ignore a11y_autofocus (Native modal entry focus is intentional.) -->
                <input
                  bind:this={activeEmailInput}
                  autofocus
                  value={$authState.email}
                  oninput={(event) =>
                    auth.trigger.updateEmail({
                      email: event.currentTarget.value,
                    })}
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
                <InlineNotification kind="error">
                  <div class="auth-form__failure">
                    <p>{errors.delivery}</p>
                    <button type="button" onclick={() => switchMode("login")}>
                      Log in to request another link
                    </button>
                  </div>
                </InlineNotification>
              {/if}
            {/snippet}
          </Form>
        {/if}

        {#if hasAvailableProvider}
          <div class="auth-panel__separator" aria-hidden="true">
            <span>or</span>
          </div>

          <!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
          <div class="auth-providers" aria-label="Other registration methods">
            {@render provider(
              "Sign up",
              "Google",
              googleIconSvg,
              page.props.auth.providers.google.available,
              googleAuthUrl,
            )}
            {@render provider(
              "Sign up",
              "Apple",
              appleIconSvg,
              page.props.auth.providers.apple.available,
              appleAuthUrl,
            )}
            {@render provider(
              "Sign up",
              "Discord",
              discordIconSvg,
              page.props.auth.providers.discord.available,
              discordAuthUrl,
            )}
            {@render provider(
              "Sign up",
              "Facebook",
              facebookIconSvg,
              page.props.auth.providers.facebook.available,
              facebookAuthUrl,
            )}
          </div>
          <!-- eslint-enable svelte/no-at-html-tags -->
        {/if}

        <p class="auth-panel__mode-switch">
          Already have an account?
          <button type="button" onclick={() => switchMode("login")}>Log in</button>
        </p>
      {:else}
        <section class="auth-method" aria-label="Magic link login">
          {#if $authState.magicLinkCompleted}
            <InlineNotification kind="info">
              Check your email. If your email is in our system, a login link will arrive shortly.
              {#if page.props.auth.local}
                Open the <a href="/dev/mailbox">local mailbox</a>.
              {/if}
            </InlineNotification>
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
                  <!-- svelte-ignore a11y_autofocus (Native modal entry focus is intentional.) -->
                  <input
                    bind:this={activeEmailInput}
                    autofocus
                    value={$authState.email}
                    oninput={(event) =>
                      auth.trigger.updateEmail({
                        email: event.currentTarget.value,
                      })}
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

        <div class="auth-panel__separator" aria-hidden="true">
          <span>or</span>
        </div>

        <section class="auth-method" aria-label="Password login">
          <Form class="auth-form" method="post" action="/users/log-in" disableWhileProcessing>
            {#snippet children({ errors, processing }: FormSlotProps)}
              <input
                type="hidden"
                name="return_to"
                value={$authState.prompt?.returnTo ?? page.url}
              />
              <input type="hidden" name="response_to" value={page.url} />

              <div class="auth-form__field">
                <label class="auth-panel__sr-only" for="auth-dialog-password-login-identifier">
                  Username or email
                </label>
                <input
                  value={$authState.identifier}
                  oninput={(event) =>
                    auth.trigger.updateIdentifier({
                      identifier: event.currentTarget.value,
                    })}
                  id="auth-dialog-password-login-identifier"
                  name="user[identifier]"
                  type="text"
                  placeholder="Username or email"
                  autocomplete="username"
                  spellcheck="false"
                  readonly={$authState.prompt?.reauthenticate ?? false}
                  required
                  aria-invalid={errors.credentials ? "true" : undefined}
                  aria-describedby={errors.credentials
                    ? "auth-dialog-password-login-error"
                    : undefined}
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
                    type={passwordVisible ? "text" : "password"}
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
                    aria-label={passwordVisible ? "Hide password" : "Show password"}
                    aria-pressed={passwordVisible}
                    onclick={() => (passwordVisible = !passwordVisible)}
                  >
                    {passwordVisible ? "Hide" : "Show"}
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

        {#if hasAvailableProvider}
          <div class="auth-panel__separator" aria-hidden="true">
            <span>or</span>
          </div>

          <!-- eslint-disable svelte/no-at-html-tags -- Provider icons are trusted build-time SVG assets. -->
          <div class="auth-providers" aria-label="Other login methods">
            {@render provider(
              "Sign in",
              "Google",
              googleIconSvg,
              page.props.auth.providers.google.available,
              googleAuthUrl,
            )}
            {@render provider(
              "Sign in",
              "Apple",
              appleIconSvg,
              page.props.auth.providers.apple.available,
              appleAuthUrl,
            )}
            {@render provider(
              "Sign in",
              "Discord",
              discordIconSvg,
              page.props.auth.providers.discord.available,
              discordAuthUrl,
            )}
            {@render provider(
              "Sign in",
              "Facebook",
              facebookIconSvg,
              page.props.auth.providers.facebook.available,
              facebookAuthUrl,
            )}
          </div>
          <!-- eslint-enable svelte/no-at-html-tags -->
        {/if}

        {#if !reauthenticate}
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
    padding: 0;
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
    gap: 0.625rem;
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
    align-items: flex-start;
    justify-content: space-between;
    gap: 1rem;
    padding-block-start: 1.5rem;
    padding-inline: 1.5rem;
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

  .auth-panel__description {
    margin: 0;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.9rem;
    line-height: 1.5;
  }

  .auth-panel__content {
    display: flex;
    flex: 0 1 auto;
    flex-direction: column;
    gap: 0.625rem;
    min-block-size: 0;
    overflow-y: auto;
    overscroll-behavior: contain;
    padding-block-end: 1.5rem;
    padding-inline: 1.5rem;
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

  .auth-form__error {
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
    gap: 0.625rem;
    margin-block: 0.25rem;
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
    color: var(--color-base-content);
    font: inherit;
    font-size: 0.85rem;
    text-align: start;
    text-decoration: none;
    cursor: pointer;
  }

  .auth-providers__button:hover {
    border-color: color-mix(in oklab, var(--color-primary) 55%, transparent);
    background: color-mix(in oklab, var(--color-primary) 10%, var(--color-base-200));
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

  .auth-panel__mode-switch {
    margin: 0.375rem 0 0;
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.8rem;
    text-align: center;
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
      inset-block-start: max(0.5rem, env(safe-area-inset-top, 0px));
      inset-inline-end: max(0.5rem, env(safe-area-inset-right, 0px));
      inset-block-end: max(0.5rem, env(safe-area-inset-bottom, 0px));
      inset-inline-start: max(0.5rem, env(safe-area-inset-left, 0px));
      inline-size: auto;
      block-size: auto;
      max-block-size: none;
      margin: 0;
    }

    .auth-panel__title-row {
      padding-block-start: 1rem;
      padding-inline: 1rem;
    }

    .auth-panel__content {
      padding-block-end: 1rem;
      padding-inline: 1rem;
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
