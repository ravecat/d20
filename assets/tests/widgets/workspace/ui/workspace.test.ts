import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Workspace as WorkspaceView } from "~/widgets/workspace";
import type {
  Workspace,
  WorkspaceSessionDescriptor,
  WorkspaceState,
} from "~/widgets/workspace/model/workspace";

const qwintoId = "game_01h45yhtgqfhxbcrsfbhxdsdvy";
const koalaId = "game_01h45y0sxkfmntta78gqs1vsw6";

const transport = vi.hoisted(() => ({
  call: vi.fn(),
  session: vi.fn(),
}));

const bridge = vi.hoisted(() => ({
  destroy: vi.fn(),
}));

interface WorkspaceSessionConfig {
  events: {
    snapshot(previous: Workspace | null, workspace: Workspace): Workspace;
  };
}

let sessionConfigs: WorkspaceSessionConfig[] = [];

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => bridge),
}));

vi.mock("phoenix-session", () => ({
  session: transport.session,
}));

const showDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = true;
});
const closeDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = false;
  queueMicrotask(() => this.dispatchEvent(new Event("close")));
});

let cleanup: (() => Promise<void>) | undefined;
let fullscreenElement: Element | null = null;
const requestFullscreen = vi.fn(async function (this: Element) {
  fullscreenElement = this;
  this.ownerDocument.dispatchEvent(new Event("fullscreenchange"));
});
const exitFullscreen = vi.fn(async function (this: Document) {
  fullscreenElement = null;
  this.dispatchEvent(new Event("fullscreenchange"));
});

