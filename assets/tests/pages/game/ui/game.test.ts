import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { writable, type Writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { GamePage } from "~/pages/game";
import type { SessionState, SessionStore } from "~/shared/stores";
import type { Attrs, GameMetadata, Session } from "~/shared/types";
import GamePageHarness from "../../../mocks/game_page_harness.svelte";
import inertiaMock from "../../../mocks/inertia";

const sessionMock = vi.hoisted(() => ({
  createSession: vi.fn(),
}));

vi.mock("~/shared/stores", () => ({
  createSession: sessionMock.createSession,
}));

let cleanup: (() => Promise<void>) | undefined;
let waitingController: SessionStore;
let waitingControllerState: Writable<SessionState>;
let waitingDetach = vi.fn<() => void>();

beforeEach(() => {
  waitingControllerState = writable(waitingState("waiting_for_players"));
  waitingDetach = vi.fn();
  waitingController = {
    subscribe: waitingControllerState.subscribe,
    detach: waitingDetach,
    join: vi.fn(),
    start: vi.fn(),
  } as unknown as SessionStore;
  sessionMock.createSession.mockReturnValue(waitingController);
});

const koalaAttrs: Attrs = {
  sheet: {
    id: "attrs_sheet",
    name: "sheet",
    type: "enum",
    value: "dharug",
    required: true,
    values: ["dharug", "yugambeh"],
    errors: [],
  },
};

const nextStationAttrs: Attrs = {
  objectives: {
    id: "attrs_objectives",
    name: "objectives",
    type: "boolean",
    value: false,
    required: true,
    errors: [],
  },
  powers: {
    id: "attrs_powers",
    name: "powers",
    type: "boolean",
    value: false,
    required: true,
    errors: [],
  },
};

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  sessionMock.createSession.mockClear();
});

