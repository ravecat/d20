import "@inertiajs/core";
import type { LiveSocket } from "phoenix_live_view";
import type { PageProps, SharedPageProps } from "@inertiajs/core";

declare module "@inertiajs/core" {
  interface InertiaConfig {
    sharedPageProps: Record<string, never>;
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
