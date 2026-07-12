import "@inertiajs/core";
import type { LiveSocket } from "phoenix_live_view";
import type { PageProps, SharedPageProps } from "@inertiajs/core";

declare module "@inertiajs/core" {
  interface InertiaConfig {
    sharedPageProps: Record<string, never>;
  }
}

declare module "svelte/elements" {
  // biome-ignore lint/correctness/noUnusedVariables: The generic must match Svelte's declaration.
  interface HTMLAttributes<T extends EventTarget> {
    "scroll-region"?: boolean | "";
  }
}

declare global {
  type InertiaProps<Props extends object = Record<string, never>> = PageProps &
    SharedPageProps &
    Props;

  interface Window {
    actorToken?: string;
    liveSocket?: LiveSocket;
    liveReloader?: {
      enableServerLogs(): void;
      openEditorAtCaller(target: EventTarget | null): void;
      openEditorAtDef(target: EventTarget | null): void;
    };
  }
}
