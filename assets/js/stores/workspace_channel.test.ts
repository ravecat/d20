import { beforeEach, describe, expect, it, vi } from "vitest";
import { createWorkspaceChannel } from "~stores/workspace_channel";
import type { WorkspacePayload } from "~types/workspace";

const mocks = vi.hoisted(() => ({
  call: vi.fn(),
  detach: vi.fn(),
  session: vi.fn(),
  subscribe: vi.fn(),
  socket: {},
}));

vi.mock("phoenix-session", () => ({
  session: mocks.session,
}));

vi.mock("~/user_socket.js", () => ({
  default: mocks.socket,
}));

beforeEach(() => {
  mocks.detach.mockClear();
  mocks.call.mockReset();
  mocks.session.mockReset();
  mocks.subscribe.mockClear();
  const controller = {
    subscribe: mocks.subscribe,
    detach: mocks.detach,
    extend(factory: (helpers: { call: typeof mocks.call }) => object) {
      return { ...controller, ...factory({ call: mocks.call }) };
    },
  };
  mocks.session.mockReturnValue(controller);
});

describe("WorkspaceChannel", () => {
  it("joins the actor workspace and normalizes complete wire payloads", () => {
    const channel = createWorkspaceChannel();
    const [_socket, config] = mocks.session.mock.calls[0] as [
      unknown,
      {
        topic: string;
        connect: {
          ok(previous: unknown, payload: WorkspacePayload): unknown;
        };
        events: {
          snapshot(previous: unknown, payload: WorkspacePayload): unknown;
        };
      },
    ];
    const payload = workspacePayload("fresh-token");

    expect(config.topic).toBe("workspace");
    expect(config.connect.ok(null, payload)).toEqual({
      sessions: [
        {
          id: "session-a",
          slug: "qwinto",
          module: {
            embedUrl: "https://qwinto.example.test/",
            allowedOrigins: ["https://qwinto.example.test"],
            sandbox: ["allow-scripts"],
          },
          connection: {
            endpoint: "wss://example.test/module",
            topic: "session:session-a",
            token: "fresh-token",
          },
        },
      ],
    });
    expect(config.events.snapshot(null, payload)).toEqual(config.connect.ok(null, payload));

    const listener = vi.fn();
    const closeCall = {};
    mocks.call.mockReturnValue(closeCall);
    channel.subscribe(listener);
    expect(channel.close("session-a")).toBe(closeCall);
    channel.dispose();

    expect(mocks.subscribe).toHaveBeenCalledWith(listener);
    expect(mocks.call).toHaveBeenCalledWith("close", { id: "session-a" });
    expect(mocks.detach).toHaveBeenCalledOnce();
  });
});

function workspacePayload(token: string): WorkspacePayload {
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
