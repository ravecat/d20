<script lang="ts">
  import Frame from "~components/module_frame.svelte";
  import SessionPanel from "~components/session_panel.svelte";
  import type { GameSessionStore } from "~stores/session";
  import type { GameSession } from "~types/game";
  import type { ModuleEntry } from "~types/module";

  interface Props {
    module: ModuleEntry;
    session: GameSession;
    gameSession: GameSessionStore;
  }

  const { module, session, gameSession }: Props = $props();

  const sessionState = $derived($gameSession.value);
  const activeSession = $derived(sessionState ?? session);
</script>

<SessionPanel session={gameSession} />

{#if activeSession.phase === "in_progress" && module.bootstrap}
  <section class="mt-6 h-136 min-h-0 overflow-hidden rounded-sm border border-base-300">
    <Frame {module} />
  </section>
{:else}
  <p class="mt-6 text-sm text-base-content/70">Waiting for players</p>
{/if}
