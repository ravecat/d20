import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import { Workspace as WorkspaceView } from "~/widgets/workspace";
import type { WorkspaceSessionDescriptor } from "~/widgets/workspace/model/workspace";

const transport = vi.hoisted(() => ({
  call: vi.fn(),
  session: vi.fn(),
}));

vi.mock("@rvct/d20sdk", () => ({
  module: vi.fn(() => ({ destroy: vi.fn() })),
}));

vi.mock("phoenix-session", () => ({
  session: transport.session,
}));

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  transport.call.mockReset();
  transport.session.mockReset();
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("Workspace presentation", () => {
  it("stacks the Theater window above every sibling and restores selection through Compact", async () => {
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const secondDialog = page.getByRole("dialog", { name: "Game session session-b" });

    await expect.element(firstDialog).toBeVisible();
    await expect.element(secondDialog).toBeVisible();

    const initialFirstBounds = firstDialog.element().getBoundingClientRect();
    const initialSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(initialFirstBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(initialFirstBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(initialSecondBounds.width).toBeLessThan(initialFirstBounds.width);
    expect(initialSecondBounds.height).toBeLessThan(initialFirstBounds.height);
    expect(
      firstDialog
        .element()
        .contains(
          document.elementFromPoint(
            initialSecondBounds.left + initialSecondBounds.width / 2,
            initialSecondBounds.top + initialSecondBounds.height / 2,
          ),
        ),
    ).toBe(true);

    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    await page.getByRole("button", { name: "Expand Game session session-b" }).click();
    flushSync();

    const selectedFirstBounds = firstDialog.element().getBoundingClientRect();
    const selectedSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(selectedSecondBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(selectedSecondBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(selectedFirstBounds.width).toBeLessThan(selectedSecondBounds.width);
    expect(
      secondDialog
        .element()
        .contains(
          document.elementFromPoint(
            selectedFirstBounds.left + selectedFirstBounds.width / 2,
            selectedFirstBounds.top + selectedFirstBounds.height / 2,
          ),
        ),
    ).toBe(true);
  });

  it("uses a lower-right half-width by quarter-height region on wide viewports", async () => {
    renderWorkspace([descriptor("session-a")]);
    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const region = page.getByRole("region", { name: "Open game sessions" });
    const dialog = page.getByRole("dialog", { name: "Game session session-a" });

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
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);
    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const region = page.getByRole("region", { name: "Open game sessions" });
    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const firstFrame = page.getByTitle("Game module").first();
    const controls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });
    const layoutControl = page.getByRole("button", {
      name: "Expand Game session session-a",
    });

    await expect.element(region).toBeVisible();
    await expect.element(firstDialog).toBeVisible();
    await expect.element(firstFrame).toBeVisible();
    await expect.element(controls).toBeInViewport();
    await expect.element(layoutControl).toBeInViewport();

    const regionBounds = region.element().getBoundingClientRect();

    expect(regionBounds.left).toBeCloseTo(12, 0);
    expect(regionBounds.right).toBeCloseTo(window.innerWidth - 12, 0);
    expect(regionBounds.bottom).toBeCloseTo(window.innerHeight - 12, 0);
    expect(document.documentElement.scrollWidth).toBeLessThanOrEqual(window.innerWidth);

    for (const button of controls.getByRole("button").elements()) {
      expect(button.getBoundingClientRect().right).toBeLessThanOrEqual(window.innerWidth);
      await expect.element(page.elementLocator(button)).toBeInViewport();
    }

    expect(layoutControl.element().getBoundingClientRect().right).toBeLessThanOrEqual(
      window.innerWidth,
    );
  });
});

function renderWorkspace(descriptors: WorkspaceSessionDescriptor[]) {
  const channelState = writable({
    value: { sessions: descriptors },
    status: "ready" as const,
    error: null,
    processing: {},
    errors: {},
    timeouts: {},
  });
  const controller = {
    subscribe: channelState.subscribe,
    extend(factory: (helpers: { call: typeof transport.call }) => object) {
      return { ...controller, ...factory({ call: transport.call }) };
    },
  };
  transport.session.mockReturnValue(controller);
  const target = document.createElement("div");
  document.body.append(target);
  const component = mount(WorkspaceView, { target });
  flushSync();

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
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
