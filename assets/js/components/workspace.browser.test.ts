import { flushSync, mount, unmount } from "svelte";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import WorkspaceView from "~components/workspace.svelte";
import { createWorkspace } from "~stores/workspace";
import type { WorkspaceSessionDescriptor } from "~types/workspace";

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => ({ destroy: vi.fn() })),
}));

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("Workspace Compact presentation", () => {
  it("uses a lower-right half-width by quarter-height region on wide viewports", async () => {
    renderCompactWorkspace([descriptor("session-a")]);

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
    renderCompactWorkspace([descriptor("session-a"), descriptor("session-b")]);

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

function renderCompactWorkspace(descriptors: WorkspaceSessionDescriptor[]) {
  const workspace = createWorkspace({ discovery: false });
  const target = document.createElement("div");
  document.body.append(target);
  const component = mount(WorkspaceView, { target, props: { workspace } });

  workspace.reconcile(descriptors);
  workspace.compact(descriptors[0].id);
  flushSync();

  cleanup = async () => {
    await unmount(component);
    workspace.dispose();
    target.remove();
  };
}

function descriptor(id: string): WorkspaceSessionDescriptor {
  return {
    id,
    slug: "qwinto",
    module: {
      embedUrl: "about:blank",
      allowedOrigins: ["null"],
      sandbox: [],
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token: `token-${id}`,
    },
  };
}
