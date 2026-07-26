import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import WorkspaceView from "./workspace.svelte";
import { createWorkspace } from "~/shared/stores";
import type { WorkspaceChannel, WorkspaceCloseCall, WorkspaceCloseError } from "~/shared/stores";
import type { Workspace, WorkspaceChannelState, WorkspaceSessionDescriptor } from "~/shared/types";

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => ({ destroy: vi.fn() })),
}));

const showDialog = vi.fn(function (this: HTMLDialogElement) {
  this.open = true;
});
const showModalDialog = vi.fn(function (this: HTMLDialogElement) {
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
  fullscreenElement = null;
  showDialog.mockClear();
  showModalDialog.mockClear();
  closeDialog.mockClear();
  requestFullscreen.mockClear();
  exitFullscreen.mockClear();
  vi.mocked(exposeModule).mockClear();
});

describe("Workspace presentation", () => {
  it("keeps one iframe and bridge while switching Theater, Compact, and fullscreen", async () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([descriptor("session-a")]);
    flushSync();

    const iframe = gameFrame();
    const dialog = gameDialog("Qwinto session session-a");

    expect(showModalDialog).toHaveBeenCalledOnce();
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

    expect(showModalDialog).toHaveBeenCalledTimes(2);
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

    dialog.dispatchEvent(new Event("cancel", { cancelable: true }));
    flushSync();

    expect(showDialog).toHaveBeenCalledTimes(2);
    expect(gameFrame()).toBe(iframe);
    expect(vi.mocked(exposeModule)).toHaveBeenCalledOnce();
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

  it("keeps a failed close retryable without removing the window", () => {
    const harness = workspaceHarness();
    renderWorkspace(harness.workspace);
    harness.ready([descriptor("session-a")]);
    flushSync();

    button("Close Qwinto session session-a").click();
    harness.latestClose().reply("error", { reason: "Could not close" });
    flushSync();

    expect(document.body.textContent).toContain("Could not close");
    button("Try again").click();
    expect(harness.close).toHaveBeenCalledTimes(2);
    expect(document.querySelectorAll("dialog")).toHaveLength(1);
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
    expect(document.querySelectorAll("dialog.dialog--compact")).toHaveLength(2);

    const expand = button("Expand Qwinto session session-a");
    expand.focus();
    expect(document.activeElement).toBe(expand);
  });
});

function workspaceHarness() {
  const state = writable<WorkspaceChannelState>(channelState("loading", null));
  const requests: CloseRequest[] = [];
  const close = vi.fn((_sessionId: string) => {
    const request = new CloseRequest();
    requests.push(request);
    return request;
  });
  const discovery: WorkspaceChannel = {
    subscribe: state.subscribe,
    dispose: vi.fn(),
    close,
  };
  const workspace = createWorkspace({ discovery });

  return {
    workspace,
    close,
    latestClose() {
      const request = requests.at(-1);
      if (!request) throw new Error("Expected a close request.");
      return request;
    },
    ready(sessions: WorkspaceSessionDescriptor[]) {
      state.set(channelState("ready", { sessions }));
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
      embedUrl: `https://module.example.test/${id}`,
      allowedOrigins: ["https://module.example.test"],
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
  const target = document.createElement("div");
  document.body.append(target);
  const component = mount(WorkspaceView, { target, props: { workspace } });
  flushSync();

  cleanup = async () => {
    await unmount(component);
    workspace.dispose();
    target.remove();
  };
}

function gameFrame() {
  const iframe = document.querySelector('iframe[title="Game module"]');
  if (!(iframe instanceof HTMLIFrameElement)) throw new Error("Expected a game module frame.");
  return iframe;
}

function gameDialog(name: string) {
  const dialog = [...document.getElementsByTagName("dialog")].find(
    (candidate) => candidate.getAttribute("aria-label") === name,
  );
  if (!dialog) throw new Error(`Expected dialog named ${name}.`);
  return dialog;
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
