import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { type Writable, writable } from "svelte/store";
import { afterEach, describe, expect, it, vi } from "vitest";
import SessionPanel from "~components/session_panel.svelte";
import type { Session } from "~types/game";
import type { ModuleConnection, ModuleEntry } from "~types/module";

type SessionState = {
  value?: Session;
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
  const start = vi.fn();

  return {
    createSession: vi.fn((topic: string) => {
      if (!store) {
        throw new Error(`Session store was not prepared for ${topic}`);
      }

      return {
        subscribe: store.subscribe,
        start,
      };
    }),
    start,
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
  sessionMock.start.mockClear();
  vi.mocked(exposeModule).mockClear();
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
    expect(document.querySelector("button")?.hasAttribute("disabled")).toBe(false);
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });

  it("renders the start panel without a surrounding border", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const startButton = document.querySelector("button");
    const startPanel = startButton?.closest("section");

    expect(startButton?.textContent).toContain("Start");
    expect(startPanel?.className).not.toContain("border");
  });

  it("styles the start action as the primary full-width game action", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const startButton = document.querySelector("button");

    expect(startButton?.textContent).toContain("Start");
    expect(startButton?.className).toContain("session-panel-start__action");
  });

  it("starts the session without creation attrs", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    document.querySelector("button")?.click();
    flushSync();

    expect(sessionMock.start).toHaveBeenCalledWith();
  });

  it("disables start when permissions do not allow starting the game", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players", { can_start_game: false }),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const startButton = document.querySelector("button");

    expect(startButton?.textContent).toContain("Start");
    expect(startButton?.hasAttribute("disabled")).toBe(true);

    startButton?.click();
    flushSync();

    expect(sessionMock.start).not.toHaveBeenCalled();
  });

  it("renders joined players without media borders and allows two-line names", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const joinedPlayers = document.querySelector('ul[aria-label="Joined players"]');

    if (!joinedPlayers) {
      throw new Error("Expected joined players list to be rendered.");
    }

    const avatar = joinedPlayers.querySelector("img");
    const fallbackAvatar = joinedPlayers.querySelector('span[aria-hidden="true"]');
    const name = [...joinedPlayers.querySelectorAll("li > span:not([aria-hidden])")].find(
      (element) => element.textContent?.trim() === "Ada Lovelace",
    );

    if (!avatar || !fallbackAvatar || !name) {
      throw new Error("Expected joined player avatar, fallback avatar, and long name.");
    }

    expect(avatar.className).not.toContain("border");
    expect(fallbackAvatar.className).not.toContain("border");
    expect(name.className).toContain("session-panel-players__name");
  });

  it("omits unavailable presence copy when no members are visible", () => {
    renderPanel({
      value: { ...sessionWithPhase("waiting_for_players"), members: {} },
      status: "failed",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    expect(document.body.textContent).not.toContain("Presence unavailable");
    expect(document.querySelector('ul[aria-label="Joined players"]')).not.toBeNull();
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

  it("passes a cloneable bootstrap payload to the embedded module bridge", () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    expect(exposeModule).toHaveBeenCalledWith(
      expect.objectContaining({
        bootstrap: {
          endpoint: connection.endpoint,
          topic: connection.topic,
          token: connection.token,
        },
      }),
    );
    expect(vi.mocked(exposeModule).mock.calls[0]?.[0].bootstrap).not.toBe(connection);
  });

  it("keeps the module frame mounted after the session is finished", () => {
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
    expect(document.querySelector('iframe[title="Game module"]')).not.toBeNull();
  });

  it("does not mount the module frame before the session phase is available", () => {
    renderPanel({
      value: undefined,
      status: "loading",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

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

function sessionWithPhase(
  phase: Session["phase"],
  permissions: Session["permissions"] = { can_start_game: true },
): Session {
  return {
    id: `session-${phase}`,
    phase,
    owner_id: "player-1",
    members: {
      "player-1": {
        online_at: 1,
        display_name: "Ada Lovelace",
        avatar: "https://example.invalid/ada.png",
      },
      "player-2": {
        online_at: 2,
        display_name: "Grace",
        avatar: null,
      },
    },
    permissions,
    game: {},
  };
}
