import { module as exposeModule } from "@rvct/d20sdk";
import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page, userEvent } from "vitest/browser";
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
  document.documentElement.style.setProperty("--color-base-content", "rgb(20 30 40)");
  document.documentElement.style.setProperty("--color-base-100", "rgb(250 250 250)");
  document.documentElement.style.setProperty("--color-success", "rgb(0 200 80)");
  document.documentElement.style.setProperty("--color-warning", "rgb(255 193 7)");
  document.documentElement.style.setProperty("--color-error", "rgb(220 38 38)");
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.documentElement.style.removeProperty("--color-base-content");
  document.documentElement.style.removeProperty("--color-base-100");
  document.documentElement.style.removeProperty("--color-success");
  document.documentElement.style.removeProperty("--color-warning");
  document.documentElement.style.removeProperty("--color-error");
  document.body.innerHTML = "";
});

describe("Workspace presentation", () => {
  it("waits for authoritative Close snapshots and restores a directly reattached session", async () => {
    const workspace = renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    await page.getByRole("button", { name: "Close Game session session-a" }).click();
    flushSync();

    expect(transport.call).toHaveBeenCalledWith("close_session", { id: "session-a" });
    expect(page.getByRole("dialog", { name: "Game session session-a" }).elements()).toHaveLength(1);
    expect(page.getByRole("dialog", { name: "Game session session-b" }).elements()).toHaveLength(1);

    workspace.ready([descriptor("session-b")]);
    flushSync();

    expect(page.getByRole("dialog", { name: "Game session session-a" }).elements()).toHaveLength(0);
    await expect
      .element(page.getByRole("dialog", { name: "Game session session-b" }))
      .toBeVisible();

    workspace.ready([descriptor("session-a"), descriptor("session-b")]);
    flushSync();

    await expect
      .element(page.getByRole("dialog", { name: "Game session session-a" }))
      .toBeVisible();
  });

  it("keeps the game frame while compacting and restoring its runtime", async () => {
    const embedUrl = URL.createObjectURL(new Blob(["<!doctype html><title>Ready</title>"]));
    const bridgeCalls = vi.mocked(exposeModule).mock.calls.length;

    try {
      renderWorkspace([descriptor("session-a", "in_progress", embedUrl, ["allow-same-origin"])]);

      const iframe = page.getByTitle("Game module").element();
      expect(iframe).toBeInstanceOf(HTMLIFrameElement);
      if (!(iframe instanceof HTMLIFrameElement)) {
        throw new Error("Expected a game module frame.");
      }

      expect(iframe.loading).toBe("eager");
      await vi.waitFor(() => expect(iframe.contentDocument?.URL).toBe(embedUrl));
      expect(vi.mocked(exposeModule).mock.calls).toHaveLength(bridgeCalls + 1);

      await page.getByRole("button", { name: "Compact Game session session-a" }).click();
      flushSync();

      await page.getByRole("button", { name: "Expand Game session session-a" }).click();
      flushSync();

      expect(page.getByTitle("Game module").element()).toBe(iframe);
      expect(iframe.contentDocument?.URL).toBe(embedUrl);
      expect(vi.mocked(exposeModule).mock.calls).toHaveLength(bridgeCalls + 1);
    } finally {
      URL.revokeObjectURL(embedUrl);
    }
  });

  it("keeps Compact restoration and Theater controls keyboard reachable in source order", async () => {
    renderWorkspace([descriptor("session-a")]);

    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const controls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });
    const close = page.getByRole("button", { name: "Close Game session session-a" });
    const enterFullscreen = page.getByRole("button", {
      name: "Enter Game session session-a fullscreen",
    });
    const restore = page.getByRole("button", { name: "Expand Game session session-a" });

    expect(restore.element().tagName).toBe("BUTTON");
    expect(
      controls
        .getByRole("button")
        .elements()
        .every((button) => button.tagName === "BUTTON"),
    ).toBe(true);

    restore.element().focus();
    await userEvent.tab();
    expect(document.activeElement).toBe(close.element());

    await userEvent.tab();
    expect(document.activeElement).toBe(enterFullscreen.element());

    restore.element().focus();
    const compactChrome = restore.element().parentElement;
    if (!(compactChrome instanceof HTMLElement)) {
      throw new Error("Expected the Compact chrome.");
    }
    expect(getComputedStyle(restore.element()).outlineStyle).toBe("none");
    expect(getComputedStyle(compactChrome).outlineStyle).not.toBe("none");

    await userEvent.keyboard("{Enter}");
    flushSync();

    const compact = page.getByRole("button", { name: "Compact Game session session-a" });
    expect(
      controls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);

    close.element().focus();
    await userEvent.tab();
    expect(document.activeElement).toBe(enterFullscreen.element());

    await userEvent.tab();
    expect(document.activeElement).toBe(compact.element());

    await userEvent.keyboard(" ");
    flushSync();

    const restored = page.getByRole("button", { name: "Expand Game session session-a" });
    restored.element().focus();
    await userEvent.keyboard(" ");
    flushSync();

    await expect
      .element(page.getByRole("button", { name: "Compact Game session session-a" }))
      .toBeVisible();

    await page.getByRole("button", { name: "Enter Game session session-a fullscreen" }).click();
    const exitFullscreen = page.getByRole("button", {
      name: "Exit Game session session-a fullscreen",
    });
    await expect.element(exitFullscreen).toBeVisible();

    for (const fullscreenControl of controls.getByRole("button").elements()) {
      const icon = fullscreenControl.querySelector("svg");
      if (!(icon instanceof SVGSVGElement)) {
        throw new Error("Expected a fullscreen window-control icon.");
      }
      expect(fullscreenControl.getBoundingClientRect().width).toBeCloseTo(1.875 * 16, 0);
      expect(fullscreenControl.getBoundingClientRect().height).toBeCloseTo(1.875 * 16, 0);
      expect(icon.getBoundingClientRect().width).toBeCloseTo(0.9375 * 16, 0);
      expect(icon.getBoundingClientRect().height).toBeCloseTo(0.9375 * 16, 0);
    }

    await exitFullscreen.click();
  });

  it("starts Auto, stacks the Theater window above siblings, and restores selection", async () => {
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const secondDialog = page.getByRole("dialog", { name: "Game session session-b" });
    const firstControls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });

    await expect.element(firstDialog).toBeVisible();
    await expect.element(secondDialog).toBeVisible();

    expect(
      firstControls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);

    const initialFirstBounds = firstDialog.element().getBoundingClientRect();
    const initialSecondBounds = secondDialog.element().getBoundingClientRect();
    const firstSurface = firstDialog.element().firstElementChild;
    const secondSurface = secondDialog.element().firstElementChild;
    if (!(firstSurface instanceof HTMLElement) || !(secondSurface instanceof HTMLElement)) {
      throw new Error("Expected dialog surfaces.");
    }

    expect(initialFirstBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(initialFirstBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(initialSecondBounds.height).toBeCloseTo(3 * 16, 0);
    expect(initialSecondBounds.width).toBeLessThan(initialFirstBounds.width);
    expect(getComputedStyle(firstSurface).backgroundColor).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(firstSurface).color).toBe("rgb(0, 0, 0)");
    expect(getComputedStyle(firstSurface).boxShadow).not.toBe("none");
    expect(getComputedStyle(secondSurface).boxShadow).toBe("none");

    const theaterControlButtons = firstControls.getByRole("button").elements();
    expect(theaterControlButtons.map((button) => button.getAttribute("aria-label"))).toEqual([
      "Close Game session session-a",
      "Enter Game session session-a fullscreen",
      "Compact Game session session-a",
    ]);

    const visualControlOrder = [
      theaterControlButtons[0],
      theaterControlButtons[2],
      theaterControlButtons[1],
    ];
    const firstControlBounds = visualControlOrder.map((button) => button?.getBoundingClientRect());
    expect(firstControlBounds[0]?.top).toBeLessThan(firstControlBounds[1]?.top ?? 0);
    expect(firstControlBounds[1]?.top).toBeLessThan(firstControlBounds[2]?.top ?? 0);
    expect(getComputedStyle(firstControls.element()).position).toBe("absolute");

    const iconBounds = theaterControlButtons.map((button) => {
      const icon = button.querySelector("svg");
      if (!(icon instanceof SVGSVGElement)) throw new Error("Expected a window-control icon.");
      return icon.getBoundingClientRect();
    });
    for (const bounds of iconBounds) {
      expect(bounds.width).toBeCloseTo(0.9375 * 16, 0);
      expect(bounds.height).toBeCloseTo(0.9375 * 16, 0);
    }
    for (const button of theaterControlButtons) {
      expect(button.getBoundingClientRect().width).toBeCloseTo(1.875 * 16, 0);
      expect(button.getBoundingClientRect().height).toBeCloseTo(1.875 * 16, 0);
    }

    const compactGlyph = theaterControlButtons[2]?.querySelector("path");
    if (!(compactGlyph instanceof SVGGraphicsElement)) {
      throw new Error("Expected the Compact lower-line glyph.");
    }
    expect(compactGlyph.getBBox().width).toBeCloseTo(14, 0);
    expect(compactGlyph.getBBox().height).toBeCloseTo(0, 0);

    const expandedFirstBounds = firstDialog.element().getBoundingClientRect();
    const compactSecondBounds = secondDialog.element().getBoundingClientRect();

    expect(expandedFirstBounds.width).toBeCloseTo(window.innerWidth - 16, 0);
    expect(expandedFirstBounds.height).toBeCloseTo(window.innerHeight - 16, 0);
    expect(getComputedStyle(firstSurface).backgroundColor).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(firstSurface).color).toBe("rgb(0, 0, 0)");
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

    const restoreSurface = page.getByRole("button", { name: "Expand Game session session-a" });
    expect(restoreSurface.element().querySelector("svg")).toBeNull();
    expect(
      firstControls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual(["Close Game session session-a", "Enter Game session session-a fullscreen"]);

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

  it("keeps Compact content readable with dark theme tokens", async () => {
    await page.viewport(390, 640);
    document.documentElement.style.setProperty("--color-base-content", "rgb(250 250 250)");
    document.documentElement.style.setProperty("--color-base-100", "rgb(20 30 40)");
    renderWorkspace([descriptor("session-a")]);

    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const dialog = page.getByRole("dialog", { name: "Game session session-a" });
    const liveText = page.getByText("Live", { exact: true });
    const sessionText = page.getByText("Session session-a", { exact: true });
    const controls = page.getByRole("group", {
      name: "Game session session-a window controls",
    });
    const surface = dialog.element().firstElementChild;
    const liveBadge = liveText.element().closest(".workspace__compact-status");
    const sessionLabel = sessionText.element().closest(".workspace__session-label");
    if (
      !(surface instanceof HTMLElement) ||
      !(liveBadge instanceof HTMLElement) ||
      !(sessionLabel instanceof HTMLElement)
    ) {
      throw new Error("Expected the Compact surface, status, and session label.");
    }

    expect(getComputedStyle(surface).backgroundColor).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(surface).color).toBe("rgb(20, 30, 40)");
    expect(getComputedStyle(liveBadge).backgroundColor).toBe("rgb(20, 30, 40)");
    expect(getComputedStyle(liveBadge).color).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(sessionLabel).color).toBe("rgb(20, 30, 40)");

    for (const button of controls.getByRole("button").elements()) {
      expect(getComputedStyle(button).backgroundColor).toBe("rgb(20, 30, 40)");
      expect(getComputedStyle(button).color).toBe("rgb(250, 250, 250)");
    }
  });

  it("uses a content-sized lower-right status bar with equal padding", async () => {
    renderWorkspace([descriptor("session-a")]);

    await page.getByRole("button", { name: "Compact Game session session-a" }).click();
    flushSync();

    const region = page.getByRole("region", { name: "Open game sessions" });
    const dialog = page.getByRole("dialog", { name: "Game session session-a" });
    const restore = page.getByRole("button", { name: "Expand Game session session-a" });
    const badge = page
      .getByText("Live", { exact: true })
      .element()
      .closest(".workspace__compact-status");
    const chrome = restore.element().parentElement;
    if (!(badge instanceof HTMLElement) || !(chrome instanceof HTMLElement)) {
      throw new Error("Expected Compact chrome and status badge.");
    }

    await expect.element(region).toBeVisible();
    await expect.element(dialog).toBeVisible();

    const regionBounds = region.element().getBoundingClientRect();
    const dialogBounds = dialog.element().getBoundingClientRect();
    const badgeBounds = badge.getBoundingClientRect();
    const chromeStyle = getComputedStyle(chrome);

    expect(regionBounds.width).toBeCloseTo(32 * 16, 0);
    expect(getComputedStyle(region.element()).gridAutoRows).toBe("auto");
    expect(chromeStyle.paddingBlockStart).toBe("8px");
    expect(chromeStyle.paddingBlockEnd).toBe("8px");
    expect(chromeStyle.paddingInlineStart).toBe("8px");
    expect(chromeStyle.paddingInlineEnd).toBe("8px");
    expect(chrome.clientHeight).toBeCloseTo(badgeBounds.height + 2 * 8, 0);
    expect(regionBounds.height).toBeCloseTo(chrome.clientHeight + 2, 0);
    expect(window.innerWidth - regionBounds.right).toBeCloseTo(12, 0);
    expect(window.innerHeight - regionBounds.bottom).toBeCloseTo(12, 0);
    expect(regionBounds.left).toBeGreaterThan(0);
    expect(dialogBounds.width).toBeCloseTo(regionBounds.width, 0);
    expect(dialogBounds.height).toBeCloseTo(regionBounds.height, 0);
  });

  it("hides Compact game content and keeps horizontal controls reachable without overflow", async () => {
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
    const liveBadge = page
      .getByText("Live", { exact: true })
      .first()
      .element()
      .closest(".workspace__compact-status");
    const restoreSurface = page.getByRole("button", {
      name: "Expand Game session session-a",
    });
    if (!(liveBadge instanceof HTMLElement)) {
      throw new Error("Expected the compact Live badge.");
    }

    await expect.element(region).toBeVisible();
    await expect.element(firstDialog).toBeVisible();
    await expect.element(firstFrame).not.toBeVisible();
    await expect.element(controls).toBeInViewport();
    await expect.element(restoreSurface).toBeInViewport();
    expect(firstFrame.element().parentElement?.inert).toBe(true);
    expect(
      controls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual(["Close Game session session-a", "Enter Game session session-a fullscreen"]);

    const regionBounds = region.element().getBoundingClientRect();
    const controlButtons = controls.getByRole("button").elements();
    const controlBounds = controlButtons.map((button) => button.getBoundingClientRect());
    const dialogBounds = firstDialog.element().getBoundingClientRect();
    const badgeBounds = liveBadge.getBoundingClientRect();
    const compactChrome = restoreSurface.element().parentElement;
    const sessionLabel = firstDialog.element().querySelector(".workspace__session-label");
    if (!(compactChrome instanceof HTMLElement) || !(sessionLabel instanceof HTMLElement)) {
      throw new Error("Expected the Compact chrome and session label.");
    }
    const chromeStyle = getComputedStyle(compactChrome);
    const sessionLabelBounds = sessionLabel.getBoundingClientRect();
    const controlsBounds = controls.element().getBoundingClientRect();

    expect(regionBounds.left).toBeCloseTo(12, 0);
    expect(regionBounds.right).toBeCloseTo(window.innerWidth - 12, 0);
    expect(regionBounds.bottom).toBeCloseTo(window.innerHeight - 12, 0);
    expect(regionBounds.height).toBeLessThanOrEqual(window.innerHeight - 24);
    expect(getComputedStyle(region.element()).rowGap).toBe("6px");
    expect(dialogBounds.height).toBeCloseTo(3 * 16, 0);
    expect(chromeStyle.paddingBlockStart).toBe("8px");
    expect(chromeStyle.paddingBlockEnd).toBe("8px");
    expect(chromeStyle.paddingInlineStart).toBe("8px");
    expect(chromeStyle.paddingInlineEnd).toBe("8px");
    expect(restoreSurface.element().getBoundingClientRect().height).toBeCloseTo(
      compactChrome.clientHeight,
      0,
    );
    expect(restoreSurface.element().children).toHaveLength(0);
    expect(liveBadge.parentElement).toBe(compactChrome);
    expect(sessionLabel.parentElement).toBe(compactChrome);
    expect(controls.element().parentElement).toBe(compactChrome);
    expect(
      document.elementFromPoint(
        sessionLabelBounds.left + sessionLabelBounds.width / 2,
        sessionLabelBounds.top + sessionLabelBounds.height / 2,
      ),
    ).toBe(restoreSurface.element());
    expect(controlBounds[0]?.height).toBeCloseTo(1.875 * 16, 0);
    expect(badgeBounds.height).toBeCloseTo(1.875 * 16, 0);
    expect(badgeBounds.width).toBeCloseTo(5.25 * 16, 0);
    expect(getComputedStyle(liveBadge).minInlineSize).toBe("84px");
    expect(getComputedStyle(liveBadge).justifyContent).toBe("center");
    expect(getComputedStyle(liveBadge).backgroundColor).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(liveBadge).color).toBe("rgb(20, 30, 40)");
    expect(getComputedStyle(sessionLabel).color).toBe("rgb(250, 250, 250)");
    for (const button of controlButtons) {
      const icon = button.querySelector("svg");
      if (!(icon instanceof SVGSVGElement)) throw new Error("Expected a Compact control icon.");
      expect(button.getBoundingClientRect().width).toBeCloseTo(1.875 * 16, 0);
      expect(getComputedStyle(button).backgroundColor).toBe("rgb(250, 250, 250)");
      expect(getComputedStyle(button).color).toBe("rgb(20, 30, 40)");
      expect(icon.getBoundingClientRect().width).toBeCloseTo(0.9375 * 16, 0);
      expect(icon.getBoundingClientRect().height).toBeCloseTo(0.9375 * 16, 0);
    }
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
      expect(buttons).toHaveLength(2);
      expect(buttons[0]?.getBoundingClientRect().top).toBeCloseTo(
        buttons[1]?.getBoundingClientRect().top ?? 0,
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

    await page.getByRole("button", { name: "Compact Game session short" }).click();
    flushSync();

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
    expect(getComputedStyle(reconnectingBadge).color).toBe(liveColor);
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
    ready(sessions: WorkspaceSessionDescriptor[]) {
      channelState.update((current) => ({
        ...current,
        status: "ready",
        value: { sessions },
      }));
    },
    status(status: WorkspaceState["status"]) {
      channelState.update((current) => ({ ...current, status }));
    },
  };
}

function descriptor(
  id: string,
  phase: WorkspaceSessionDescriptor["phase"] = "in_progress",
  embedUrl = "about:blank",
  sandbox: string[] = [],
): WorkspaceSessionDescriptor {
  return {
    id,
    slug: "qwinto",
    phase,
    module: {
      embed_url: embedUrl,
      allowed_origins: ["null"],
      sandbox,
    },
    connection: {
      endpoint: "wss://module.example.test/socket",
      topic: `session:${id}`,
      token: `token-${id}`,
    },
  };
}
