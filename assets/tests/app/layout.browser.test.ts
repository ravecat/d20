import { flushSync, mount, unmount } from "svelte";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import LayoutHarness from "../mocks/layout_harness.svelte";

const workspaceMock = vi.hoisted(() => {
  const workspace = {
    subscribe(
      listener: (state: {
        sessions: [];
        layout: { mode: "auto" };
        status: "ready";
        error: null;
      }) => void,
    ) {
      listener({ sessions: [], layout: { mode: "auto" }, status: "ready", error: null });
      return () => undefined;
    },
    compact: vi.fn(),
    close: vi.fn(),
    dispose: vi.fn(),
    focus: vi.fn(),
  };

  return { createWorkspace: vi.fn(() => workspace) };
});

vi.mock("~/widgets/workspace/model/workspace", () => ({
  createWorkspace: workspaceMock.createWorkspace,
}));

vi.mock("@inertiajs/svelte", () => ({
  inertia: () => undefined,
  router: {
    get: () => undefined,
  },
}));

let cleanup: (() => Promise<void>) | undefined;

const supportsScrollTimeline = CSS.supports(
  "(animation-timeline: scroll()) and (animation-range: 0% 100%) and " +
    "(scroll-timeline: --app-shell-scroll block) and (timeline-scope: --app-shell-scroll)",
);

beforeEach(async () => {
  await page.viewport(1280, 800);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  workspaceMock.createWorkspace.mockClear();
});

describe("Layout scroll timeline", () => {
  it("reserves scrollbar space symmetrically", () => {
    renderLayout();

    const content = page.getByRole("main").element();

    expect(getComputedStyle(content).scrollbarGutter).toBe("stable both-edges");
  });

  it.runIf(supportsScrollTimeline)(
    "links header dimensions to the internal content scroll position",
    async () => {
      renderLayout();

      const header = page.getByRole("banner");
      const content = page.getByRole("main");

      await expect.element(header).toBeVisible();
      await expect.element(content).toBeVisible();
      expect(header.element().getBoundingClientRect().height).toBeCloseTo(80, 0);

      content.element().scrollTop = 12;

      await expect.poll(() => header.element().getBoundingClientRect().height).toBeCloseTo(64, 0);

      content.element().scrollTop = 24;

      await expect.poll(() => header.element().getBoundingClientRect().height).toBeCloseTo(48, 0);

      content.element().scrollTop = 0;

      await expect.poll(() => header.element().getBoundingClientRect().height).toBeCloseTo(80, 0);
    },
  );
});

function renderLayout() {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() => mount(LayoutHarness, { target }));

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}
