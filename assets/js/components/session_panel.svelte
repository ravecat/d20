<script lang="ts">
  import { untrack } from "svelte";
  import Frame from "~components/module_frame.svelte";
  import { createSession } from "~stores/session";
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

  function handleStart() {
    session.start();
  }
</script>

{#if phase === "waiting_for_players"}
  <section class="mt-6 min-w-0 rounded-sm border border-base-300 bg-base-100 px-4 py-3">
    <div class="flex min-w-0 items-start gap-4">
      <button
        class="inline-flex min-h-10 min-w-20 flex-none items-center justify-center gap-2 rounded-sm border border-base-content bg-base-content px-3 py-2 text-sm font-medium text-base-100 transition-colors hover:bg-base-content/85 focus:outline-none focus:ring-2 focus:ring-base-content/40 disabled:cursor-not-allowed disabled:opacity-50"
        type="button"
        disabled={$session.processing.start}
        aria-busy={$session.processing.start}
        onclick={handleStart}
      >
        {#if $session.processing.start}
          <span
            class="size-3 animate-spin rounded-full border-2 border-base-100/35 border-t-base-100"
            aria-hidden="true"
          ></span>
        {/if}
        Start
      </button>

      <div class="min-w-0 flex-1">
        {#if $session.timeouts.start}
          <p class="mb-3 text-sm text-error">timeout</p>
        {:else if $session.errors.start?.reason}
          <p class="mb-3 text-sm text-error">{$session.errors.start.reason}</p>
        {/if}

        {#if status === "loading"}
          <p class="py-2 text-sm text-base-content/60">Joining session...</p>
        {:else if status === "failed" && members.length === 0}
          <p class="py-2 text-sm text-error">Presence unavailable</p>
        {:else}
          <ul class="flex min-w-0 flex-wrap items-start gap-3">
            {#each members as member (member.id)}
              <li class="flex w-16 min-w-0 flex-none flex-col items-center gap-1.5">
                {#if member.avatar}
                  <img
                    class="size-10 flex-none rounded-sm border border-base-300 bg-base-200 object-cover"
                    src={member.avatar}
                    alt=""
                    loading="lazy"
                    referrerpolicy="no-referrer"
                  >
                {:else}
                  <span
                    class="flex size-10 flex-none items-center justify-center rounded-sm border border-base-300 bg-base-200 text-xs font-medium uppercase text-base-content/70"
                    aria-hidden="true"
                  >
                    {member.letter}
                  </span>
                {/if}
                <span class="block max-w-full truncate text-center text-xs text-base-content">
                  {member.name}
                </span>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    </div>
  </section>
{/if}

{#if phase === "in_progress"}
  <section class="mt-6 h-136 min-h-0 overflow-hidden rounded-sm border border-base-300">
    <Frame {module} {connection} />
  </section>
{/if}