beforeEach(() => {
  transport.call.mockReset();
  transport.session.mockReset();
  bridge.destroy.mockReset();
  sessionConfigs = [];
  Object.defineProperties(HTMLDialogElement.prototype, {
    show: { configurable: true, value: showDialog },
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
  fullscreenElement = null;
  showDialog.mockClear();
  closeDialog.mockClear();
  requestFullscreen.mockClear();
  exitFullscreen.mockClear();
  vi.mocked(exposeModule).mockClear();
});

describe("Workspace presentation", () => {
  it("keeps one iframe and bridge while switching Compact, Theater, and fullscreen", async () => {
    const harness = workspaceHarness();
    renderWorkspace();
    harness.ready([descriptor("session-a")]);
    flushSync();

    const iframe = gameFrame();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();
    expect(windowControls("Game session session-a")).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);
    expect(iframe.parentElement?.inert).toBe(false);

    button("Enter Game session session-a fullscreen").click();
    await vi.waitFor(() => expect(requestFullscreen).toHaveBeenCalledOnce());

    expect(gameFrame()).toBe(iframe);
    expect(iframe.parentElement?.inert).toBe(false);
    expect(findCompactRestore("session-a")).toBeUndefined();
    expect(windowControls("Game session session-a")).toEqual([
      "Close Game session session-a",
      "Exit Game session session-a fullscreen",
    ]);

    button("Exit Game session session-a fullscreen").click();
    await vi.waitFor(() => expect(exitFullscreen).toHaveBeenCalledOnce());
    await vi.waitFor(() =>
      expect(windowControls("Game session session-a")).toEqual([
        "Close Game session session-a",
        "Enter Game session session-a fullscreen",
        "Compact Game session session-a",
      ]),
    );

    expect(gameFrame()).toBe(iframe);
    expect(iframe.parentElement?.inert).toBe(false);
    expect(findCompactRestore("session-a")).toBeUndefined();

    button("Compact Game session session-a").click();
    flushSync();

    expect(iframe.parentElement?.inert).toBe(true);
    expect(findCompactRestore("session-a")).toBeInstanceOf(HTMLButtonElement);

    button("Expand Game session session-a").click();
    flushSync();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(gameFrame()).toBe(iframe);
    expect(iframe.parentElement?.inert).toBe(false);
    expect(windowControls("Game session session-a")).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);

    button("Enter Game session session-a fullscreen").click();
    await vi.waitFor(() => expect(requestFullscreen).toHaveBeenCalledTimes(2));
    expect(windowControls("Game session session-a")).toEqual([
      "Close Game session session-a",
      "Exit Game session session-a fullscreen",
    ]);
    button("Exit Game session session-a fullscreen").click();
    await vi.waitFor(() => expect(exitFullscreen).toHaveBeenCalledTimes(2));
    await vi.waitFor(() =>
      expect(windowControls("Game session session-a")).toEqual([
        "Close Game session session-a",
        "Enter Game session session-a fullscreen",
        "Compact Game session session-a",
      ]),
    );

    expect(showDialog).toHaveBeenCalledOnce();
    expect(gameFrame()).toBe(iframe);
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();

    button("Compact Game session session-a").click();
    flushSync();

    expect(gameFrame()).toBe(iframe);
    expect(iframe.parentElement?.inert).toBe(true);
    expect(findCompactRestore("session-a")).toBeDefined();
  });

  it("closes one active window and destroys its frame after the replacement snapshot", () => {
    const harness = workspaceHarness();
    renderWorkspace();
    harness.ready([descriptor("session-a"), descriptor("session-b", koalaId)]);
    flushSync();

    expect(document.querySelector('[aria-label="Workspace sessions"]')).toBeNull();
    expect(document.querySelectorAll("dialog")).toHaveLength(2);
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(2);
    expect(windowControls("Game session session-a")).toContain("Close Game session session-a");
    expect(windowControls("Game session session-b")).toContain("Close Game session session-b");

    button("Close Game session session-a").click();
    flushSync();

    expect(transport.call).toHaveBeenCalledWith("close_session", { id: "session-a" });
    expect(document.querySelectorAll("dialog")).toHaveLength(2);
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(2);
    expect(bridge.destroy).not.toHaveBeenCalled();

    harness.ready([descriptor("session-b", koalaId)]);
    flushSync();

    expect(document.querySelectorAll("dialog")).toHaveLength(1);
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(1);
    expect(findButton("Close Game session session-a")).toBeUndefined();
    expect(findButton("Compact Game session session-b")).toBeDefined();
    expect(bridge.destroy).toHaveBeenCalledOnce();
  });

  it("expands the first authoritative session while layout remains Auto", () => {
    const harness = workspaceHarness();
    renderWorkspace();
    harness.ready([descriptor("session-a"), descriptor("session-b")]);
    flushSync();

    expect(findButton("Compact Game session session-a")).toBeDefined();
    expect(findButton("Expand Game session session-b")).toBeDefined();

    harness.ready([descriptor("session-c"), descriptor("session-b")]);
    flushSync();

    expect(findButton("Compact Game session session-c")).toBeDefined();
    expect(findButton("Expand Game session session-b")).toBeDefined();
  });

  it("keeps exact focus when its session disappears and restores it when the session returns", () => {
    const harness = workspaceHarness();
    renderWorkspace();
    harness.ready([descriptor("session-a"), descriptor("session-b")]);
    flushSync();

    button("Expand Game session session-b").click();
    flushSync();

    harness.ready([descriptor("session-a"), descriptor("session-c")]);
    flushSync();

    expect(findButton("Expand Game session session-a")).toBeDefined();
    expect(findButton("Expand Game session session-c")).toBeDefined();

    harness.ready([descriptor("session-a"), descriptor("session-b"), descriptor("session-c")]);
    flushSync();

    expect(findButton("Expand Game session session-a")).toBeDefined();
    expect(findButton("Compact Game session session-b")).toBeDefined();
    expect(findButton("Expand Game session session-c")).toBeDefined();
  });

  it("renders generic transport status messages while every compact window remains reachable", () => {
    const harness = workspaceHarness();
    renderWorkspace();
    const sessions = [
      descriptor("session-a"),
      descriptor("session-b", koalaId),
      descriptor("session-c"),
    ];
    harness.loading(sessions);
    flushSync();

    expect(document.body.textContent).toContain("Connecting to game");
    expect(document.body.textContent).not.toContain("Connecting to Qwinto");

    harness.stale();
    flushSync();
    button("Compact Game session session-a").click();
    flushSync();
    button("Expand Game session session-c").click();
    flushSync();

    expect(document.body.textContent).toContain("Reconnecting to game");
    expect(document.body.textContent).not.toContain("Reconnecting to Koala Rescue Club");
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(3);
    expect(findButton("Expand Game session session-a")).toBeDefined();
    expect(findButton("Expand Game session session-b")).toBeDefined();
    expect(findButton("Compact Game session session-c")).toBeDefined();

    harness.failed();
    flushSync();

    expect(document.body.textContent).toContain("Connection to game failed");
    expect(document.body.textContent).not.toContain("Connection to Qwinto failed");

    const expand = button("Expand Game session session-a");
    expand.focus();
    expect(document.activeElement).toBe(expand);
  });

  it("maps authoritative phase and shared transport state to compact statuses", () => {
    const harness = workspaceHarness();
    renderWorkspace();
    harness.ready([descriptor("session-a"), descriptor("session-b", qwintoId, "finished")]);
    flushSync();

    button("Compact Game session session-a").click();
    flushSync();

    expect(compactStatus("session-a").textContent).toContain("Live");
    expect(compactStatus("session-b").textContent).toContain("Finished");

    harness.stale();
    flushSync();

    expect(compactStatus("session-a").textContent).toContain("Reconnecting");
    expect(compactStatus("session-b").textContent).toContain("Reconnecting");
    expect(document.body.textContent).not.toContain("Live");
    expect(document.body.textContent).not.toContain("Finished");

    harness.failed();
    flushSync();

    expect(compactStatus("session-a").textContent).toContain("Failed");
    expect(compactStatus("session-b").textContent).toContain("Failed");
  });

  it("starts a remounted workspace in Auto independently of the previous selection", async () => {
    const firstHarness = workspaceHarness();
    renderWorkspace();
    firstHarness.ready([descriptor("session-a")]);
    flushSync();

    expect(findButton("Compact Game session session-a")).toBeDefined();

    button("Compact Game session session-a").click();
    flushSync();

    expect(findButton("Expand Game session session-a")).toBeDefined();

    await cleanup?.();
    cleanup = undefined;

    const secondHarness = workspaceHarness();
    renderWorkspace();
    secondHarness.ready([descriptor("session-a")]);
    flushSync();

    expect(findButton("Compact Game session session-a")).toBeDefined();
    expect(findButton("Expand Game session session-a")).toBeUndefined();
  });

  it("releases the session subscription when the workspace unmounts", async () => {
    const harness = workspaceHarness();
    renderWorkspace();

    expect(harness.unsubscribe).not.toHaveBeenCalled();

    await cleanup?.();
    cleanup = undefined;

    expect(harness.unsubscribe).toHaveBeenCalledOnce();
  });
});

