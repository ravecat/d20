import { get, writable } from "svelte/store";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  createWorkspace,
  type Workspace,
  type WorkspaceChannelState,
  type WorkspaceSession,
  type WorkspaceSessionDescriptor,
} from "~/widgets/workspace/model/workspace";

const mocks = vi.hoisted(() => ({
  call: vi.fn(),
  session: vi.fn(),
  subscribe: vi.fn(),
  socket: {},
}));

vi.mock("phoenix-session", () => ({
  session: mocks.session,
}));

vi.mock("~/shared/api", () => ({
  socket: mocks.socket,
}));

beforeEach(() => {
  mocks.call.mockReset();
  mocks.session.mockReset();
  mocks.subscribe.mockReset();
  mocks.subscribe.mockImplementation((listener: (state: WorkspaceChannelState) => void) => {
    listener(discoveryState("ready", workspaceSnapshot("fresh-token")));
    return vi.fn();
  });

  const controller = {
    subscribe: mocks.subscribe,
    extend(factory: (helpers: { call: typeof mocks.call }) => object) {
      return { ...controller, ...factory({ call: mocks.call }) };
    },
  };
  mocks.session.mockReturnValue(controller);
});

describe("Workspace", () => {
  it("joins the actor workspace and consumes complete wire snapshots without transformation", () => {
    const workspace = createWorkspace();
    const [_socket, config] = mocks.session.mock.calls[0] as [
      unknown,
      {
        topic: string;
        connect: {
          ok(previous: unknown, workspace: Workspace): unknown;
        };
        events: {
          snapshot(previous: unknown, workspace: Workspace): unknown;
        };
      },
    ];
    const snapshot = workspaceSnapshot("fresh-token");

    expect(config.topic).toBe("workspace");
    expect(config.connect.ok(null, snapshot)).toBe(snapshot);
    expect(config.events.snapshot(null, snapshot)).toBe(snapshot);
    workspace.close("session-a");

    expect(mocks.call).toHaveBeenCalledWith("close", { id: "session-a" });
  });

  it("reconciles authoritative workspace state by id without creating game session controllers", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ session: discovery.session });

    discovery.ready([descriptor("session-a", "qwinto"), descriptor("session-b", "qwinto")]);

    expect(get(workspace).sessions.map(({ id, slug }) => ({ id, slug }))).toEqual([
      { id: "session-a", slug: "qwinto" },
      { id: "session-b", slug: "qwinto" },
    ]);
    expect(get(workspace).layout).toEqual({ mode: "auto" });

    workspace.compact("session-a");
    discovery.ready([
      descriptor("session-b", "qwinto", "fresh-token"),
      descriptor("session-c", "koala-rescue-club"),
    ]);

    expect(get(workspace).sessions.map(({ id }) => id)).toEqual(["session-b", "session-c"]);
    expect(get(workspace).layout).toEqual({ mode: "compact" });
    expect(session(workspace, "session-b").connection.token).toBe("fresh-token");
  });

  it("changes layout only for visible workspace sessions", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ session: discovery.session });

    discovery.ready([descriptor("session-a"), descriptor("session-b")]);
    workspace.compact("session-a");
    workspace.focus("session-b");
    workspace.focus("missing-session");
    workspace.compact("session-a");

    expect(get(workspace).layout).toEqual({ mode: "focused", sessionId: "session-b" });
  });

  it("retains requested focus while allowing the visible fallback to compact", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ session: discovery.session });

    discovery.ready([descriptor("session-a"), descriptor("session-b")]);
    workspace.focus("session-b");
    discovery.ready([descriptor("session-a"), descriptor("session-c")]);

    expect(get(workspace).layout).toEqual({ mode: "focused", sessionId: "session-b" });

    workspace.compact("session-a");

    expect(get(workspace).layout).toEqual({ mode: "compact" });
  });

  it("keeps windows stale during a transport outage and applies the reconnected workspace", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ session: discovery.session });

    discovery.ready([descriptor("session-a")]);
    discovery.stale();

    expect(get(workspace).sessions.map(({ id }) => id)).toEqual(["session-a"]);
    expect(get(workspace).status).toBe("stale");

    discovery.ready([]);

    expect(get(workspace).sessions).toEqual([]);
  });

  it("sends close through the workspace session and waits for workspace state before removing the window", () => {
    const discovery = discoveryHarness();
    const workspace = createWorkspace({ session: discovery.session });

    discovery.ready([descriptor("session-a")]);
    workspace.close("session-a");

    expect(discovery.close).toHaveBeenCalledWith("session-a");
    expect(get(workspace).sessions.map(({ id }) => id)).toEqual(["session-a"]);

    discovery.ready([]);

    expect(get(workspace).sessions).toEqual([]);
  });
});

function discoveryHarness() {
  const state = writable<WorkspaceChannelState>(discoveryState("loading", null));
  const close = vi.fn();
  const session: WorkspaceSession = {
    subscribe: state.subscribe,
    close,
  };

  return {
    session,
    close,
    ready(sessions: WorkspaceSessionDescriptor[]) {
      state.set(discoveryState("ready", { sessions }));
    },
    stale() {
      state.update((current) => ({ ...current, status: "stale" }));
    },
  };
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
      embed_url: `https://module.example.test/${id}`,
      allowed_origins: ["https://module.example.test"],
      sandbox: ["allow-scripts"],
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token,
    },
  };
}

function workspaceSnapshot(token: string): Workspace {
  return {
    sessions: [
      {
        id: "session-a",
        slug: "qwinto",
        module: {
          embed_url: "https://qwinto.example.test/",
          allowed_origins: ["https://qwinto.example.test"],
          sandbox: ["allow-scripts"],
        },
        connection: {
          endpoint: "wss://example.test/module",
          topic: "session:session-a",
          token,
        },
      },
    ],
  };
}

function session(workspace: ReturnType<typeof createWorkspace>, sessionId: string) {
  const found = get(workspace).sessions.find((candidate) => candidate.id === sessionId);
  if (!found) throw new Error(`Expected workspace session ${sessionId}.`);
  return found;
}
