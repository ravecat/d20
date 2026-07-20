<script lang="ts">
  import { module as expose } from "@rvct/d20sdk";
  import type { ModuleConnection, ModuleEntry } from "~types/module";

  interface Props {
    module: ModuleEntry;
    connection: ModuleConnection;
  }

  const { module, connection }: Props = $props();

  let iframe: HTMLIFrameElement | undefined;

  $effect(() => {
    if (!iframe?.contentWindow) return;

    const bridge = expose({
      remoteWindow: iframe.contentWindow,
      allowedOrigins: module.allowedOrigins,
      bootstrap: {
        endpoint: connection.endpoint,
        topic: connection.topic,
        token: connection.token,
      },
    });

    return () => {
      bridge.destroy();
    };
  });
</script>

<iframe
  bind:this={iframe}
  class="frame"
  title="Game module"
  src={module.embedUrl}
  loading="lazy"
  sandbox={module.sandbox.join(" ")}
></iframe>

<style>
  .frame {
    display: block;
    inline-size: 100%;
    block-size: 100%;
    border: none;
    background: white;
  }
</style>