describe("game detail page", () => {
  it("renders runtime title, preview image, and description", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        name: "Resolved Qwinto",
        categories: ["Dice", "Number"],
        mechanics: ["Dice Rolling", "Paper-and-Pencil"],
        imageUrl: "https://example.invalid/qwinto.jpg",
        description: "Resolved details.",
      }),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.body.textContent).toContain("Resolved Qwinto");
    expect(document.body.textContent).toContain("Resolved details.");
    expect(document.querySelector("img")?.getAttribute("src")).toBe(
      "https://example.invalid/qwinto.jpg",
    );
    expect(document.querySelector('a[href="/games"]')).toBeNull();
    expect(document.querySelector('[aria-label="Categories"]')?.textContent).toContain("Dice");
    expect(document.querySelector('[aria-label="Categories"]')?.textContent).toContain("Number");
    expect(document.querySelector('[aria-label="Mechanics"]')?.textContent).toContain(
      "Dice Rolling",
    );
    expect(document.querySelector('[aria-label="Mechanics"]')?.textContent).toContain(
      "Paper-and-Pencil",
    );
  });

  it("renders provider metadata labels in the activation panel", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        minPlayers: 2,
        maxPlayers: 6,
        playingTime: 30,
        minPlayTime: 20,
        maxPlayTime: 40,
        minAge: 8,
        complexity: 2.14,
        rating: 7.42,
      }),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20-40");
    expect(playTime).not.toContain("min");
    const age = document.querySelector('[aria-label="Age"]');
    expect(age?.textContent).toContain("8+");
    expect(age?.querySelector("svg")).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')?.textContent).toContain("2.1/5");
    expect(document.querySelector('[aria-label="BGG rating"]')?.textContent).toContain("7.4/10");
  });

  it("renders single metadata values without fake ranges", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        minPlayers: 1,
        maxPlayers: 1,
        playingTime: 15,
        minPlayTime: 15,
        maxPlayTime: 15,
      }),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("1");
    expect(document.querySelector('[aria-label="Players"]')?.textContent).not.toContain("1-1");
    expect(document.querySelector('[aria-label="Play time"]')?.textContent).toContain("15");
  });

  it("renders minimum-only play time as an open-ended value", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        playingTime: null,
        minPlayTime: 20,
        maxPlayTime: null,
      }),
      status: "active",
      canLaunchGame: true,
    });

    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20+");
    expect(playTime).not.toContain("min");
  });

  it("omits missing provider metadata labels", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        name: null,
        imageUrl: null,
        thumbnailUrl: null,
        description: null,
        minPlayers: null,
        maxPlayers: null,
        playingTime: null,
        minPlayTime: null,
        maxPlayTime: null,
        minAge: null,
        complexity: null,
        rating: null,
      }),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.body.textContent).toContain("Play");
    expect(document.body.textContent).toContain("Description not listed.");
    expect(document.body.textContent).not.toContain("Not listed");
    expect(document.querySelector('[aria-label="Game metadata"]')).toBeNull();
    expect(document.querySelector('[aria-label="Players"]')).toBeNull();
    expect(document.querySelector('[aria-label="Play time"]')).toBeNull();
    expect(document.querySelector('[aria-label="Age"]')).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')).toBeNull();
    expect(document.querySelector('[aria-label="BGG rating"]')).toBeNull();
    expect(document.querySelector("img")).toBeNull();
  });

  it("keeps available metadata while omitting missing metadata labels", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        minPlayers: 2,
        maxPlayers: 6,
        playingTime: null,
        minPlayTime: null,
        maxPlayTime: null,
        minAge: null,
        complexity: null,
        rating: null,
      }),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    expect(document.querySelector('[aria-label="Play time"]')).toBeNull();
    expect(document.querySelector('[aria-label="Age"]')).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')).toBeNull();
    expect(document.querySelector('[aria-label="BGG rating"]')).toBeNull();
    expect(document.body.textContent).not.toContain("Not listed");
  });

  it("posts session creation to the internal slug route", () => {
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata(),
      status: "active",
      canLaunchGame: true,
    });

    expect(document.querySelector("button")?.textContent).toContain("Play");

    document.querySelector("button")?.click();

    expect(inertiaMock.formSubmit).toHaveBeenCalledWith({
      action: "/games/qwinto/sessions",
      method: "post",
      data: {},
    });
  });

  it("keeps a query session in the lobby until it starts", () => {
    const session = {
      id: "session-a",
      slug: "qwinto",
      topic: "session:session-a",
    };

    render(GamePageHarness, {
      pageProps: {
        slug: "qwinto",
        game: gameMetadata(),
        status: "active",
        canLaunchGame: true,
        session,
      },
    });

    expect(sessionMock.createSession).toHaveBeenCalledWith("session:session-a");
    expect(waitingController.join).toHaveBeenCalledOnce();
    expect(document.body.textContent).toContain("Start");
    expect(document.body.textContent).toContain("Ada");
    expect(document.body.textContent).not.toContain("Play");
  });

  it("returns to Play and detaches the Lobby channel after the session starts", async () => {
    const session = {
      id: "session-a",
      slug: "qwinto",
      topic: "session:session-a",
    };

    render(GamePageHarness, {
      pageProps: {
        slug: "qwinto",
        game: gameMetadata(),
        status: "active",
        canLaunchGame: true,
        session,
      },
    });

    waitingControllerState.set(waitingState("in_progress"));
    flushSync();

    await vi.waitFor(() => {
      expect(inertiaMock.router.get).toHaveBeenCalledWith(
        "/games/qwinto",
        {},
        { preserveScroll: true, replace: true },
      );
    });

    expect(document.body.textContent).toContain("Play");
    expect(document.body.textContent).not.toContain("Start");
    expect(waitingDetach).toHaveBeenCalledOnce();

    await cleanup?.();
    cleanup = undefined;

    expect(waitingDetach).toHaveBeenCalledOnce();
  });

  it("detaches a waiting session when the caller leaves before Start", async () => {
    render(GamePageHarness, {
      pageProps: {
        slug: "qwinto",
        game: gameMetadata(),
        status: "active",
        canLaunchGame: true,
        session: {
          id: "session-a",
          slug: "qwinto",
          topic: "session:session-a",
        },
      },
    });

    await cleanup?.();
    cleanup = undefined;

    expect(waitingDetach).toHaveBeenCalledOnce();
  });

  it("posts selected creation attrs when creating a session", () => {
    render(GamePage, {
      slug: "koala-rescue-club",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      attrs: koalaAttrs,
      status: "in_progress",
      canLaunchGame: true,
    });

    const defaultOption = document.querySelector('input[value="dharug"]');
    const selectedOption = document.querySelector('input[value="yugambeh"]');

    if (!(defaultOption instanceof HTMLInputElement)) {
      throw new Error("Expected Dharug radio option.");
    }

    if (!(selectedOption instanceof HTMLInputElement)) {
      throw new Error("Expected Yugambeh radio option.");
    }

    expect(defaultOption.checked).toBe(true);

    selectedOption.click();
    document.querySelector("button")?.click();

    expect(inertiaMock.formSubmit).toHaveBeenCalledWith({
      action: "/games/koala-rescue-club/sessions",
      method: "post",
      data: { sheet: "yugambeh" },
    });
  });

  it("renders boolean creation attrs as checkboxes and posts their values", () => {
    render(GamePage, {
      slug: "next-station-london",
      game: gameMetadata({ name: "Next Station London" }),
      attrs: nextStationAttrs,
      status: "active",
      canLaunchGame: true,
    });

    const objectives = inputByLabel("Objectives");
    const powers = inputByLabel("Powers");

    expect(objectives.type).toBe("checkbox");
    expect(powers.type).toBe("checkbox");
    expect(objectives.checked).toBe(false);
    expect(powers.checked).toBe(false);
    expect(objectives.required).toBe(false);
    expect(powers.required).toBe(false);

    powers.click();
    document.querySelector("button")?.click();

    expect(inertiaMock.formSubmit).toHaveBeenCalledWith({
      action: "/games/next-station-london/sessions",
      method: "post",
      data: { objectives: "false", powers: "true" },
    });
  });

  it("keeps game details visible without session controls when launch is unavailable", () => {
    render(GamePage, {
      slug: "voyages",
      status: null,
      canLaunchGame: false,
      game: gameMetadata({ name: "Voyages", description: "Chart a course." }),
    });

    expect(document.body.textContent).toContain("Voyages");
    expect(document.body.textContent).toContain("Chart a course.");
    expect(document.querySelector("form")).toBeNull();
    expect(document.querySelector("button")).toBeNull();
  });
});