function workspaceHarness() {
  const state = writable(channelState("loading", null));
  const unsubscribe = vi.fn();
  const subscribe = vi.fn((run: (state: WorkspaceChannelState) => void) => {
    const stop = state.subscribe(run);

    return () => {
      stop();
      unsubscribe();
    };
  });
  const controller = {
    subscribe,
    extend(factory: (helpers: { call: typeof transport.call }) => object) {
      return { ...controller, ...factory({ call: transport.call }) };
    },
  };
  transport.session.mockImplementation((_socket: unknown, config: WorkspaceSessionConfig) => {
    sessionConfigs.push(config);
    return controller;
  });

  return {
    unsubscribe,
    ready(sessions: WorkspaceSessionDescriptor[]) {
      const config = workspaceConfig();

      state.update((current) => ({
        ...current,
        status: "ready",
        value: config.events.snapshot(current.value, { sessions }),
      }));
    },
    loading(sessions: WorkspaceSessionDescriptor[]) {
      state.set(channelState("loading", { sessions }));
    },
    stale() {
      state.update((current) => ({ ...current, status: "stale" }));
    },
    failed() {
      state.update((current) => ({ ...current, status: "failed" }));
    },
  };
}

function workspaceConfig() {
  const config = sessionConfigs[sessionConfigs.length - 1];
  if (!config) throw new Error("Expected a Workspace session configuration.");
  return config;
}

function channelState(status: WorkspaceState["status"], value: Workspace | null) {
  return {
    value,
    status,
    error: null,
    processing: {},
    errors: {},
    timeouts: {},
  };
}

type WorkspaceChannelState = ReturnType<typeof channelState>;

function descriptor(
  id: string,
  game_id = qwintoId,
  phase: WorkspaceSessionDescriptor["phase"] = "in_progress",
): WorkspaceSessionDescriptor {
  return {
    id,
    game_id,
    phase,
    module: {
      embed_url: `https://module.example.test/${id}`,
      allowed_origins: ["https://module.example.test"],
      sandbox: ["allow-scripts"],
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token: `token-${id}`,
    },
  };
}

function renderWorkspace() {
  const target = document.createElement("div");
  document.body.append(target);
  const component = mount(WorkspaceView, { target });
  flushSync();

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function gameFrame() {
  const iframe = document.querySelector('iframe[title="Game module"]');
  if (!(iframe instanceof HTMLIFrameElement)) throw new Error("Expected a game module frame.");
  return iframe;
}

function compactStatus(id: string) {
  const dialog = findDialog(id);
  const status = dialog?.querySelector(".workspace__compact-status");
  if (!(status instanceof HTMLElement)) throw new Error(`Expected compact status for ${id}.`);
  return status;
}

function findCompactRestore(id: string) {
  const restore = findDialog(id)?.querySelector(".workspace__compact-restore");
  return restore instanceof HTMLButtonElement ? restore : undefined;
}

function findDialog(id: string) {
  return [...document.getElementsByTagName("dialog")].find(
    (candidate) => candidate.getAttribute("aria-label") === `Game session ${id}`,
  );
}

function windowControlGroup(name: string) {
  const group = [...document.querySelectorAll('[role="group"]')].find(
    (candidate) => candidate.getAttribute("aria-label") === `${name} window controls`,
  );
  if (!(group instanceof HTMLElement)) throw new Error(`Expected controls for ${name}.`);
  return group;
}

function windowControls(name: string) {
  return [...windowControlGroup(name).getElementsByTagName("button")].map((control) =>
    control.getAttribute("aria-label"),
  );
}

function button(name: string) {
  const found = findButton(name);
  if (!found) throw new Error(`Expected button named ${name}.`);
  return found;
}

function findButton(name: string) {
  return [...document.getElementsByTagName("button")].find(
    (candidate) => candidate.getAttribute("aria-label") === name || candidate.textContent === name,
  );
}
