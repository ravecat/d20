import { flushSync, mount, unmount } from "svelte";
import { writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Session from "~/shared/components/session.svelte";
import type { SessionState, SessionStore } from "~/shared/stores";
import type { Session as SessionProjection } from "~/shared/types";

const start = vi.fn();

let cleanup: (() => Promise<void>) | undefined;
beforeEach(() => start.mockClear());

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("Session", () => {
  it("shows only online members while waiting for players", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: null,
    });

    expect(document.body.textContent).toContain("Start");
    expect(document.body.textContent).toContain("Ada");
    expect(document.body.textContent).not.toContain("Grace");
    expect(document.querySelector("button")?.hasAttribute("disabled")).toBe(false);
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });

  it("starts sessions without projected attrs", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: null,
    });

    document.querySelector("button")?.click();
    flushSync();

    expect(start).toHaveBeenCalledWith({});
  });

  it("submits projected attrs without client-side normalization", () => {
    renderPanel({
      value: {
        ...sessionWithPhase("waiting_for_players"),
        attrs: projectedAttrs(),
      },
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: null,
    });

    const seat1 = selectByLabel("Seat 1");
    const seat4 = selectByLabel("Seat 4");

    expect(seat1.value).toBe("ada");
    expect(seat4.value).toBe("margaret");

    seat1.value = "margaret";

    expect(seat4.value).toBe("margaret");

    document.querySelector("button")?.click();
    flushSync();

    expect(start).toHaveBeenCalledWith({
      turn_order: ["margaret", "grace", "katherine", "margaret"],
    });
  });

  it("disables start when permissions do not allow starting the game", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players", { can_start_game: false }),
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: null,
    });

    const startButton = document.querySelector("button");

    expect(startButton?.textContent).toContain("Start");
    expect(startButton?.hasAttribute("disabled")).toBe(true);

    startButton?.click();
    flushSync();

    expect(start).not.toHaveBeenCalled();
  });

  it("omits unavailable presence copy when no members are visible", () => {
    renderPanel({
      value: { ...sessionWithPhase("waiting_for_players"), members: {} },
      status: "failed",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: { kind: "transport_error", cause: new Error("transport failed") },
    });

    expect(document.body.textContent).not.toContain("Presence unavailable");
    expect(document.querySelector('ul[aria-label="Joined players"]')).not.toBeNull();
  });

  it("keeps projected action errors and timeouts visible", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "ready",
      processing: { start: false },
      timeouts: { start: true },
      errors: { start: { reason: "not_owner" } },
      error: null,
    });

    expect(document.body.textContent).toContain("timeout");
    expect(document.body.textContent).not.toContain("not_owner");
  });

  it("shows the projected action reason when no timeout supersedes it", () => {
    renderPanel({
      value: sessionWithPhase("waiting_for_players"),
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: { reason: "not_owner" } },
      error: null,
    });

    expect(document.body.textContent).toContain("not_owner");
  });

  it("hides active members once the session is in progress", () => {
    renderPanel({
      value: sessionWithPhase("in_progress"),
      status: "ready",
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
      error: null,
    });

    expect(document.body.textContent).not.toContain("Start");
    expect(document.body.textContent).not.toContain("Ada");
    expect(document.body.textContent).not.toContain("Grace");
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });

  it("does not render Lobby controls after the session is finished", () => {
    renderPanel({
      value: sessionWithPhase("finished"),
      status: "ready",
      error: null,
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
    });

    expect(document.body.textContent).not.toContain("Start");
    expect(document.body.textContent).not.toContain("Ada");
    expect(document.body.textContent).not.toContain("Grace");
    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });

  it("does not mount the module frame before the session phase is available", () => {
    renderPanel({
      value: null,
      status: "loading",
      error: null,
      processing: { start: false },
      timeouts: { start: false },
      errors: { start: null },
    });

    expect(document.querySelector('iframe[title="Game module"]')).toBeNull();
  });
});

function renderPanel(state: SessionState) {
  const target = document.createElement("div");
  const store = writable(state);
  const controller = {
    subscribe: store.subscribe,
    detach: vi.fn(),
    start,
  } as unknown as SessionStore;

  document.body.append(target);

  const component = mount(Session, {
    target,
    props: { controller },
  });

  flushSync();
  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function sessionWithPhase(
  phase: SessionProjection["phase"],
  permissions: SessionProjection["permissions"] = { can_start_game: true },
): SessionProjection {
  return {
    id: `session-${phase}`,
    phase,
    owner_id: "player-1",
    members: {
      "player-1": {
        status: "online",
        online_at: 1,
        display_name: "Ada Lovelace",
        avatar: "https://example.invalid/ada.png",
      },
      "player-2": {
        status: "offline",
        online_at: 2,
        display_name: "Grace",
        avatar: null,
      },
    },
    permissions,
    game: {},
  };
}

function projectedAttrs() {
  const players = ["ada", "grace", "katherine", "margaret"];

  return Object.fromEntries(
    players.map((player, index) => [
      `turn_order_${index}`,
      {
        id: `turn_order_${index}`,
        name: `turn_order[${index}]`,
        type: "enum",
        label: `Seat ${index + 1}`,
        position: index,
        value: player,
        required: true,
        values: players,
        errors: [],
      },
    ]),
  );
}

function selectByLabel(label: string) {
  const select = [...document.getElementsByTagName("select")].find((candidate) =>
    [...candidate.labels].some((element) => element.textContent?.trim().startsWith(label)),
  );

  if (!select) {
    throw new Error(`Expected select labelled ${label}.`);
  }

  return select;
}
