import type { ModuleConnection, ModuleEntry } from "~types/module";

export type WorkspaceMode = "compact" | "theater";
export type WorkspaceChannelStatus = "failed" | "loading" | "ready" | "stale";

export interface WorkspaceSessionDescriptor {
  id: string;
  slug: string;
  module: ModuleEntry;
  connection: ModuleConnection;
}

export interface Workspace {
  sessions: WorkspaceSessionDescriptor[];
}

export interface SessionDescriptor extends WorkspaceSessionIdentity {
  topic: string;
}

export interface WorkspaceSessionIdentity {
  id: string;
  slug: string;
}

export interface WorkspacePayload {
  sessions: Array<{
    id: string;
    slug: string;
    module: {
      embed_url: string;
      allowed_origins: string[];
      sandbox: string[];
    };
    connection: ModuleConnection;
  }>;
}

export interface WorkspaceChannelState {
  value: Workspace | null;
  status: WorkspaceChannelStatus;
  error: unknown;
  processing: { close: boolean };
  errors: { close: { reason?: string } | null };
  timeouts: { close: boolean };
}

export interface WorkspaceEntry {
  id: string;
  slug: string;
  mode: WorkspaceMode;
  channelStatus: WorkspaceChannelStatus;
  closing: boolean;
  closeError: string | null;
  module: ModuleEntry;
  connection: ModuleConnection;
}

export interface WorkspaceState {
  entries: WorkspaceEntry[];
  status: WorkspaceChannelStatus;
  error: unknown;
}
