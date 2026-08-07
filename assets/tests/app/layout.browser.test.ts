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

const supportsScrollTimeline = CSS.supports(
  "(animation-timeline: scroll()) and (animation-range: 0% 100%) and " +
    "(scroll-timeline: --app-shell-scroll block) and (timeline-scope: --app-shell-scroll)",
);

beforeEach(async () => {
  auth.trigger.reset();
  await page.viewport(1280, 800);
  inertiaMock.setPage({
    props: {
      auth: { authenticated: false, local: false, prompt: null },
      errors: {},
    },
  });
});

afterEach(() => {
  workspaceMock.createWorkspace.mockClear();
});

describe("Layout scroll timeline", () => {
  it("hosts a server-requested account dialog", async () => {
    inertiaMock.setPage({
      url: "/",
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: {
            email: "",
            message: "You must log in to access this page.",
            reauthenticate: false,
            returnTo: "/users/settings",
          },
        },
        errors: {},
      },
    });

    await render(Layout, { children: narrowLayoutContent });

    await expect.element(page.getByRole("dialog", { name: "Log in" })).toBeVisible();
    await expect.element(page.getByRole("status")).toHaveTextContent("You must log in");
  });

  it("reserves scrollbar space symmetrically", async () => {
    await render(Layout, { children: narrowLayoutContent });

    const content = page.getByRole("main").element();

    expect(getComputedStyle(content).scrollbarGutter).toBe("stable both-edges");
  });

  it("aligns header and content horizontal gutters", async () => {
    await page.viewport(800, 800);
    await render(Layout, { children: narrowLayoutContent });

    const brand = page.getByRole("link", { name: "D20" }).element();
    const register = page.getByRole("button", { name: "Register" }).element();
    const content = page.getByText("initial", { exact: true }).element();
    const contentStyle = getComputedStyle(content);
    const contentStart =
      content.getBoundingClientRect().left + Number.parseFloat(contentStyle.paddingInlineStart);
    const contentEnd =
      content.getBoundingClientRect().right - Number.parseFloat(contentStyle.paddingInlineEnd);

    expect(brand.getBoundingClientRect().left).toBeCloseTo(contentStart, 0);
    expect(register.getBoundingClientRect().right).toBeCloseTo(contentEnd, 0);
    expect(contentStart).toBeCloseTo(window.innerWidth - contentEnd, 0);
  });

  it("aligns the wide header, content, and footer to desktop gutters", async () => {
    await render(Layout, { variant: "wide", children: wideLayoutContent });

    const brand = page.getByRole("link", { name: "D20" }).element();
    const register = page.getByRole("button", { name: "Register" }).element();
    const developerLink = page.getByRole("link", { name: "for developers" }).element();
    const content = page.getByText("wide", { exact: true }).element();
    const contentStyle = getComputedStyle(content);
    const contentStart =
      content.getBoundingClientRect().left + Number.parseFloat(contentStyle.paddingInlineStart);
    const contentEnd =
      content.getBoundingClientRect().right - Number.parseFloat(contentStyle.paddingInlineEnd);

    expect(brand.getBoundingClientRect().left).toBeCloseTo(contentStart, 0);
    expect(register.getBoundingClientRect().right).toBeCloseTo(contentEnd, 0);
    expect(developerLink.getBoundingClientRect().right).toBeCloseTo(contentEnd, 0);
    expect(contentStart - content.getBoundingClientRect().left).toBeCloseTo(24, 3);
    expect(content.getBoundingClientRect().right - contentEnd).toBeCloseTo(24, 3);
    expect(contentStart).toBeCloseTo(window.innerWidth - contentEnd, 0);
  });

  it("aligns the wide header, content, and footer to mobile gutters", async () => {
    await page.viewport(412, 915);
    await render(Layout, { variant: "wide", children: mobileWideLayoutContent });

    const brand = page.getByRole("link", { name: "D20" }).element();
    const register = page.getByRole("button", { name: "Register" }).element();
    const developerLink = page.getByRole("link", { name: "for developers" }).element();
    const content = page.getByText("mobile wide", { exact: true }).element();
    const contentStyle = getComputedStyle(content);
    const contentStart =
      content.getBoundingClientRect().left + Number.parseFloat(contentStyle.paddingInlineStart);
    const contentEnd =
      content.getBoundingClientRect().right - Number.parseFloat(contentStyle.paddingInlineEnd);

    expect(brand.getBoundingClientRect().left).toBeCloseTo(contentStart, 0);
    expect(register.getBoundingClientRect().right).toBeCloseTo(contentEnd, 0);
    expect(developerLink.getBoundingClientRect().right).toBeCloseTo(contentEnd, 0);
    expect(contentStart - content.getBoundingClientRect().left).toBeCloseTo(16, 3);
    expect(content.getBoundingClientRect().right - contentEnd).toBeCloseTo(16, 3);
    expect(contentStart).toBeCloseTo(window.innerWidth - contentEnd, 0);
  });

  it.runIf(supportsScrollTimeline)(
    "links header dimensions to the internal content scroll position",
    async () => {
      await render(Layout, { children: narrowLayoutContent });

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

const narrowLayoutContent = createRawSnippet(() => ({
  render: () =>
    '<p style="box-sizing: border-box; inline-size: 100%; max-inline-size: 46.25rem; min-block-size: 200dvh; margin: 0 auto; padding-inline: 1rem;">initial</p>',
}));

const wideLayoutContent = createRawSnippet(() => ({
  render: () =>
    '<p style="box-sizing: border-box; inline-size: 100%; max-inline-size: 64rem; min-block-size: 200dvh; margin: 0 auto; padding-inline: 1.5rem;">wide</p>',
}));

const mobileWideLayoutContent = createRawSnippet(() => ({
  render: () =>
    '<p style="box-sizing: border-box; inline-size: 100%; max-inline-size: 64rem; min-block-size: 200dvh; margin: 0 auto; padding-inline: 1rem;">mobile wide</p>',
}));
