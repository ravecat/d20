import { createStore } from "@xstate/store";
import { session as createSession } from "phoenix-session";
import { derived, get, readable, type Readable } from "svelte/store";
import { socket, type ModuleConnection, type ModuleEntry } from "~/shared/api";

export type WorkspaceChannelStatus = "failed" | "loading" | "ready" | "stale";
export type WorkspaceLayout =
  | { mode: "auto" }
  | { mode: "focused"; sessionId: string }
  | { mode: "compact" };

export interface WorkspaceSessionDescriptor {
  id: string;
  slug: string;
  module: ModuleEntry;
  connection: ModuleConnection;
}

export interface Workspace {
  sessions?: WorkspaceSessionDescriptor[];
}

export interface WorkspaceChannelState {
  value: Workspace | null;
  status: WorkspaceChannelStatus;
  error: unknown;
  processing: { close: boolean };
  errors: { close: { reason?: string } | null };
  timeouts: { close: boolean };
}

export interface WorkspaceState {
  error: unknown;
  layout: WorkspaceLayout;
  sessions: WorkspaceSessionDescriptor[];
  status: WorkspaceChannelStatus;
}

interface WorkspaceOptions {
  session?: WorkspaceSession;
}

export interface WorkspaceSession extends Readable<WorkspaceChannelState> {
  detach(): void;
  close(sessionId: string): void;
}

export interface WorkspaceStore extends Readable<WorkspaceState> {
  compact(sessionId: string): void;
  close(sessionId: string): void;
  dispose(): void;
  focus(sessionId: string): void;
}

export function createWorkspace(options: WorkspaceOptions = {}): WorkspaceStore {
  const session =
    options.session ??
    createSession<Workspace>(socket, {
      topic: "workspace",
      connect: {
        ok: (_value, workspace: Workspace) => workspace,
      },
      events: {
        snapshot: (_value, workspace: Workspace) => workspace,
      },
    }).extend(({ call }) => ({
      close(sessionId: string) {
        call("close", { id: sessionId });
      },
    }));
  let disposed = false;

  const store = createStore<
    {
      layout: WorkspaceLayout;
    },
    {
      focus: { sessionId: string };
      compact: null;
      reset: null;
    }
  >({
    context: {
      layout: { mode: "auto" },
    },
    on: {
      focus: (context, event) => ({
        ...context,
        layout: { mode: "focused", sessionId: event.sessionId },
      }),
      compact: (context) => ({
        ...context,
        layout: { mode: "compact" },
      }),
      reset: () => ({
        layout: { mode: "auto" },
      }),
    },
  });

  const context = readable(store.get().context, (set) => {
    set(store.get().context);

    const subscription = store.subscribe(({ context }) => set(context));
    return () => subscription.unsubscribe();
  });

  const state = derived([session, context], ([$session, $context]) => {
    return {
      status: $session.status,
      error: $session.error,
      sessions: $session.value?.sessions ?? [],
      layout: $context.layout,
    };
  });

  function focus(sessionId: string) {
    if (disposed || !get(state).sessions.some(({ id }) => id === sessionId)) return;
    store.trigger.focus({ sessionId });
  }

  function compact(sessionId: string) {
    if (disposed) return;

    const current = get(state);

    switch (current.layout.mode) {
      case "auto":
        if (current.sessions[0]?.id !== sessionId) return;
        break;
      case "focused": {
        const requestedSessionId = current.layout.sessionId;

        if (
          current.sessions.some(({ id }) => id === requestedSessionId)
            ? requestedSessionId !== sessionId
            : current.sessions[0]?.id !== sessionId
        ) {
          return;
        }
        break;
      }
      case "compact":
        return;
      default: {
        const exhaustive: never = current.layout;
        return exhaustive;
      }
    }

    store.trigger.compact();
  }

  function close(sessionId: string) {
    if (disposed || !get(state).sessions.some(({ id }) => id === sessionId)) return;

    session.close(sessionId);
  }

  function dispose() {
    if (disposed) return;
    disposed = true;
    session.detach();
    store.trigger.reset();
  }

  return {
    subscribe: state.subscribe,
    compact,
    close,
    dispose,
    focus,
  };
}
