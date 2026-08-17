import "@inertiajs/core";
import type { LiveSocket } from "phoenix_live_view";
import type { SharedPageProps } from "@inertiajs/core";

declare module "@inertiajs/core" {
  interface InertiaConfig {
    sharedPageProps: {
      auth: {
        readonly authenticated: boolean;
        readonly local: boolean;
        readonly providers: {
          readonly google: {
            readonly available: boolean;
          };
        };
        readonly prompt: {
          readonly email: string;
          readonly kind: "info" | "warning" | "error";
          readonly message: string;
          readonly reauthenticate: boolean;
          readonly returnTo: string;
        } | null;
      };
    };
  }
}

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
