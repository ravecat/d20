import "@inertiajs/core";
import type { LiveSocket } from "phoenix_live_view";
import type { SharedPageProps } from "@inertiajs/core";

declare module "svelte/elements" {
  interface HTMLAttributes<T extends EventTarget> {
    "scroll-region"?: boolean | "";
  }
}

declare global {
  type InertiaProps<Props extends object = Record<string, never>> = SharedPageProps & Props;

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
