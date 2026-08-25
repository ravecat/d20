import { createStore } from "@xstate/store";
import { session as createSession } from "phoenix-session";
import { derived, readable, type Readable } from "svelte/store";
import { socket, type ModuleConnection, type ModuleEntry } from "~/shared/api";

export type WorkspaceLayout =
  | { mode: "auto"; id: string | undefined }
  | { mode: "focused"; id: string }
  | { mode: "compact"; id: undefined };

export type WorkspaceSessionPhase = "in_progress" | "finished";

export interface WorkspaceSessionDescriptor {
  id: string;
  game_id: string;
  phase: WorkspaceSessionPhase;
  module: ModuleEntry;
  connection: ModuleConnection;
}

export interface Workspace {
  sessions?: WorkspaceSessionDescriptor[];
}

interface WorkspaceCommandError {
  reason?: string;
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
  closeSession(id: string): void;
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
    closeSession(id: string) {
      return call<unknown, WorkspaceCommandError>("close_session", { id });
    },
  }));

  const layout = createStore<
    WorkspaceLayout,
    {
      focus: { id: string };
      compact: null;
    }
  >({
    context: { mode: "auto", id: undefined },
    on: {
      focus: (_context, event) => ({ mode: "focused", id: event.id }),
      compact: () => ({ mode: "compact", id: undefined }),
    },
  });

  const context = readable(layout.get().context, (set) => {
    set(layout.get().context);

    const subscription = layout.subscribe(({ context }) => set(context));
    return () => subscription.unsubscribe();
  });

  const state = derived([session, context], ([$session, $context]) => {
    const sessions = $session.value?.sessions ?? [];

    return {
      status: $session.status,
      error: $session.error,
      sessions,
      layout: $context.mode === "auto" ? { ...$context, id: sessions[0]?.id } : $context,
    };
  });

  function focus(id: string) {
    layout.trigger.focus({ id });
  }

  function compact() {
    layout.trigger.compact();
  }

  function closeSession(id: string) {
    session.closeSession(id);
  }

  return {
    subscribe: state.subscribe,
    compact,
    closeSession,
    focus,
  };
}
