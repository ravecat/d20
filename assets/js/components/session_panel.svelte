<script lang="ts">
  import type { GameSessionStore } from "~stores/session";

  interface Props {
    session: GameSessionStore;
  }

  const { session }: Props = $props();

  let starting = $state(false);
  let startAccepted = $state(false);
  let startError = $state<string | null>(null);

  const members = $derived(
    Object.entries($session.value?.members ?? {})
      .map(([id, status]) => ({ id, status }))
      .sort((a, b) => a.id.localeCompare(b.id)),
  );
  const presentMembers = $derived(members.filter((member) => member.status === "online"));
  const status = $derived($session.status);
  const phase = $derived($session.value?.phase);
  const canStart = $derived(
    status === "ready" && !starting && !startAccepted && phase === "waiting_for_players",
  );

  function handleStart() {
    starting = true;
    startAccepted = false;
    startError = null;

    session
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
      <span class="text-xs tabular-nums text-base-content/60">{presentMembers.length}</span>
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

  {#if status === "failed" && presentMembers.length === 0}
    <p class="px-4 py-3 text-sm text-error">Presence unavailable</p>
  {:else if presentMembers.length === 0}
    <p class="px-4 py-3 text-sm text-base-content/60">Joining session...</p>
  {:else}
    <ul class="divide-y divide-base-300">
      {#each presentMembers as member (member.id)}
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
