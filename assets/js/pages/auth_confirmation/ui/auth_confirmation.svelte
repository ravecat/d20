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
  <title>{confirmed ? "Log in" : "Finish registration"} · D20</title>
</svelte:head>

<div class="confirmation-page">
  <h1 class="confirmation-page__title">
    {confirmed ? "Log in" : "Finish creating your account"}
  </h1>
  <p class="confirmation-page__email">{email}</p>
  <p class="confirmation-page__description">
    {#if confirmed}
      Use this magic link to continue to D20.
    {:else}
      Choose the username other players will see
    {/if}
  </p>

  <Form class="confirmation-form" method="post" action="/users/log-in" disableWhileProcessing>
    {#snippet children({ errors, processing }: FormSlotProps)}
      <input type="hidden" name="user[token]" value={token} />
      {#if !confirmed}
        <input type="hidden" name="_action" value="confirmed" />

        <div class="confirmation-form__field">
          <label for="registration-username">Username</label>
          <p id="registration-username-hint" class="confirmation-form__hint">
            Use 3-32 letters, numbers, underscores, or hyphens. Start and end with a letter or
            number.
          </p>
          <!-- svelte-ignore a11y_autofocus (This is the only registration-completion field.) -->
          <input
            id="registration-username"
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
            autofocus
            oninput={(event) => {
              event.currentTarget.value = event.currentTarget.value.trim().toLowerCase();
            }}
            aria-invalid={errors.username ? "true" : undefined}
            aria-describedby={errors.username
              ? "registration-username-hint registration-username-error"
              : "registration-username-hint"}
          />
          {#if errors.username}
            <p id="registration-username-error" class="confirmation-form__error" role="alert">
              {errors.username}
            </p>
          {/if}
        </div>
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
            : "Finishing registration..."
          : confirmed
            ? "Log in"
            : "Finish registration"}
      </button>
    {/snippet}
  </Form>

  {#if !confirmed}
    <p class="confirmation-page__tip">You can add a password later from account settings.</p>
  {/if}
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
  .confirmation-page__description,
  .confirmation-page__tip {
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

  .confirmation-form__field {
    display: grid;
    gap: 0.4rem;
  }

  .confirmation-form__field label {
    font-weight: 700;
  }

  .confirmation-form__hint {
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  .confirmation-form__field input {
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

  .confirmation-form__field input[aria-invalid="true"] {
    border-color: var(--color-error);
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

  .confirmation-page__tip {
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.85rem;
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
