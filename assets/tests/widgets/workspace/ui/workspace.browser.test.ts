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

const qwintoId = "game_01h45yhtgqfhxbcrsfbhxdsdvy";

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

describe("Workspace behavior", () => {
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
    await userEvent.keyboard("{Enter}");
    flushSync();

    const compact = page.getByRole("button", { name: "Compact Game session session-a" });
    await expect.element(compact).toBeVisible();
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

    await exitFullscreen.click();
  });

  it("starts Auto with the first session expanded and restores selection", async () => {
    renderWorkspace([descriptor("session-a"), descriptor("session-b")]);

    const firstDialog = page.getByRole("dialog", { name: "Game session session-a" });
    const secondDialog = page.getByRole("dialog", { name: "Game session session-b" });
    const compactFirst = page.getByRole("button", { name: "Compact Game session session-a" });
    const expandSecond = page.getByRole("button", { name: "Expand Game session session-b" });

    await expect.element(firstDialog).toBeVisible();
    await expect.element(secondDialog).toBeVisible();
    await expect.element(compactFirst).toBeVisible();
    await expect.element(expandSecond).toBeVisible();

    await compactFirst.click();
    flushSync();

    await expect
      .element(page.getByRole("button", { name: "Expand Game session session-a" }))
      .toBeVisible();

    await expandSecond.click();
    flushSync();

    await expect
      .element(page.getByRole("button", { name: "Compact Game session session-b" }))
      .toBeVisible();
  });

  it("hides Compact game content while keeping its controls available", async () => {
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
    const restoreSurface = page.getByRole("button", {
      name: "Expand Game session session-a",
    });

    await expect.element(region).toBeVisible();
    await expect.element(firstDialog).toBeVisible();
    await expect.element(firstFrame).not.toBeVisible();
    await expect.element(controls).toBeVisible();
    await expect.element(restoreSurface).toBeVisible();
    expect(firstFrame.element().parentElement?.inert).toBe(true);
    expect(
      controls
        .getByRole("button")
        .elements()
        .map((button) => button.getAttribute("aria-label")),
    ).toEqual(["Close Game session session-a", "Enter Game session session-a fullscreen"]);
    await expect
      .element(page.getByRole("button", { name: "Expand Game session session-b" }))
      .toBeVisible();
  });

  it("renders session identifiers and connection status transitions", async () => {
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
    await expect.element(liveStatus).toBeVisible();
    await expect.element(finishedStatus).toBeVisible();

    workspace.status("stale");
    flushSync();

    const reconnectingStatus = page.getByText("Reconnecting", { exact: true }).first();
    await expect.element(reconnectingStatus).toBeVisible();

    workspace.status("failed");
    flushSync();

    const failedStatus = page.getByText("Failed", { exact: true }).first();
    await expect.element(failedStatus).toBeVisible();
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
    game_id: qwintoId,
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