function render(Component: unknown, props: Record<string, unknown>) {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() =>
    mount(Component as SvelteComponent<Record<string, unknown>>, { target, props }),
  );

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function inputByLabel(label: string) {
  const input = [...document.getElementsByTagName("input")].find((candidate) =>
    [...(candidate.labels ?? [])].some((element) => element.textContent?.trim() === label),
  );

  if (!input) {
    throw new Error(`Expected input labelled ${label}.`);
  }

  return input;
}

function gameMetadata(overrides: Partial<GameMetadata> = {}): GameMetadata {
  return {
    name: "Qwinto",
    alternateNames: [],
    categories: [],
    mechanics: [],
    description: "Details.",
    thumbnailUrl: null,
    imageUrl: null,
    yearPublished: 2015,
    minPlayers: 2,
    maxPlayers: 6,
    playingTime: 15,
    minPlayTime: 15,
    maxPlayTime: 15,
    minAge: 8,
    complexity: 2.1,
    rating: 7.4,
    ...overrides,
  };
}

function waitingState(phase: Session["phase"]): SessionState {
  return {
    value: {
      id: "session-a",
      phase,
      owner_id: "actor-a",
      members: {
        "actor-a": {
          status: "online",
          display_name: "Ada",
          avatar: null,
          online_at: 1,
        },
      },
      permissions: { can_start_game: true },
      game: {},
    },
    status: "ready",
    error: null,
    processing: { join: false, start: false },
    errors: { join: null, start: null },
    timeouts: { join: false, start: false },
  };
}
