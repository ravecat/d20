import { session } from "phoenix-session";
import { socket } from "~/shared/api";
import type { Workspace, WorkspaceChannelState, WorkspacePayload } from "~/shared/types";

export interface WorkspaceChannel {
  subscribe(listener: (state: WorkspaceChannelState) => void): () => void;
  dispose(): void;
  close(sessionId: string): WorkspaceCloseCall;
}

export interface WorkspaceCloseCall {
  receive(status: "ok", callback: () => unknown): WorkspaceCloseCall;
  receive(status: "error", callback: (error: WorkspaceCloseError) => unknown): WorkspaceCloseCall;
  receive(status: "timeout", callback: () => unknown): WorkspaceCloseCall;
}

export interface WorkspaceCloseError {
  reason?: string;
}

export function createWorkspaceChannel(): WorkspaceChannel {
  const controller = session<Workspace>(socket, {
    topic: "workspace",
    connect: {
      ok: (_value, payload: WorkspacePayload) => normalize(payload),
    },
    events: {
      snapshot: (_value, payload: WorkspacePayload) => normalize(payload),
    },
  }).extend(({ call }) => ({
    close(sessionId: string) {
      return call<unknown, WorkspaceCloseError>("close", { id: sessionId });
    },
  }));

  return {
    subscribe: controller.subscribe,
    dispose: controller.detach,
    close: controller.close,
  };
}

function normalize(payload: WorkspacePayload): Workspace {
  return {
    sessions: payload.sessions.map((descriptor) => ({
      id: descriptor.id,
      slug: descriptor.slug,
      module: {
        embedUrl: descriptor.module.embed_url,
        allowedOrigins: descriptor.module.allowed_origins,
        sandbox: descriptor.module.sandbox,
      },
      connection: descriptor.connection,
    })),
  };
}
