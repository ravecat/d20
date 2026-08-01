import { get, writable } from "svelte/store";
import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  createWorkspace,
  type Workspace,
  type WorkspaceSessionDescriptor,
  type WorkspaceState,
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

  it("expands the first session from initial and replacement snapshots in Auto", () => {
    const discovery = discoveryHarness();

    discovery.ready([descriptor("session-a", "qwinto"), descriptor("session-b", "qwinto")]);

    expect(
      get(discovery.workspace).sessions.map(({ id, slug, phase }) => ({ id, slug, phase })),
    ).toEqual([
      { id: "session-a", slug: "qwinto", phase: "in_progress" },
      { id: "session-b", slug: "qwinto", phase: "in_progress" },
    ]);
    expect(get(discovery.workspace).layout).toEqual({ mode: "auto", id: "session-a" });
    expect(get(discovery.workspace)).not.toHaveProperty("expandedId");

    discovery.ready([
      descriptor("session-b", "qwinto", "fresh-token"),
      descriptor("session-c", "koala-rescue-club"),
    ]);

    expect(get(discovery.workspace).sessions.map(({ id }) => id)).toEqual([
      "session-b",
      "session-c",
    ]);
    expect(get(discovery.workspace).layout).toEqual({ mode: "auto", id: "session-b" });
    expect(session(discovery.workspace, "session-b").connection.token).toBe("fresh-token");
  });

  it("publishes exact focused and compact layouts", () => {
    const discovery = discoveryHarness();

    discovery.ready([descriptor("session-a"), descriptor("session-b")]);
    discovery.workspace.focus("session-b");

    expect(get(discovery.workspace).layout).toEqual({ mode: "focused", id: "session-b" });

    discovery.workspace.focus("missing-session");

    expect(get(discovery.workspace).layout).toEqual({
      mode: "focused",
      id: "missing-session",
    });

    discovery.workspace.compact();

    expect(get(discovery.workspace).layout).toEqual({ mode: "compact", id: undefined });

    discovery.ready([descriptor("session-b")]);

    expect(get(discovery.workspace).layout).toEqual({ mode: "compact", id: undefined });
  });

  it("retains exact focus while its session is absent and after it reappears", () => {
    const discovery = discoveryHarness();

    discovery.ready([descriptor("session-a"), descriptor("session-b")]);
    discovery.workspace.focus("session-b");
    discovery.ready([descriptor("session-a"), descriptor("session-c")]);

    expect(get(discovery.workspace).layout).toEqual({ mode: "focused", id: "session-b" });

    discovery.ready([descriptor("session-a"), descriptor("session-b"), descriptor("session-c")]);

    expect(get(discovery.workspace).layout).toEqual({ mode: "focused", id: "session-b" });
  });

  it("keeps windows stale during a transport outage and applies the reconnected workspace", () => {
    const discovery = discoveryHarness();

    discovery.ready([descriptor("session-a")]);
    discovery.stale();

    expect(get(discovery.workspace).sessions.map(({ id }) => id)).toEqual(["session-a"]);
    expect(get(discovery.workspace).status).toBe("stale");

    discovery.ready([]);

    expect(get(discovery.workspace).sessions).toEqual([]);
  });

  it("sends close through the workspace session and waits for workspace state before removing the window", () => {
    const discovery = discoveryHarness();

    discovery.ready([descriptor("session-a")]);
    discovery.workspace.close("session-a");
    discovery.workspace.close("missing-session");

    expect(mocks.call).toHaveBeenCalledWith("close", { id: "session-a" });
    expect(mocks.call).toHaveBeenCalledWith("close", { id: "missing-session" });
    expect(get(discovery.workspace).sessions.map(({ id }) => id)).toEqual(["session-a"]);

    discovery.ready([]);

    expect(get(discovery.workspace).sessions).toEqual([]);
  });
});

function discoveryHarness() {
  const state = writable(discoveryState("loading", null));
  mocks.subscribe.mockImplementation(state.subscribe);

  return {
    workspace: createWorkspace(),
    ready(sessions: WorkspaceSessionDescriptor[]) {
      state.set(discoveryState("ready", { sessions }));
    },
    stale() {
      state.update((current) => ({ ...current, status: "stale" }));
    },
  };
}

function discoveryState(status: WorkspaceState["status"], value: Workspace | null) {
  return {
    value,
    status,
    error: null,
    processing: {},
    errors: {},
    timeouts: {},
  };
}

type WorkspaceChannelState = ReturnType<typeof discoveryState>;

function descriptor(
  id: string,
  slug = "qwinto",
  token = `token-${id}`,
): WorkspaceSessionDescriptor {
  return {
    id,
    slug,
    phase: "in_progress",
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
        phase: "in_progress",
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

function session(workspace: ReturnType<typeof createWorkspace>, id: string) {
  const found = get(workspace).sessions.find((session) => session.id === id);
  if (!found) throw new Error(`Expected workspace session ${id}.`);
  return found;
}
