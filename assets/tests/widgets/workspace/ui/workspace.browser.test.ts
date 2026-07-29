import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import { Workspace as WorkspaceView } from "~/widgets/workspace";
import type {
  WorkspaceSessionDescriptor,
  WorkspaceState,
} from "~/widgets/workspace/model/workspace";

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
  document.documentElement.style.setProperty("--color-base-content", "rgb(255 255 255)");
  document.documentElement.style.setProperty("--color-success", "rgb(0 200 80)");
  document.documentElement.style.setProperty("--color-warning", "rgb(255 193 7)");
  document.documentElement.style.setProperty("--color-error", "rgb(220 38 38)");
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.documentElement.style.removeProperty("--color-base-content");
  document.documentElement.style.removeProperty("--color-success");
  document.documentElement.style.removeProperty("--color-warning");
  document.documentElement.style.removeProperty("--color-error");
  document.body.innerHTML = "";
});

describe("Workspace presentation", () => {
  it("starts Compact, stacks the Theater window above siblings, and restores selection", async () => {
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const secondDialog = page.getByRole("dialog", { name: "Game session session-b" });
    const firstControls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });

    await expect.element(firstDialog).toBeVisible();
    await expect.element(secondDialog).toBeVisible();

    const firstControlButtons = firstControls.getByRole("button").elements();
    expect(firstControlButtons.map((button) => button.getAttribute("aria-label"))).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Expand Game session session-a",
    ]);

    const initialFirstBounds = firstDialog.element().getBoundingClientRect();
    const initialSecondBounds = secondDialog.element().getBoundingClientRect();
    const firstSurface = firstDialog.element().firstElementChild;
    const secondSurface = secondDialog.element().firstElementChild;
    if (!(firstSurface instanceof HTMLElement) || !(secondSurface instanceof HTMLElement)) {
      throw new Error("Expected dialog surfaces.");
    }

    expect(initialFirstBounds.height).toBeCloseTo(4 * 16, 0);
    expect(initialSecondBounds.height).toBeCloseTo(4 * 16, 0);
    expect(initialFirstBounds.width).toBeCloseTo(initialSecondBounds.width, 0);
    expect(getComputedStyle(firstSurface).boxShadow).toBe("none");
    expect(getComputedStyle(secondSurface).boxShadow).toBe("none");

    await page.getByRole("button", { name: "Expand Game session session-a" }).click();
    flushSync();

    expect(firstControlButtons.map((button) => button.getAttribute("aria-label"))).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);

    const visualControlOrder = [
      firstControlButtons[0],
      firstControlButtons[2],
      firstControlButtons[1],
    ];
    const firstControlBounds = visualControlOrder.map((button) => button?.getBoundingClientRect());
    expect(firstControlBounds[0]?.top).toBeLessThan(firstControlBounds[1]?.top ?? 0);
    expect(firstControlBounds[1]?.top).toBeLessThan(firstControlBounds[2]?.top ?? 0);
    expect(getComputedStyle(firstControls.element()).position).toBe("absolute");

    const iconBounds = firstControlButtons.map((button) => {
      const icon = button.querySelector("svg");
      if (!(icon instanceof SVGSVGElement)) throw new Error("Expected a window-control icon.");
      return icon.getBoundingClientRect();
    });
    for (const bounds of iconBounds) {
      expect(bounds.width).toBeCloseTo(0.75 * 16, 0);
      expect(bounds.height).toBeCloseTo(0.75 * 16, 0);
    }

    const compactGlyph = firstControlButtons[2]?.querySelector("path");
    if (!(compactGlyph instanceof SVGGraphicsElement)) {
      throw new Error("Expected the Compact lower-line glyph.");
    }
    expect(compactGlyph.getBBox().width).toBeCloseTo(14, 0);
    expect(compactGlyph.getBBox().height).toBeCloseTo(0, 0);

    const expandedFirstBounds = firstDialog.element().getBoundingClientRect();
    const compactSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(expandedFirstBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(expandedFirstBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(getComputedStyle(firstSurface).boxShadow).not.toBe("none");
    expect(getComputedStyle(secondSurface).boxShadow).toBe("none");
    expect(compactSecondBounds.width).toBeLessThan(expandedFirstBounds.width);
    expect(compactSecondBounds.height).toBeLessThan(expandedFirstBounds.height);
    expect(
      firstDialog
        .element()
        .contains(
          document.elementFromPoint(
            compactSecondBounds.left + compactSecondBounds.width / 2,
            compactSecondBounds.top + compactSecondBounds.height / 2,
          ),
        ),
    ).toBe(true);

    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const expandGlyph = page
      .getByRole("button", { name: "Expand Game session session-a" })
      .element()
      .querySelector("rect");
    if (!(expandGlyph instanceof SVGGraphicsElement)) {
      throw new Error("Expected the Expand outline-square glyph.");
    }
    expect(expandGlyph.getBBox().width).toBeCloseTo(14, 0);
    expect(expandGlyph.getBBox().height).toBeCloseTo(14, 0);
    expect(getComputedStyle(expandGlyph).fill).toBe("none");
    expect(getComputedStyle(expandGlyph).stroke).not.toBe("none");

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

  it("uses a centered 4rem lower-right status bar", async () => {
    renderWorkspace([descriptor("session-a")]);

    const region = page.getByRole("region", { name: "Open game sessions" });
    const dialog = page.getByRole("dialog", { name: "Game session session-a" });

    await expect.element(region).toBeVisible();
    await expect.element(dialog).toBeVisible();

    const regionBounds = region.element().getBoundingClientRect();
    const dialogBounds = dialog.element().getBoundingClientRect();

    expect(regionBounds.width).toBeCloseTo(32 * 16, 0);
    expect(regionBounds.height).toBeCloseTo(4 * 16, 0);
    expect(window.innerWidth - regionBounds.right).toBeCloseTo(12, 0);
    expect(window.innerHeight - regionBounds.bottom).toBeCloseTo(12, 0);
    expect(regionBounds.left).toBeGreaterThan(0);
    expect(dialogBounds.width).toBeCloseTo(regionBounds.width, 0);
    expect(dialogBounds.height).toBeCloseTo(regionBounds.height, 0);
  });

  it("hides Compact game content and keeps horizontal controls reachable without overflow", async () => {
    await page.viewport(390, 640);
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const region = page.getByRole("region", { name: "Open game sessions" });
    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const firstFrame = page.getByTitle("Game module").first();
    const controls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });
    const liveBadge = page
      .getByText("Live", { exact: true })
      .first()
      .element()
      .closest(".workspace__compact-status");
    const layoutControl = page.getByRole("button", {
      name: "Expand Game session session-a",
    });
    if (!(liveBadge instanceof HTMLElement)) {
      throw new Error("Expected the compact Live badge.");
    }

    await expect.element(region).toBeVisible();
    await expect.element(firstDialog).toBeVisible();
    await expect.element(firstFrame).not.toBeVisible();
    await expect.element(controls).toBeInViewport();
    await expect.element(layoutControl).toBeInViewport();
    expect(firstFrame.element().parentElement?.inert).toBe(true);
    expect(
      controls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Expand Game session session-a",
    ]);

    const regionBounds = region.element().getBoundingClientRect();
    const controlBounds = controls
      .getByRole("button")
      .elements()
      .map((button) => button.getBoundingClientRect());
    const dialogBounds = firstDialog.element().getBoundingClientRect();
    const badgeBounds = liveBadge.getBoundingClientRect();
    const sessionLabel = firstDialog.element().querySelector(".workspace__session-label");
    if (!(sessionLabel instanceof HTMLElement)) {
      throw new Error("Expected the compact session label.");
    }
    const sessionLabelBounds = sessionLabel.getBoundingClientRect();
    const controlsBounds = controls.element().getBoundingClientRect();

    expect(regionBounds.left).toBeCloseTo(12, 0);
    expect(regionBounds.right).toBeCloseTo(window.innerWidth - 12, 0);
    expect(regionBounds.bottom).toBeCloseTo(window.innerHeight - 12, 0);
    expect(regionBounds.height).toBeLessThanOrEqual(window.innerHeight - 24);
    expect(getComputedStyle(region.element()).rowGap).toBe("6px");
    expect(dialogBounds.height).toBeCloseTo(4 * 16, 0);
    expect(controlBounds[0]?.height).toBeCloseTo(1.5 * 16, 0);
    expect(badgeBounds.height).toBeCloseTo(1.5 * 16, 0);
    expect(getComputedStyle(liveBadge).textTransform).toBe("uppercase");
    expect(getComputedStyle(controls.element()).position).toBe("static");
    expect(sessionLabelBounds.left - badgeBounds.right).toBeCloseTo(0.5 * 16, 0);
    expect(controlsBounds.left - sessionLabelBounds.right).toBeCloseTo(0.5 * 16, 0);
    expect(badgeBounds.top + badgeBounds.height / 2).toBeCloseTo(
      dialogBounds.top + dialogBounds.height / 2,
      0,
    );
    expect((controlBounds[0]?.top ?? 0) + (controlBounds[0]?.height ?? 0) / 2).toBeCloseTo(
      dialogBounds.top + dialogBounds.height / 2,
      0,
    );
    expect(controlBounds[0]?.top).toBeCloseTo(controlBounds[1]?.top ?? 0, 0);
    expect(controlBounds[2]?.left).toBeLessThan(controlBounds[1]?.left ?? 0);
    expect(controlBounds[1]?.left).toBeLessThan(controlBounds[0]?.left ?? 0);
    expect(document.documentElement.scrollWidth).toBeLessThanOrEqual(window.innerWidth);

    const controlGroups = page.getByRole("group").elements();
    expect(controlGroups).toHaveLength(2);

    for (const dialog of region.getByRole("dialog").elements()) {
      const surface = dialog.firstElementChild;
      if (!(surface instanceof HTMLElement)) throw new Error("Expected a compact dialog surface.");
      expect(getComputedStyle(surface).boxShadow).toBe("none");
    }

    for (const group of controlGroups) {
      const buttons = [...group.getElementsByTagName("button")];
      expect(buttons).toHaveLength(3);
      expect(buttons[0]?.getBoundingClientRect().top).toBeCloseTo(
        buttons[1]?.getBoundingClientRect().top ?? 0,
        0,
      );
      expect(buttons[1]?.getBoundingClientRect().top).toBeCloseTo(
        buttons[2]?.getBoundingClientRect().top ?? 0,
        0,
      );

      for (const button of buttons) {
        expect(button.getBoundingClientRect().right).toBeLessThanOrEqual(window.innerWidth);
        await expect.element(page.elementLocator(button)).toBeInViewport();
      }
    }
  });

  it("moves only an overflowing session identifier and renders status motion as supplemental", async () => {
    await page.viewport(390, 640);
    const longId = "session-with-an-identifier-that-exceeds-the-available-compact-lane";
    const workspace = renderWorkspace([descriptor("short"), descriptor(longId, "finished")]);

    const shortLabel = page.getByText("Session short", { exact: true });
    const longLabel = page.getByText(`Session ${longId}`, { exact: true });
    const liveStatus = page.getByText("Live", { exact: true }).first();
    const finishedStatus = page.getByText("Finished", { exact: true }).first();

    await expect.element(shortLabel).toBeVisible();
    await expect.element(longLabel).toBeVisible();
    await vi.waitFor(() => {
      expect(shortLabel.element().getAnimations()).toHaveLength(1);
      expect(longLabel.element().getAnimations()).toHaveLength(1);
    });

    const liveText = liveStatus.element();
    const liveBadge = liveText.closest(".workspace__compact-status");
    const liveDot = liveBadge?.querySelector(".workspace__status-dot");
    const finishedBadge = finishedStatus.element().closest(".workspace__compact-status");
    const finishedDot = finishedBadge?.querySelector(".workspace__status-dot");
    if (
      !(liveBadge instanceof HTMLElement) ||
      !(liveDot instanceof HTMLElement) ||
      !(finishedDot instanceof HTMLElement)
    ) {
      throw new Error("Expected the Live and Finished status indicators.");
    }
    const liveColor = getComputedStyle(liveBadge).color;

    const shortElement = shortLabel.element();
    const longElement = longLabel.element();
    const shortLane = shortElement.parentElement;
    const longLane = longElement.parentElement;
    const shortAnimation = shortElement.getAnimations()[0];
    const longAnimation = longElement.getAnimations()[0];
    if (
      !(shortLane instanceof HTMLElement) ||
      !(longLane instanceof HTMLElement) ||
      shortAnimation === undefined ||
      longAnimation === undefined
    ) {
      throw new Error("Expected session label lanes and their CSS animations.");
    }

    expect(shortElement.scrollWidth).toBeLessThanOrEqual(shortLane.clientWidth);
    expect(longLabel.element().scrollWidth).toBeGreaterThan(
      longLabel.element().parentElement?.clientWidth ?? Number.POSITIVE_INFINITY,
    );
    shortAnimation.pause();
    longAnimation.pause();
    shortAnimation.currentTime = 0;
    longAnimation.currentTime = 0;
    const shortDuration = Number(shortAnimation.effect?.getComputedTiming().duration);
    const longDuration = Number(longAnimation.effect?.getComputedTiming().duration);
    expect(shortDuration).toBeCloseTo(7_000 / 1.2, 0);
    expect(longDuration).toBeCloseTo(7_000 / 1.2, 0);
    const shortStart = shortElement.getBoundingClientRect().left;
    const longStart = longElement.getBoundingClientRect().left;

    shortAnimation.currentTime = shortDuration * 0.9;
    longAnimation.currentTime = longDuration * 0.9;

    expect(shortElement.getBoundingClientRect().left).toBeCloseTo(shortStart, 1);
    expect(longElement.getBoundingClientRect().left - longStart).toBeCloseTo(
      longLane.getBoundingClientRect().width - longElement.getBoundingClientRect().width,
      1,
    );
    expect(getComputedStyle(liveBadge).borderStyle).toBe("solid");
    expect(getComputedStyle(liveDot).backgroundColor).toBe("rgb(0, 200, 80)");
    expect(getComputedStyle(liveDot).animationName).not.toBe("none");
    expect(getComputedStyle(liveDot).animationDuration).toBe("1.2s");
    expect(getComputedStyle(finishedDot).backgroundColor).not.toBe("rgb(0, 200, 80)");
    expect(getComputedStyle(finishedDot).animationName).toBe("none");

    workspace.status("stale");
    flushSync();

    const reconnectingStatus = page.getByText("Reconnecting", { exact: true }).first();
    await expect.element(reconnectingStatus).toBeVisible();
    const reconnectingBadge = reconnectingStatus.element().closest(".workspace__compact-status");
    const reconnectingDot = reconnectingBadge?.querySelector(".workspace__status-dot");
    if (!(reconnectingBadge instanceof HTMLElement) || !(reconnectingDot instanceof HTMLElement)) {
      throw new Error("Expected the Reconnecting status indicator.");
    }
    expect(getComputedStyle(reconnectingBadge).color).not.toBe(liveColor);
    expect(getComputedStyle(reconnectingDot).backgroundColor).toBe("rgb(255, 193, 7)");
    expect(getComputedStyle(reconnectingDot).animationName).not.toBe("none");
    expect(getComputedStyle(reconnectingDot).animationDuration).toBe("0.8s");

    workspace.status("failed");
    flushSync();

    const failedStatus = page.getByText("Failed", { exact: true }).first();
    await expect.element(failedStatus).toBeVisible();
    const failedBadge = failedStatus.element().closest(".workspace__compact-status");
    const failedDot = failedBadge?.querySelector(".workspace__status-dot");
    if (!(failedDot instanceof HTMLElement)) {
      throw new Error("Expected the Failed status indicator.");
    }
    expect(getComputedStyle(failedDot).backgroundColor).toBe("rgb(220, 38, 38)");
    expect(getComputedStyle(failedDot).animationName).toBe("none");
  });
});

function renderWorkspace(descriptors: WorkspaceSessionDescriptor[]) {
  const channelState = writable({
    value: { sessions: descriptors },
    status: "ready" as WorkspaceState["status"],
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

  return {
    status(status: WorkspaceState["status"]) {
      channelState.update((current) => ({ ...current, status }));
    },
  };
}

function descriptor(
  id: string,
  phase: WorkspaceSessionDescriptor["phase"] = "in_progress",
): WorkspaceSessionDescriptor {
  return {
    id,
    slug: "qwinto",
    phase,
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
