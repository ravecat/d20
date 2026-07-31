<script lang="ts">
  import { router } from "@inertiajs/svelte";
  import { onDestroy, onMount, untrack } from "svelte";
  import Session from "./session.svelte";
  import { createSession } from "~/shared/stores";
  import type { SessionDescriptor } from "~/shared/types";

  interface Props {
    session: SessionDescriptor;
  }

  const { session }: Props = $props();
  const controller = untrack(() => createSession(session.topic));
  let handled = false;
  let joinRequested = false;

  function finish() {
    if (handled) return;

    const { slug } = session;
    handled = true;

    router.get(`/games/${slug}`, {}, { preserveScroll: true, replace: true });
  }

  onMount(() =>
    controller.subscribe(({ value, status }) => {
      if (status === "ready" && value?.phase === "waiting_for_players" && !joinRequested) {
        joinRequested = true;
        controller.join();
      }

      if (value?.phase === "in_progress" || value?.phase === "finished") finish();
    }),
  );

  onDestroy(controller.detach);
</script>

<Session {controller} />
