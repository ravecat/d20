<script lang="ts">
  import type { SessionStore } from "~/shared/stores";

  interface Props {
    controller: SessionStore;
  }

  const { controller }: Props = $props();

  const members = $derived(
    Object.entries($controller.value?.members ?? {})
      .filter(([, member]) => member.status === "online")
      .map(([id, member]) => {
        const name = member.display_name || "Player";

        return {
          id,
          name,
          avatar: member.avatar,
          letter: name.charAt(0).toUpperCase() || "?",
        };
      }),
  );
  const status = $derived($controller.status);
  const phase = $derived($controller.value?.phase);
</script>

{#if phase === "waiting_for_players"}
  <section class="session-panel-start">
    <div class="session-panel-start__content">
      <button
        class="session-panel-start__action"
        type="button"
        disabled={$controller.processing.start || !$controller.value?.permissions?.can_start_game}
        aria-busy={$controller.processing.start}
        onclick={() => controller.start()}
      >
        {#if $controller.processing.start}
          <span class="session-panel-start__spinner" aria-hidden="true"></span>
        {/if}
        Start
      </button>

      <div class="session-panel-start__players">
        {#if $controller.timeouts.start}
          <p class="session-panel-start__error">timeout</p>
        {:else if $controller.errors.start?.reason}
          <p class="session-panel-start__error">{$controller.errors.start.reason}</p>
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
                  />
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
    </div>
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
