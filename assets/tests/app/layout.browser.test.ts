import { createRawSnippet } from "svelte";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { page } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import Layout from "~/app/layout.svelte";
import { auth } from "~/shared/stores";
import inertiaMock from "../mocks/inertia";

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

beforeEach(async () => {
  auth.trigger.reset();
  await page.viewport(1280, 800);
  inertiaMock.setPage({
    props: {
      auth: {
        authenticated: false,
        local: false,
        prompt: null,
        providers: {
          apple: { available: false },
          discord: { available: true },
          facebook: { available: false },
          google: { available: true },
          steam: { available: false },
        },
      },
      errors: {},
    },
  });
});

afterEach(() => {
  window.scrollTo(0, 0);
  workspaceMock.createWorkspace.mockClear();
});

describe("app layout", () => {
  it.each([
    { name: "desktop", width: 1280 },
    { name: "mobile", width: 480 },
  ])(
    "uses the document as its only page scroller at the $name viewport",
    async ({ name, width }) => {
      await page.viewport(width, 800);
      await render(Layout, { children: overflowingLayoutContent });

      const content = page.getByRole("main");
      const brand = page.getByRole("link", { name: "D20" });
      const firstAction = page.getByRole("link", { name: "First action" });
      const lowerAction = page.getByRole("link", { name: "Lower action" });
      const scrollingElement = document.scrollingElement;

      expect(scrollingElement).not.toBeNull();
      expect(scrollingElement).toBe(document.documentElement);
      await expect.element(firstAction).toBeVisible();

      content.element().scrollTop = 24;

      expect(content.element().scrollTop).toBe(0);
      expect(scrollingElement!.scrollTop).toBe(0);

      scrollingElement!.scrollTop = 12;

      await expect.poll(() => scrollingElement!.scrollTop).toBeCloseTo(12, 0);

      if (supportsRootScrollAnimation()) {
        await expect.poll(() => animationProgress(brand.element())).toBeCloseTo(0.5, 1);
      } else {
        expect(brand.element().getAnimations()).toHaveLength(0);
      }

      scrollingElement!.scrollTop = 24;

      await expect.poll(() => scrollingElement!.scrollTop).toBeCloseTo(24, 0);

      if (supportsRootScrollAnimation()) {
        await expect.poll(() => animationProgress(brand.element())).toBeCloseTo(1, 1);
        await expect(document.documentElement).toMatchScreenshot(`${name}-compact-page.png`);
      }

      lowerAction.element().scrollIntoView({ block: "start" });

      await expect.poll(() => scrollingElement!.scrollTop).toBeGreaterThan(24);
      await expect
        .poll(() => documentBlockOffset(lowerAction.element()) - scrollingElement!.scrollTop)
        .toBeGreaterThanOrEqual((width <= 544 ? 72 : 80) - 1);

      scrollingElement!.scrollTop = 0;

      await expect.poll(() => scrollingElement!.scrollTop).toBe(0);
      if (supportsRootScrollAnimation()) {
        await expect.poll(() => animationProgress(brand.element())).toBeCloseTo(0, 1);
      }
    },
  );

  it("hosts a server-requested account dialog", async () => {
    inertiaMock.setPage({
      url: "/",
      props: {
        auth: {
          authenticated: false,
          local: false,
          providers: {
            apple: { available: false },
            discord: { available: true },
            facebook: { available: false },
            google: { available: true },
            steam: { available: false },
          },
          prompt: {
            email: null,
            identifier: "",
            kind: "warning",
            message: "You must log in to access this page.",
            reauthenticate: false,
            returnTo: "/profile",
          },
        },
        errors: {},
      },
    });

    await render(Layout, { children: layoutContent });

    await expect.element(page.getByRole("dialog", { name: "Log in" })).toBeVisible();
    await expect.element(page.getByRole("status")).toHaveTextContent("You must log in");
  });
});

const layoutContent = createRawSnippet(() => ({
  render: () => "<p>content</p>",
}));

const overflowingLayoutContent = createRawSnippet(() => ({
  render: () => `
    <section aria-label="Long page" style="min-block-size: 75rem">
      <a href="#start">First action</a>
      <a id="lower-action" href="#lower-action" style="display: block; margin-block-start: 25rem">Lower action</a>
    </section>
  `,
}));

function supportsRootScrollAnimation() {
  return CSS.supports("(animation-timeline: scroll()) and (animation-range: 0% 100%)");
}

function animationProgress(element: Element) {
  return element.getAnimations()[0]?.effect?.getComputedTiming().progress;
}

function documentBlockOffset(element: Element) {
  let offset = 0;
  let current: Element | null = element;

  while (current instanceof HTMLElement) {
    offset += current.offsetTop;
    current = current.offsetParent;
  }

  return offset;
}
