<script lang="ts">
  import { untrack } from "svelte";
  import Frame from "~components/module_frame.svelte";
  import { createSession } from "~stores/session";
  import type { Session } from "~types/game";
  import type { ModuleEntry } from "~types/module";

  interface Props {
    module: ModuleEntry;
    session: Session;
  }

  const { module, session }: Props = $props();
  const sessionStore = createSession(untrack(() => session.id));

  let starting = $state(false);
  let startAccepted = $state(false);
  let startError = $state<string | null>(null);

  const members = $derived(
    Object.entries($sessionStore.value?.members ?? {})
      .map(([id]) => ({ id }))
      .sort((a, b) => a.id.localeCompare(b.id)),
  );
  const status = $derived($sessionStore.status);
  const phase = $derived($sessionStore.value?.phase);
  const canStart = $derived(
    status === "ready" && !starting && !startAccepted && phase === "waiting_for_players",
  );

  function handleStart() {
    starting = true;
    startAccepted = false;
    startError = null;

    sessionStore
      .start()
      .receive("ok", () => {
        starting = false;
        startAccepted = true;
      })
      .receive("error", (reply: { reason?: string }) => {
        starting = false;
        startAccepted = false;
        startError = reply.reason ?? "start_failed";
      })
      .receive("timeout", () => {
        starting = false;
        startAccepted = false;
        startError = "timeout";
      });
  }
</script>

<section class="mt-6 min-w-0 overflow-hidden rounded-sm border border-base-300 bg-base-100">
  <div class="flex items-center justify-between gap-3 border-b border-base-300 px-4 py-3">
    <div class="flex min-w-0 items-center gap-3">
      <h2 class="text-sm font-medium text-base-content">Present</h2>
      <span class="text-xs tabular-nums text-base-content/60">{members.length}</span>
    </div>

    <button
      class="inline-flex min-h-8 min-w-20 items-center justify-center gap-2 rounded-sm border border-base-content bg-base-content px-3 py-1.5 text-xs font-medium text-base-100 transition-colors hover:bg-base-content/85 focus:outline-none focus:ring-2 focus:ring-base-content/40 disabled:cursor-not-allowed disabled:opacity-50"
      type="button"
      disabled={!canStart}
      aria-busy={starting}
      onclick={handleStart}
    >
      {#if starting}
        <span
          class="size-3 animate-spin rounded-full border-2 border-base-100/35 border-t-base-100"
          aria-hidden="true"
        ></span>
      {/if}
      Start
    </button>
  </div>

  {#if startError}
    <p class="border-b border-base-300 px-4 py-3 text-sm text-error">{startError}</p>
  {/if}

  {#if status === "loading"}
    <p class="px-4 py-3 text-sm text-base-content/60">Joining session...</p>
  {:else if status === "failed" && members.length === 0}
    <p class="px-4 py-3 text-sm text-error">Presence unavailable</p>
  {:else if members.length === 0}
    <p class="px-4 py-3 text-sm text-base-content/60">No players present</p>
  {:else}
    <ul class="divide-y divide-base-300">
      {#each members as member (member.id)}
        <li
          class="flex min-w-0 flex-col items-start gap-1 px-4 py-3 sm:flex-row sm:items-center sm:gap-3"
        >
          <span class="w-full min-w-0 truncate text-sm text-base-content sm:flex-1"
            >{member.id}</span
          >
        </li>
      {/each}
    </ul>
  {/if}
</section>

{#if status === "loading"}
  <p class="mt-6 text-sm text-base-content/70">Joining session...</p>
{:else if phase === "in_progress" && module.bootstrap}
  <section class="mt-6 h-136 min-h-0 overflow-hidden rounded-sm border border-base-300">
    <Frame {module} />
  </section>
{:else}
  <p class="mt-6 text-sm text-base-content/70">Waiting for players</p>
{/if}
