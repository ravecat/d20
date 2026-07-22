import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { type Writable, writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Session from "~components/session.svelte";
import type { Session as SessionProjection } from "~types/game";
import type { ModuleConnection, ModuleEntry } from "~types/module";

type SessionState = {
  value?: SessionProjection;
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
let fullscreenElement: Element | null = null;

const showDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = true;
});
const showModalDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = true;
});
const closeDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = false;
});
const requestFullscreen = vi.fn(async function (this: Element) {
  fullscreenElement = this;
  this.ownerDocument.dispatchEvent(new Event("fullscreenchange"));
});
const exitFullscreen = vi.fn(async function (this: Document) {
  fullscreenElement = null;
  this.dispatchEvent(new Event("fullscreenchange"));
});

beforeEach(() => {
  Object.defineProperties(HTMLDialogElement.prototype, {
    show: { configurable: true, value: showDialog },
    showModal: { configurable: true, value: showModalDialog },
    close: { configurable: true, value: closeDialog },
  });
  Object.defineProperty(Element.prototype, "requestFullscreen", {
    configurable: true,
    value: requestFullscreen,
  });
  Object.defineProperties(Document.prototype, {
    fullscreenElement: { configurable: true, get: () => fullscreenElement },
    exitFullscreen: { configurable: true, value: exitFullscreen },
  });
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  sessionMock.createSession.mockClear();
  sessionMock.start.mockClear();
  vi.mocked(exposeModule).mockClear();
  fullscreenElement = null;
  showDialog.mockClear();
  showModalDialog.mockClear();
  closeDialog.mockClear();
  requestFullscreen.mockClear();
  exitFullscreen.mockClear();
});

