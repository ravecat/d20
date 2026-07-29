import { createStore } from "@xstate/store";
import { session as createSession } from "phoenix-session";
import { derived, readable, type Readable } from "svelte/store";
import { socket, type ModuleConnection, type ModuleEntry } from "~/shared/api";

export type WorkspaceLayout =
  | { mode: "auto" }
  | { mode: "focused"; id: string }
  | { mode: "compact" };

export type WorkspaceSessionPhase = "in_progress" | "finished";

export interface WorkspaceSessionDescriptor {
  id: string;
  slug: string;
  phase: WorkspaceSessionPhase;
  module: ModuleEntry;
  connection: ModuleConnection;
}

export interface Workspace {
  sessions?: WorkspaceSessionDescriptor[];
}

type PhoenixWorkspaceSession = ReturnType<typeof createSession<Workspace>>;

type PhoenixWorkspaceState = Parameters<Parameters<PhoenixWorkspaceSession["subscribe"]>[0]>[0];

export interface WorkspaceState {
  error: PhoenixWorkspaceState["error"];
  layout: WorkspaceLayout;
  sessions: WorkspaceSessionDescriptor[];
  status: PhoenixWorkspaceState["status"];
}

export interface WorkspaceStore extends Readable<WorkspaceState> {
  compact(): void;
  close(id: string): void;
  focus(id: string): void;
}

export function createWorkspace(): WorkspaceStore {
  const session = createSession<Workspace>(socket, {
    topic: "workspace",
    connect: {
      ok: (_value, workspace: Workspace) => workspace,
    },
    events: {
      snapshot: (_value, workspace: Workspace) => workspace,
    },
  }).extend(({ call }) => ({
    close(id: string) {
      call("close", { id });
    },
  }));

  const store = createStore<
    {
      layout: WorkspaceLayout;
    },
    {
      focus: { id: string };
      compact: null;
    }
  >({
    context: {
      layout: { mode: "compact" },
    },
    on: {
      focus: (context, event) => ({
        ...context,
        layout: { mode: "focused", id: event.id },
      }),
      compact: (context) => ({
        ...context,
        layout: { mode: "compact" },
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

  function focus(id: string) {
    store.trigger.focus({ id });
  }

  function compact() {
    store.trigger.compact();
  }

  function close(id: string) {
    session.close(id);
  }

  return {
    subscribe: state.subscribe,
    compact,
    close,
    focus,
  };
}
