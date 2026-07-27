import { flushSync, mount, unmount } from "svelte";
import { afterEach, describe, expect, it, vi } from "vitest";
import Layout from "~/app/layout.svelte";
import { layout as developersLayout } from "~/pages/developers";
import * as gamePage from "~/pages/game";
import { layout as homeLayout } from "~/pages/home";
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
    focus: vi.fn(),
  };

  return { createWorkspace: vi.fn(() => workspace) };
});

vi.mock("~/widgets/workspace/model/workspace", () => ({
  createWorkspace: workspaceMock.createWorkspace,
}));

let cleanup: (() => Promise<void>) | undefined;

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  workspaceMock.createWorkspace.mockClear();
});

describe("Layout", () => {
  it("gets non-default presentation metadata from page public APIs", () => {
    expect(homeLayout).toEqual({ variant: "narrow" });
    expect(developersLayout).toEqual({ variant: "narrow" });
    expect(gamePage).not.toHaveProperty("layout");
  });

  it("marks page content as an Inertia scroll region and links developers", () => {
    renderLayout();

    const content = document.body.querySelector("main");
    const developerLink = document.body.querySelector('footer a[href="/developers"]');

    expect(content?.hasAttribute("scroll-region")).toBe(true);
    expect(content?.getAttribute("tabindex")).toBe("-1");
    expect(developerLink?.textContent).toBe("for developers");
    expect(developerLink?.getAttribute("href")).toBe("/developers");
  });

  it("preserves one realtime workspace while replaceable page content changes", () => {
    const component = renderLayoutHarness();
    const main = document.querySelector("main");
    const header = document.querySelector("header");

    component.navigate("home", "narrow");
    flushSync();

    expect(workspaceMock.createWorkspace).toHaveBeenCalledOnce();
    expect(document.querySelector("main")).toBe(main);
    expect(document.querySelector("header")).toBe(header);
    expect(header?.classList.contains("header--narrow")).toBe(true);

    component.navigate("game", "default");
    flushSync();

    expect(workspaceMock.createWorkspace).toHaveBeenCalledOnce();
    expect(document.querySelector("main")).toBe(main);
    expect(document.querySelector("[data-page=game]")).not.toBeNull();
  });
});

function renderLayout() {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() => mount(Layout, { target }));

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function renderLayoutHarness() {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() => mount(LayoutHarness, { target }));

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };

  return component;
}
