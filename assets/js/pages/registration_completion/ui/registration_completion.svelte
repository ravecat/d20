<script lang="ts">
  import type { FormComponentSlotProps } from "@inertiajs/core";
  import { Form } from "@inertiajs/svelte";

  type FormSlotProps = FormComponentSlotProps<Record<string, string>>;

  type Submission =
    | { action: string; credential: { type: "magic_link"; token: string } }
    | { action: string; credential: { type: "server_session" } };

  type Props = InertiaProps<{
    cancelAction?: string;
    email: string;
    submission: Submission;
  }>;

  const { cancelAction, email, submission }: Props = $props();
</script>

<svelte:head>
  <title>Finish registration · D20</title>
</svelte:head>

<div class="registration-page">
  <h1>Finish creating your account</h1>
  <p class="registration-page__email">{email}</p>
  <p>Choose the permanent username other D20 players will see.</p>

  <Form class="registration-form" method="post" action={submission.action} disableWhileProcessing>
    {#snippet children({ errors, processing }: FormSlotProps)}
      {#if submission.credential.type === "magic_link"}
        <input type="hidden" name="_action" value="confirmed" />
        <input type="hidden" name="user[token]" value={submission.credential.token} />
      {/if}

      <div class="registration-form__field">
        <label for="registration-username">Username</label>
        <p id="registration-username-hint" class="registration-form__hint">
          Use 3-32 letters, numbers, underscores, or hyphens. Start and end with a letter or number.
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
          <p id="registration-username-error" class="registration-form__error" role="alert">
            {errors.username}
          </p>
        {/if}
      </div>

      <label class="registration-form__remember">
        <input type="checkbox" name="user[remember_me]" value="true" />
        <span>Keep me signed in</span>
      </label>

      <button type="submit" disabled={processing}>
        {processing ? "Finishing registration..." : "Finish registration"}
      </button>
    {/snippet}
  </Form>

  <p class="registration-page__tip">You can add a password later from account settings.</p>

  {#if cancelAction}
    <Form method="post" action={cancelAction} disableWhileProcessing>
      {#snippet children({ processing }: FormSlotProps)}
        <button class="registration-page__cancel" type="submit" disabled={processing}>
          {processing ? "Cancelling..." : "Choose another registration method"}
        </button>
      {/snippet}
    </Form>
  {/if}
</div>

<style>
  .registration-page {
    display: grid;
    box-sizing: border-box;
    inline-size: 100%;
    max-inline-size: 46.25rem;
    min-block-size: 100%;
    margin-inline: auto;
    padding: 2rem 1rem 3rem;
    align-content: start;
    gap: 1rem;
    color: var(--color-base-content);
  }

  .registration-page h1,
  .registration-page p {
    margin: 0;
  }

  .registration-page h1 {
    font-size: clamp(1.35rem, 4vw, 1.85rem);
  }

  .registration-page__email {
    overflow-wrap: anywhere;
    color: var(--color-primary);
    font-weight: 700;
  }

  :global(.registration-form) {
    display: grid;
    gap: 1rem;
  }

  .registration-form__field {
    display: grid;
    gap: 0.4rem;
  }

  .registration-form__field label {
    font-weight: 700;
  }

  .registration-form__hint,
  .registration-page__tip {
    color: color-mix(in oklab, var(--color-base-content) 72%, transparent);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  .registration-form__field input {
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

  .registration-form__field input[aria-invalid="true"] {
    border-color: var(--color-error);
  }

  .registration-form__remember {
    display: inline-flex;
    inline-size: fit-content;
    align-items: center;
    gap: 0.55rem;
    font-size: 0.85rem;
    cursor: pointer;
  }

  .registration-form__remember input {
    inline-size: 1rem;
    block-size: 1rem;
    margin: 0;
  }

  :global(.registration-form > button) {
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

  :global(.registration-form > button:disabled),
  .registration-page__cancel:disabled {
    cursor: wait;
    opacity: 0.68;
  }

  .registration-form__error {
    margin: 0;
    color: var(--color-error);
    font-size: 0.8rem;
    line-height: 1.45;
  }

  .registration-page__cancel {
    border: 0;
    background: transparent;
    padding: 0;
    color: var(--color-primary);
    font: inherit;
    font-weight: 700;
    cursor: pointer;
  }

  :where(button, input):focus-visible {
    outline: 0.1875rem solid var(--color-primary);
    outline-offset: 0.1875rem;
  }

  @media (max-width: 34rem) {
    .registration-page {
      padding-block: 1rem 2rem;
    }
  }
</style>