describe("Session", () => {
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

  it("starts sessions without projected attrs", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    document.querySelector("button")?.click();
    flushSync();

    expect(sessionMock.start).toHaveBeenCalledWith({});
  });

  it("submits projected attrs through the same start action", () => {
    renderPanel({
      value: {
        ...sessionWithPhase("waiting_for_players"),
        attrs: projectedAttrs(),
      },
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const seat1 = selectByLabel("Seat 1");
    const seat4 = selectByLabel("Seat 4");

    expect(seat1.value).toBe("ada");
    expect(seat4.value).toBe("margaret");

    seat1.value = "margaret";
    seat1.dispatchEvent(new Event("change", { bubbles: true }));

    expect(seat4.value).toBe("ada");

    document.querySelector("button")?.click();
    flushSync();

    expect(sessionMock.start).toHaveBeenCalledWith({
      turn_order: ["margaret", "grace", "katherine", "ada"],
    });
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

  it("configures native theater light dismiss and preserves the game across modes", () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const dialog = document.getElementsByTagName("dialog")[0];
    const iframe = document.querySelector('iframe[title="Game module"]');

    if (!dialog || !iframe) {
      throw new Error("Expected the theater dialog and game module frame.");
    }

    expect(showModalDialog).toHaveBeenCalledOnce();
    expect(dialog.getAttribute("aria-label")).toBe("test-game");
    expect(dialog.getAttribute("closedby")).toBe("any");
    expect(buttonByName("Compact game view")).toBeDefined();

    buttonByName("Compact game view").click();
    flushSync();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(dialog.hasAttribute("closedby")).toBe(false);
    expect(buttonByName("Theater game view")).toBeDefined();
    expect(document.querySelector('iframe[title="Game module"]')).toBe(iframe);
    expect(exposeModule).toHaveBeenCalledOnce();

    buttonByName("Theater game view").click();
    flushSync();

    expect(showModalDialog).toHaveBeenCalledTimes(2);
    expect(dialog.getAttribute("closedby")).toBe("any");
    expect(document.querySelector('iframe[title="Game module"]')).toBe(iframe);
    expect(exposeModule).toHaveBeenCalledOnce();
  });

  it("minimizes from a native close request without remounting the game", () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const dialog = document.getElementsByTagName("dialog")[0];
    const iframe = document.querySelector('iframe[title="Game module"]');

    if (!dialog || !iframe) {
      throw new Error("Expected the theater dialog and game module frame.");
    }

    const cancel = new Event("cancel", { cancelable: true });
    dialog.dispatchEvent(cancel);
    flushSync();

    expect(cancel.defaultPrevented).toBe(true);
    expect(showDialog).toHaveBeenCalledOnce();
    expect(dialog.hasAttribute("closedby")).toBe(false);
    expect(buttonByName("Theater game view")).toBeDefined();
    expect(document.querySelector('iframe[title="Game module"]')).toBe(iframe);
    expect(exposeModule).toHaveBeenCalledOnce();
  });

  it("enters and exits fullscreen without remounting the game", async () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const iframe = document.querySelector('iframe[title="Game module"]');

    if (!iframe) throw new Error("Expected the game module frame.");

    buttonByName("Enter fullscreen").click();

    await vi.waitFor(() => {
      expect(requestFullscreen).toHaveBeenCalledOnce();
      expect(buttonByName("Exit fullscreen")).toBeDefined();
    });

    buttonByName("Exit fullscreen").click();

    await vi.waitFor(() => {
      expect(exitFullscreen).toHaveBeenCalledOnce();
      expect(buttonByName("Enter fullscreen")).toBeDefined();
    });

    expect(document.querySelector('iframe[title="Game module"]')).toBe(iframe);
    expect(exposeModule).toHaveBeenCalledOnce();
  });

  it("synchronizes a browser-driven fullscreen exit", async () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    buttonByName("Enter fullscreen").click();

    await vi.waitFor(() => {
      expect(buttonByName("Exit fullscreen")).toBeDefined();
    });

    const dialog = document.getElementsByTagName("dialog")[0];

    if (!dialog) throw new Error("Expected the theater dialog.");

    dialog.dispatchEvent(new Event("cancel", { cancelable: true }));
    flushSync();

    expect(showDialog).not.toHaveBeenCalled();

    fullscreenElement = null;
    document.dispatchEvent(new Event("fullscreenchange"));

    await vi.waitFor(() => {
      expect(buttonByName("Enter fullscreen")).toBeDefined();
      expect(buttonByName("Compact game view")).toBeDefined();
    });

    expect(exitFullscreen).not.toHaveBeenCalled();
  });

  it("ignores unavailable fullscreen at the request boundary", async () => {
    Object.defineProperty(Element.prototype, "requestFullscreen", {
      configurable: true,
      value: undefined,
    });

    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    const fullscreenButton = buttonByName("Enter fullscreen");

    expect(fullscreenButton.disabled).toBe(false);
    fullscreenButton.click();

    await vi.waitFor(() => {
      expect(buttonByName("Enter fullscreen")).toBeDefined();
    });

    expect(requestFullscreen).not.toHaveBeenCalled();
    expect(buttonByName("Compact game view")).toBeDefined();
    expect(document.querySelector('[role="status"]')).toBeNull();
  });

  it("ignores a rejected fullscreen request without changing display mode", async () => {
    requestFullscreen.mockRejectedValueOnce(new TypeError("Fullscreen denied"));

    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "connected",
      processing: { start: false },
      timeouts: { start: false },
      errors: {},
    });

    buttonByName("Enter fullscreen").click();

    await vi.waitFor(() => {
      expect(requestFullscreen).toHaveBeenCalledOnce();
    });

    expect(buttonByName("Compact game view")).toBeDefined();
    expect(buttonByName("Enter fullscreen")).toBeDefined();
    expect(document.querySelector('[role="status"]')).toBeNull();
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

  const component = mount(Session, {
    target,
    props: {
      moduleId: "test-game",
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
  phase: SessionProjection["phase"],
  permissions: SessionProjection["permissions"] = { can_start_game: true },
): SessionProjection {
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

function projectedAttrs() {
  const players = ["ada", "grace", "katherine", "margaret"];

  return Object.fromEntries(
    players.map((player, index) => [
      `turn_order_${index}`,
      {
        id: `turn_order_${index}`,
        name: `turn_order[${index}]`,
        type: "enum",
        label: `Seat ${index + 1}`,
        position: index,
        unique: true,
        value: player,
        required: true,
        values: players,
        errors: [],
      },
    ]),
  );
}

function selectByLabel(label: string) {
  const select = [...document.getElementsByTagName("select")].find((candidate) =>
    [...candidate.labels].some((element) => element.textContent?.trim().startsWith(label)),
  );

  if (!select) {
    throw new Error(`Expected select labelled ${label}.`);
  }

  return select;
}

function buttonByName(name: string) {
  const button = [...document.getElementsByTagName("button")].find(
    (candidate) => candidate.getAttribute("aria-label") === name,
  );

  if (!button) throw new Error(`Expected button named ${name}.`);

  return button;
}
