<script lang="ts">
  import { formDataToObject } from "@inertiajs/core";
  import { untrack } from "svelte";
  import Frame from "~components/module_frame.svelte";
  import { createSession } from "~stores/session";
  import type { AttrConfig } from "~types/game";
  import type { ModuleConnection, ModuleEntry } from "~types/module";

  interface Props {
    module: ModuleEntry;
    connection: ModuleConnection;
  }

  const { module, connection }: Props = $props();
  const session = createSession(untrack(() => connection.topic));

  const members = $derived(
    Object.entries($session.value?.members ?? {}).map(([id, member]) => {
      const name = member.display_name || "Player";

      return {
        id,
        name,
        avatar: member.avatar,
        letter: name.charAt(0).toUpperCase() || "?",
      };
    }),
  );
  const status = $derived($session.status);
  const phase = $derived($session.value?.phase);
  const attrFields = $derived(
    Object.entries($session.value?.attrs ?? {}).sort(
      ([, left], [, right]) => (left.position ?? 0) - (right.position ?? 0),
    ),
  );

  function fieldValue(attr: AttrConfig) {
    return attr.value == null ? "" : String(attr.value);
  }

  function fieldLabel(name: string, attr: AttrConfig) {
    if (attr.label) return attr.label;

    return humanize(name);
  }

  function humanize(value: string) {
    const label = value.replace(/_/g, " ");
    return label.charAt(0).toUpperCase() + label.slice(1);
  }

  function startGame(event: SubmitEvent) {
    event.preventDefault();

    if (event.currentTarget instanceof HTMLFormElement) {
      session.start(formDataToObject(new FormData(event.currentTarget)));
    }
  }

  function keepUniqueValue(event: Event) {
    if (!(event.currentTarget instanceof HTMLSelectElement)) return;

    const select = event.currentTarget;
    const group = select.dataset.uniqueGroup;
    const previousValue = select.dataset.previousValue;

    if (!group || !previousValue || !select.form) return;

    const duplicate = [...select.form.elements].find(
      (element) =>
        element instanceof HTMLSelectElement &&
        element !== select &&
        element.dataset.uniqueGroup === group &&
        element.value === select.value,
    );

    if (duplicate instanceof HTMLSelectElement) {
      duplicate.value = previousValue;
      duplicate.dataset.previousValue = previousValue;
    }

    select.dataset.previousValue = select.value;
  }
</script>

