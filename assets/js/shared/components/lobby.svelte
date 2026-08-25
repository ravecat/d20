<script lang="ts">
  import { router } from "@inertiajs/svelte";
  import { onDestroy, onMount, untrack } from "svelte";
  import Session from "./session.svelte";
  import { createSession } from "~/shared/stores";
  import type { SessionDescriptor } from "~/shared/types/game";

  interface Props {
    session: SessionDescriptor;
  }

  const { session }: Props = $props();
  const { topic, gameId } = untrack(() => session);
  const controller = createSession(topic);
  let handled = false;

  onMount(() =>
    controller.subscribe(({ value }) => {
      if (value?.phase === "in_progress" || value?.phase === "finished") {
        if (handled) return;

        handled = true;

        router.get(`/games/${gameId}`, {}, { preserveScroll: true, replace: true });
      }
    }),
  );

  onDestroy(controller.detach);
</script>

<Session {controller} />
