import { render, screen } from "@testing-library/svelte";
import { afterEach, describe, expect, it, vi } from "vitest";
import Layout from "~/app/layout.svelte";
import * as developersPage from "~/pages/developers";
import * as gamePage from "~/pages/game";
import * as homePage from "~/pages/home";
import { auth } from "~/shared/stores";

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

afterEach(() => {
  auth.trigger.reset();
  workspaceMock.createWorkspace.mockClear();
});

describe("Layout", () => {
  it("uses narrow presentation by default and exposes only wide page overrides", () => {
    expect(homePage).not.toHaveProperty("layout");
    expect(developersPage).not.toHaveProperty("layout");
    expect(gamePage.layout).toEqual({ variant: "wide" });
  });

  it("marks page content as an Inertia scroll region and links developers", () => {
    render(Layout);

    const content = screen.getByRole("main");
    const developerLink = screen.getByRole("link", { name: "for developers" });

    expect(content.hasAttribute("scroll-region")).toBe(true);
    expect(content.getAttribute("tabindex")).toBe("-1");
    expect(developerLink.textContent).toBe("for developers");
    expect(developerLink.getAttribute("href")).toBe("/developers");
  });
});
