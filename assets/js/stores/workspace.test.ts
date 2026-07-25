import { get, writable } from "svelte/store";
import { describe, expect, it, vi } from "vitest";
import { createWorkspace } from "~stores/workspace";
import type {
  WorkspaceChannel,
  WorkspaceCloseCall,
  WorkspaceCloseError,
} from "~stores/workspace_channel";
import type {
  Workspace,
  WorkspaceChannelState,
  WorkspaceSessionDescriptor,
} from "~types/workspace";

describe("Workspace", () => {
  it("reconciles authoritative workspace state by id without creating game session controllers", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ discovery: discovery.channel });

    discovery.ready([descriptor("session-a", "qwinto"), descriptor("session-b", "qwinto")]);

    expect(get(workspace).entries.map(({ id, slug, mode }) => ({ id, slug, mode }))).toEqual([
      { id: "session-a", slug: "qwinto", mode: "theater" },
      { id: "session-b", slug: "qwinto", mode: "compact" },
    ]);

    workspace.compact("session-a");
    discovery.ready([
      descriptor("session-b", "qwinto", "fresh-token"),
      descriptor("session-c", "koala-rescue-club"),
    ]);

    expect(get(workspace).entries.map(({ id, mode }) => ({ id, mode }))).toEqual([
      { id: "session-b", mode: "compact" },
      { id: "session-c", mode: "compact" },
    ]);
    expect(entry(workspace, "session-b").connection.token).toBe("fresh-token");
  });

  it("keeps windows stale during a transport outage and applies the reconnected workspace", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ discovery: discovery.channel });

    discovery.ready([descriptor("session-a")]);
    discovery.stale();

    expect(get(workspace).entries.map(({ id }) => id)).toEqual(["session-a"]);
    expect(entry(workspace, "session-a").channelStatus).toBe("stale");

    discovery.ready([]);

    expect(get(workspace).entries).toEqual([]);
  });

  it("sends close through WorkspaceChannel and waits for workspace state before removing the window", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ discovery: discovery.channel });

    discovery.ready([descriptor("session-a")]);
    workspace.close("session-a");

    expect(discovery.close).toHaveBeenCalledWith("session-a");
    expect(entry(workspace, "session-a").closing).toBe(true);

    discovery.latestClose().reply("ok");

    expect(entry(workspace, "session-a").closing).toBe(true);

    discovery.ready([]);

    expect(get(workspace).entries).toEqual([]);
  });

  it("keeps a rejected close retryable", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ discovery: discovery.channel });

    discovery.ready([descriptor("session-a")]);
    workspace.close("session-a");
    discovery.latestClose().reply("error", { reason: "not_allowed" });

    expect(entry(workspace, "session-a").closing).toBe(false);
    expect(entry(workspace, "session-a").closeError).toBe("not_allowed");

    workspace.close("session-a");

    expect(discovery.close).toHaveBeenCalledTimes(2);
  });

  it("detaches discovery with the layout", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ discovery: discovery.channel });

    workspace.dispose();

    expect(discovery.dispose).toHaveBeenCalledOnce();
  });
});

function discoveryHarness() {
  const state = writable<WorkspaceChannelState>(discoveryState("loading", null));
  const dispose = vi.fn();
  const requests: CloseRequest[] = [];
  const close = vi.fn((_sessionId: string) => {
    const request = new CloseRequest();
    requests.push(request);
    return request;
  });
  const channel: WorkspaceChannel = {
    subscribe: state.subscribe,
    dispose,
    close,
  };

  return {
    channel,
    dispose,
    close,
    latestClose() {
      const request = requests.at(-1);
      if (!request) throw new Error("Expected a close request.");
      return request;
    },
    ready(sessions: WorkspaceSessionDescriptor[]) {
      state.set(discoveryState("ready", { sessions }));
    },
    stale() {
      state.update((current) => ({ ...current, status: "stale" }));
    },
  };
}

class CloseRequest implements WorkspaceCloseCall {
  private callbacks: {
    ok?: () => unknown;
    error?: (error: WorkspaceCloseError) => unknown;
    timeout?: () => unknown;
  } = {};

  receive(status: "ok", callback: () => unknown): WorkspaceCloseCall;
  receive(status: "error", callback: (error: WorkspaceCloseError) => unknown): WorkspaceCloseCall;
  receive(status: "timeout", callback: () => unknown): WorkspaceCloseCall;
  receive(
    status: "ok" | "error" | "timeout",
    callback: (() => unknown) | ((error: WorkspaceCloseError) => unknown),
  ) {
    Object.assign(this.callbacks, { [status]: callback });
    return this;
  }

  reply(status: "ok" | "timeout"): void;
  reply(status: "error", error: WorkspaceCloseError): void;
  reply(status: "ok" | "error" | "timeout", error: WorkspaceCloseError = {}) {
    if (status === "error") {
      this.callbacks.error?.(error);
      return;
    }

    this.callbacks[status]?.();
  }
}

function discoveryState(
  status: WorkspaceChannelState["status"],
  value: Workspace | null,
): WorkspaceChannelState {
  return {
    value,
    status,
    error: null,
    processing: { close: false },
    errors: { close: null },
    timeouts: { close: false },
  };
}

function descriptor(
  id: string,
  slug = "qwinto",
  token = `token-${id}`,
): WorkspaceSessionDescriptor {
  return {
    id,
    slug,
    module: {
      embedUrl: `https://module.example.test/${id}`,
      allowedOrigins: ["https://module.example.test"],
      sandbox: ["allow-scripts"],
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token,
    },
  };
}

function entry(workspace: ReturnType<typeof createWorkspace>, sessionId: string) {
  const found = get(workspace).entries.find((candidate) => candidate.id === sessionId);
  if (!found) throw new Error(`Expected workspace entry ${sessionId}.`);
  return found;
}
