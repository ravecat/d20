import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Workspace as WorkspaceView } from "~/widgets/workspace";
import type {
  Workspace,
  WorkspaceChannelState,
  WorkspaceSession,
  WorkspaceSessionDescriptor,
} from "~/widgets/workspace/model/workspace";

const workspaceStoreMock = vi.hoisted(() => ({
  createWorkspace: vi.fn(),
}));

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => ({ destroy: vi.fn() })),
}));

vi.mock("~/widgets/workspace/model/workspace", () => ({
  createWorkspace: workspaceStoreMock.createWorkspace,
}));

const { createWorkspace } = await vi.importActual<
  typeof import("~/widgets/workspace/model/workspace")
>("~/widgets/workspace/model/workspace");

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
  workspaceStoreMock.createWorkspace.mockReset();
});

describe("Workspace presentation", () => {
  it("keeps one iframe and bridge while switching expanded, compact, and fullscreen", async () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([descriptor("session-a")]);
    flushSync();

    const iframe = gameFrame();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();
    expect(windowControls("Qwinto session session-a")).toEqual([
      "Close Qwinto session session-a",
      "Compact Qwinto session session-a",
      "Enter Qwinto session session-a fullscreen",
    ]);

    button("Compact Qwinto session session-a").click();
    flushSync();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(gameFrame()).toBe(iframe);
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();
    expect(windowControls("Qwinto session session-a")).toEqual([
      "Close Qwinto session session-a",
      "Expand Qwinto session session-a",
      "Enter Qwinto session session-a fullscreen",
    ]);

    button("Expand Qwinto session session-a").click();
    flushSync();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(gameFrame()).toBe(iframe);

    button("Enter Qwinto session session-a fullscreen").click();
    await vi.waitFor(() => expect(requestFullscreen).toHaveBeenCalledOnce());
    expect(windowControls("Qwinto session session-a")).toEqual([
      "Close Qwinto session session-a",
      "Exit Qwinto session session-a fullscreen",
    ]);
    button("Exit Qwinto session session-a fullscreen").click();
    await vi.waitFor(() => expect(exitFullscreen).toHaveBeenCalledOnce());
    await vi.waitFor(() =>
      expect(windowControls("Qwinto session session-a")).toEqual([
        "Close Qwinto session session-a",
        "Compact Qwinto session session-a",
        "Enter Qwinto session session-a fullscreen",
      ]),
    );

    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    flushSync();

    expect(showDialog).toHaveBeenCalledOnce();
    expect(gameFrame()).toBe(iframe);
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();
    expect(windowControls("Qwinto session session-a")).toContain("Expand Qwinto session session-a");
  });

  it("renders active windows without a duplicate workspace session panel", () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([descriptor("session-a"), descriptor("session-b", "koala-rescue-club")]);
    flushSync();

    expect(document.querySelector('[aria-label="Workspace sessions"]')).toBeNull();
    expect(document.querySelectorAll("dialog")).toHaveLength(2);
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(2);
    expect(windowControls("Qwinto session session-a")).toContain("Close Qwinto session session-a");
    expect(windowControls("Koala Rescue Club session session-b")).toContain(
      "Close Koala Rescue Club session session-b",
    );

    button("Close Qwinto session session-a").click();

    expect(harness.close).toHaveBeenCalledWith("session-a");
    expect(document.querySelectorAll("dialog")).toHaveLength(2);
  });

  it("expands the first remaining session when requested focus disappears", () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([descriptor("session-a"), descriptor("session-b")]);
    harness.workspace.focus("session-b");
    harness.ready([descriptor("session-a"), descriptor("session-c")]);
    flushSync();

    expect(windowControls("Qwinto session session-a")).toContain(
      "Compact Qwinto session session-a",
    );
    expect(windowControls("Qwinto session session-c")).toContain("Expand Qwinto session session-c");
  });

  it("isolates stale transport state while every compact window remains reachable", () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([
      descriptor("session-a"),
      descriptor("session-b", "koala-rescue-club"),
      descriptor("session-c"),
    ]);
    harness.stale();
    harness.workspace.focus("session-c");
    flushSync();

    expect(document.body.textContent).toContain("Reconnecting to Koala Rescue Club");
    expect(document.querySelectorAll('iframe[title="Game module"]')).toHaveLength(3);
    expect(windowControls("Qwinto session session-a")).toContain("Expand Qwinto session session-a");
    expect(windowControls("Koala Rescue Club session session-b")).toContain(
      "Expand Koala Rescue Club session session-b",
    );
    expect(windowControls("Qwinto session session-c")).toContain(
      "Compact Qwinto session session-c",
    );

    const expand = button("Expand Qwinto session session-a");
    expand.focus();
    expect(document.activeElement).toBe(expand);
  });
});

function workspaceHarness() {
  const state = writable<WorkspaceChannelState>(channelState("loading", null));
  const close = vi.fn();
  const session: WorkspaceSession = {
    subscribe: state.subscribe,
    detach: vi.fn(),
    close,
  };
  const workspace = createWorkspace({ session });

  return {
    workspace,
    close,
    ready(sessions: WorkspaceSessionDescriptor[]) {
      state.set(channelState("ready", { sessions }));
    },
    stale() {
      state.update((current) => ({ ...current, status: "stale" }));
    },
  };
}

function channelState(
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

function descriptor(id: string, slug = "qwinto"): WorkspaceSessionDescriptor {
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
      token: `token-${id}`,
    },
  };
}

function renderWorkspace(workspace: ReturnType<typeof createWorkspace>) {
  workspaceStoreMock.createWorkspace.mockReturnValue(workspace);
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
