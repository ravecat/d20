import { flushSync, mount, unmount } from "svelte";
import { type Writable, writable } from "svelte/store";
import { afterEach, describe, expect, it, vi } from "vitest";
import SessionPanel from "~components/session_panel.svelte";
import type { Session } from "~types/game";
import type { ModuleConnection, ModuleEntry } from "~types/module";

type SessionState = {
  value: Session;
  status: "connected" | "failed" | "loading";
  processing: { start: boolean };
  timeouts: { start: boolean };
  errors: { start?: { reason?: string } };
};

const sessionMock = vi.hoisted(() => {
  let store:
    | {
        subscribe: Writable<SessionState>["subscribe"];
      }
    | undefined;

  return {
    createSession: vi.fn((topic: string) => {
      if (!store) {
        throw new Error(`Session store was not prepared for ${topic}`);
      }

      return {
        subscribe: store.subscribe,
        start: vi.fn(),
      };
    }),
    setStore(nextStore: { subscribe: Writable<SessionState>["subscribe"] }) {
      store = nextStore;
    },
  };
});

vi.mock("~stores/session", () => ({
  createSession: sessionMock.createSession,
}));

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => ({ destroy: vi.fn() })),
}));

const moduleEntry: ModuleEntry = {
  embedUrl: "https://module.example.test/game",
  allowedOrigins: ["https://module.example.test"],
  sandbox: ["allow-scripts"],
};

const connection: ModuleConnection = {
  endpoint: "wss://module.example.test/socket",
  topic: "session:test",
  token: "token",
};

let cleanup: (() => Promise<void>) | undefined;

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  sessionMock.createSession.mockClear();
});

describe("SessionPanel", () => {
  it("shows active members while waiting for players", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    expect(document.body.textContent).toContain("Start");
    expect(document.body.textContent).toContain("Ada");
    expect(document.body.textContent).toContain("Grace");
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });

  it("hides active members once the session is in progress", () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    expect(document.body.textContent).not.toContain("Start");
    expect(document.body.textContent).not.toContain("Ada");
    expect(document.body.textContent).not.toContain("Grace");
    expect(document.querySelector('iframe[title="Game module"]')).not.toBeNull();
  });

  it("does not show active members after the session is finished", () => {
    renderPanel({
      value: sessionWithPhase("finished"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    expect(document.body.textContent).not.toContain("Start");
    expect(document.body.textContent).not.toContain("Ada");
    expect(document.body.textContent).not.toContain("Grace");
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });
});

function renderPanel(state: SessionState) {
  const target = document.createElement("div");
  const store = writable(state);

  document.body.append(target);
  sessionMock.setStore(store);

  const component = mount(SessionPanel, {
    target,
    props: {
      module: moduleEntry,
      connection,
    },
  });

  flushSync();
  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function sessionWithPhase(phase: Session["phase"]): Session {
  return {
    id: `session-${phase}`,
    phase,
    owner_id: "player-1",
    members: {
      "player-1": {
        online_at: 1,
        display_name: "Ada",
        avatar: null,
      },
      "player-2": {
        online_at: 2,
        display_name: "Grace",
        avatar: null,
      },
    },
    game: {},
  };
}
