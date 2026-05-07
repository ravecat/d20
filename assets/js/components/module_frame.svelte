<script lang="ts">
  import type { ModuleEntry, ModuleReadyMessage } from "~types/module";

  interface Props {
    module: ModuleEntry;
  }

  const { module }: Props = $props();

  let iframe: HTMLIFrameElement | undefined;

  function isModuleReadyMessage(data: unknown): data is ModuleReadyMessage {
    return (
      typeof data === "object" &&
      data !== null &&
      "type" in data &&
      data.type === "d20.module.ready" &&
      "moduleId" in data &&
      typeof data.moduleId === "string"
    );
  }

  function handleMessage(event: MessageEvent) {
    if (!module.bootstrap) return;
    if (!iframe?.contentWindow || event.source !== iframe.contentWindow) return;
    if (!module.allowedOrigins?.includes(event.origin)) return;

    const data = event.data;
    if (!isModuleReadyMessage(data)) return;
    if (data.moduleId !== module.id) return;

    iframe.contentWindow.postMessage(
      {
        type: "d20.module.bootstrap",
        ...module.bootstrap,
      },
      event.origin,
    );
  }

  $effect(() => {
    window.addEventListener("message", handleMessage);

    return () => {
      window.removeEventListener("message", handleMessage);
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
