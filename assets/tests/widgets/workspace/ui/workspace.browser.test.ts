import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import { Workspace as WorkspaceView } from "~/widgets/workspace";
import type {
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

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  workspaceStoreMock.createWorkspace.mockReset();
});

describe("Workspace presentation", () => {
  it("expands the selected window while keeping compact siblings reachable", async () => {
    const workspace = renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const firstDialog = page.getByRole("dialog", { name: "Qwinto session session-a" });
    const secondDialog = page.getByRole("dialog", { name: "Qwinto session session-b" });
    const expandSecond = page.getByRole("button", {
      name: "Expand Qwinto session session-b",
    });

    await expect.element(firstDialog).toBeVisible();
    await expect.element(secondDialog).toBeVisible();
    await expect.element(expandSecond).toBeInViewport();

    const initialFirstBounds = firstDialog.element().getBoundingClientRect();
    const initialSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(initialFirstBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(initialFirstBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(initialSecondBounds.width).toBeLessThan(initialFirstBounds.width);
    expect(initialSecondBounds.height).toBeLessThan(initialFirstBounds.height);

    workspace.focus("session-b");
    flushSync();

    const focusedFirstBounds = firstDialog.element().getBoundingClientRect();
    const focusedSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(focusedSecondBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(focusedSecondBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(focusedFirstBounds.width).toBeLessThan(focusedSecondBounds.width);
    await expect
      .element(page.getByRole("button", { name: "Expand Qwinto session session-a" }))
      .toBeInViewport();
  });

  it("uses a lower-right half-width by quarter-height region on wide viewports", async () => {
    const workspace = renderWorkspace([descriptor("session-a")]);
    workspace.compact("session-a");
    flushSync();

    const region = page.getByRole("region", { name: "Open game sessions" });
    const dialog = page.getByRole("dialog", { name: "Qwinto session session-a" });

    await expect.element(region).toBeVisible();
    await expect.element(dialog).toBeVisible();

    const regionBounds = region.element().getBoundingClientRect();
    const dialogBounds = dialog.element().getBoundingClientRect();

    expect(regionBounds.width).toBeCloseTo(window.innerWidth / 2, 0);
    expect(regionBounds.height).toBeCloseTo(window.innerHeight / 4, 0);
    expect(window.innerWidth - regionBounds.right).toBeCloseTo(12, 0);
    expect(window.innerHeight - regionBounds.bottom).toBeCloseTo(12, 0);
    expect(regionBounds.left).toBeGreaterThan(0);
    expect(dialogBounds.width).toBeCloseTo(regionBounds.width, 0);
    expect(dialogBounds.height).toBeCloseTo(regionBounds.height, 0);
  });

  it("keeps Compact content and vertical controls reachable without horizontal overflow", async () => {
    await page.viewport(390, 640);
    const workspace = renderWorkspace([descriptor("session-a"), descriptor("session-b")]);
    workspace.compact("session-a");
    flushSync();

    const region = page.getByRole("region", { name: "Open game sessions" });
    const firstDialog = page.getByRole("dialog", { name: "Qwinto session session-a" });
    const firstFrame = page.getByTitle("Game module").first();
    const controls = page.getByRole("group", {
      name: "Qwinto session session-a window controls",
    });

    await expect.element(region).toBeVisible();
    await expect.element(firstDialog).toBeVisible();
    await expect.element(firstFrame).toBeVisible();
    await expect.element(controls).toBeInViewport();

    const regionBounds = region.element().getBoundingClientRect();

    expect(regionBounds.left).toBeCloseTo(12, 0);
    expect(regionBounds.right).toBeCloseTo(window.innerWidth - 12, 0);
    expect(regionBounds.bottom).toBeCloseTo(window.innerHeight - 12, 0);
    expect(document.documentElement.scrollWidth).toBeLessThanOrEqual(window.innerWidth);

    for (const button of controls.getByRole("button").elements()) {
      expect(button.getBoundingClientRect().right).toBeLessThanOrEqual(window.innerWidth);
      await expect.element(page.elementLocator(button)).toBeInViewport();
    }
  });
});

function renderWorkspace(descriptors: WorkspaceSessionDescriptor[]) {
  const channelState = writable<WorkspaceChannelState>({
    value: { sessions: descriptors },
    status: "ready",
    error: null,
    processing: { close: false },
    errors: { close: null },
    timeouts: { close: false },
  });
  const session: WorkspaceSession = {
    subscribe: channelState.subscribe,
    detach() {},
    close() {},
  };
  const workspace = createWorkspace({ session });
  workspaceStoreMock.createWorkspace.mockReturnValue(workspace);
  const target = document.createElement("div");
  document.body.append(target);
  const component = mount(WorkspaceView, { target });
  flushSync();

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };

  return workspace;
}

function descriptor(id: string): WorkspaceSessionDescriptor {
  return {
    id,
    slug: "qwinto",
    module: {
      embed_url: "about:blank",
      allowed_origins: ["null"],
      sandbox: [],
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token: `token-${id}`,
    },
  };
}
