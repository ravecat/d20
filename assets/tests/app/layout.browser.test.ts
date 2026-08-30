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
  workspaceMock.createWorkspace.mockClear();
});

describe("app layout", () => {
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