{#if phase === "waiting_for_players"}
  <section class="session-panel-start">
    <form class="session-panel-start__content" onsubmit={startGame}>
      {#if attrFields.length > 0}
        <fieldset class="session-panel-start__fields">
          <legend>Game setup</legend>
          <div class="session-panel-start__field-grid">
            {#each attrFields as [name, attr] (name)}
              <label for={attr.id}>
                <span>{fieldLabel(name, attr)}</span>
                {#if attr.type === "enum"}
                  <select
                    id={attr.id}
                    name={attr.name ?? name}
                    value={fieldValue(attr)}
                    required={attr.required ?? false}
                    data-unique-group={attr.unique
                      ? (attr.name ?? name).replace(/\[.*$/, "")
                      : undefined}
                    data-previous-value={fieldValue(attr)}
                    onchange={keepUniqueValue}
                  >
                    {#each attr.values ?? [] as value (value)}
                      <option {value}>{humanize(value)}</option>
                    {/each}
                  </select>
                {:else}
                  <input
                    id={attr.id}
                    name={attr.name ?? name}
                    value={fieldValue(attr)}
                    required={attr.required ?? false}
                  >
                {/if}
              </label>
            {/each}
          </div>
        </fieldset>
      {/if}

      <button
        class="session-panel-start__action"
        type="submit"
        disabled={$session.processing.start ||
          !$session.value?.permissions?.can_start_game}
        aria-busy={$session.processing.start}
      >
        {#if $session.processing.start}
          <span class="session-panel-start__spinner" aria-hidden="true"></span>
        {/if}
        Start
      </button>

      <div class="session-panel-start__players">
        {#if $session.timeouts.start}
          <p class="session-panel-start__error">timeout</p>
        {:else if $session.errors.start?.reason}
          <p class="session-panel-start__error">{$session.errors.start.reason}</p>
        {/if}

        {#if status === "loading"}
          <p class="session-panel-start__loading">Joining session...</p>
        {:else}
          <ul class="session-panel-players" aria-label="Joined players">
            {#each members as member (member.id)}
              <li class="session-panel-players__item">
                {#if member.avatar}
                  <img
                    class="session-panel-players__avatar"
                    src={member.avatar}
                    alt=""
                    loading="lazy"
                    referrerpolicy="no-referrer"
                  >
                {:else}
                  <span
                    class="session-panel-players__avatar session-panel-players__avatar--fallback"
                    aria-hidden="true"
                  >
                    {member.letter}
                  </span>
                {/if}
                <span class="session-panel-players__name"> {member.name} </span>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    </form>
  </section>
{/if}

{#if phase === "in_progress" || phase === "finished"}
  <section class="session-panel-frame">
    <Frame {module} {connection} />
  </section>
{/if}

<style>
  .session-panel-start {
    min-inline-size: 0;
    border-radius: var(--radius-sm);
    background: var(--color-base-100);
    padding: 0;
  }

  .session-panel-start__content {
    display: flex;
    min-inline-size: 0;
    flex-direction: column;
    gap: 1rem;
  }

  .session-panel-start__fields {
    min-inline-size: 0;
    margin: 0;
    border: 0;
    padding: 0;
  }

  .session-panel-start__fields legend {
    margin-block-end: 0.5rem;
    font-size: 0.75rem;
    font-weight: 600;
  }

  .session-panel-start__field-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(7rem, 1fr));
    gap: 0.5rem;
  }

  .session-panel-start__field-grid label {
    display: grid;
    min-inline-size: 0;
    gap: 0.25rem;
    font-size: 0.75rem;
  }

  .session-panel-start__field-grid select,
  .session-panel-start__field-grid input {
    min-block-size: 2.25rem;
    inline-size: 100%;
    border: 1px solid var(--color-base-300);
    border-radius: var(--radius-sm);
    background: var(--color-base-100);
    padding-inline: 0.5rem;
    color: var(--color-base-content);
    font: inherit;
  }

  .session-panel-start__action {
    display: inline-flex;
    min-block-size: 2.5rem;
    inline-size: 100%;
    min-inline-size: 0;
    align-self: stretch;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    border: 1px solid var(--color-base-content);
    border-radius: var(--radius-sm);
    background: var(--color-base-content);
    padding: 0.5rem 1rem;
    color: var(--color-base-100);
    font-size: 0.875rem;
    font-weight: 600;
    line-height: 1;
    transition:
      background-color 150ms ease,
      border-color 150ms ease,
      opacity 150ms ease;
  }

  .session-panel-start__action:hover:not(:disabled) {
    background: color-mix(in oklab, var(--color-base-content) 86%, transparent);
  }

  .session-panel-start__action:focus-visible {
    outline: 2px solid color-mix(in oklab, var(--color-base-content) 42%, transparent);
    outline-offset: 2px;
  }

  .session-panel-start__action:disabled {
    cursor: not-allowed;
    opacity: 0.55;
  }

  .session-panel-start__spinner {
    inline-size: 0.875rem;
    block-size: 0.875rem;
    flex: none;
    animation: session-panel-spin 700ms linear infinite;
    border: 2px solid color-mix(in oklab, var(--color-base-100) 35%, transparent);
    border-block-start-color: var(--color-base-100);
    border-radius: 999px;
  }

  .session-panel-start__players {
    min-inline-size: 0;
    flex: 1;
  }

  .session-panel-start__error {
    margin: 0 0 0.75rem;
    color: var(--color-error);
    font-size: 0.875rem;
    line-height: 1.4;
  }

  .session-panel-start__loading {
    margin: 0;
    padding-block: 0.5rem;
    color: color-mix(in oklab, var(--color-base-content) 60%, transparent);
    font-size: 0.875rem;
    line-height: 1.4;
  }

  .session-panel-players {
    display: flex;
    min-inline-size: 0;
    flex-wrap: wrap;
    align-items: flex-start;
    gap: 0.75rem;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  .session-panel-players__item {
    display: flex;
    inline-size: 4rem;
    min-inline-size: 0;
    flex: none;
    flex-direction: column;
    align-items: center;
    gap: 0.375rem;
  }

  .session-panel-players__avatar {
    inline-size: 2.5rem;
    block-size: 2.5rem;
    flex: none;
    border-radius: var(--radius-sm);
    background: var(--color-base-200);
    object-fit: cover;
  }

  .session-panel-players__avatar--fallback {
    display: flex;
    align-items: center;
    justify-content: center;
    color: color-mix(in oklab, var(--color-base-content) 70%, transparent);
    font-size: 0.75rem;
    font-weight: 500;
    line-height: 1;
    text-transform: uppercase;
  }

  .session-panel-players__name {
    display: -webkit-box;
    max-inline-size: 100%;
    overflow: hidden;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    line-clamp: 2;
    color: var(--color-base-content);
    font-size: 0.75rem;
    line-height: 1.25;
    overflow-wrap: break-word;
    text-align: center;
    text-wrap: balance;
  }

  .session-panel-frame {
    position: fixed;
    inset: 0;
    z-index: 1000;
    display: grid;
    place-items: center;
    overflow: hidden;
    background: rgb(0 0 0 / 0.42);
    box-sizing: border-box;
  }

  @keyframes session-panel-spin {
    to {
      rotate: 360deg;
    }
  }

  @media (prefers-reduced-motion: reduce) {
    .session-panel-start__action,
    .session-panel-start__spinner {
      animation: none;
      transition: none;
    }
  }
</style>
