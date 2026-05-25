<script lang="ts">
  import { module as expose } from "@rvct/d20sdk";
  import type { ModuleEntry } from "~types/module";

  interface Props {
    module: ModuleEntry;
  }

  const { module }: Props = $props();

  let iframe: HTMLIFrameElement | undefined;

  $effect(() => {
    if (!module.bootstrap || !iframe?.contentWindow) return;

    const connection = expose({
      remoteWindow: iframe.contentWindow,
      allowedOrigins: module.allowedOrigins,
      bootstrap: module.bootstrap,
    });

    return () => {
      connection.destroy();
    };
  });
</script>

<iframe
  bind:this={iframe}
  class="h-full w-full"
  title={`${module.title} preview`}
  src={module.embedUrl}
  loading="lazy"
  sandbox={module.sandbox.join(" ")}
></iframe>
