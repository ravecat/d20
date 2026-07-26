<script lang="ts">
  import { module as expose } from "@rvct/d20sdk";
  import { untrack } from "svelte";
  import type { Attachment } from "svelte/attachments";
  import type { ModuleConnection, ModuleEntry } from "~/shared/api";

  interface Props {
    module: ModuleEntry;
    connection: ModuleConnection;
  }

  const { module, connection }: Props = $props();

  const connectFrame: Attachment<HTMLIFrameElement> = (iframe) => {
    return untrack(() => {
      if (!iframe.contentWindow) return;

      const bridge = expose({
        remoteWindow: iframe.contentWindow,
        allowedOrigins: module.allowedOrigins,
        bootstrap: {
          endpoint: connection.endpoint,
          topic: connection.topic,
          token: connection.token,
        },
      });

      return () => bridge.destroy();
    });
  };
</script>

<iframe
  {@attach connectFrame}
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
