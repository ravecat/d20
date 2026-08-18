import { fireEvent, render } from "@testing-library/svelte";
import { flushSync } from "svelte";
import { writable, type Writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Schema } from "@sjsf/form";
import { GamePage } from "~/pages/game";
import type { SessionState, SessionStore } from "~/shared/stores";
import type { GameMetadata, Session } from "~/shared/types";
import inertiaMock from "../../../mocks/inertia";

const sessionMock = vi.hoisted(() => ({
  createSession: vi.fn(),
}));

const auth = {
  authenticated: false,
  local: false,
  prompt: null,
  providers: {
    apple: { available: false },
    discord: { available: true },
    google: { available: true },
  },
};

const emptySchema: Schema = {
  type: "object",
  properties: {},
  default: {},
};

vi.mock("~/shared/stores", () => ({
  createSession: sessionMock.createSession,
}));

let waitingController: SessionStore;
let waitingControllerState: Writable<SessionState>;
let waitingDetach = vi.fn<() => void>();

beforeEach(() => {
  waitingControllerState = writable(waitingState("waiting_for_players"));
  waitingDetach = vi.fn();
  waitingController = {
    subscribe: waitingControllerState.subscribe,
    detach: waitingDetach,
    start: vi.fn(),
  } as unknown as SessionStore;
  sessionMock.createSession.mockReturnValue(waitingController);
});

const koalaSchema: Schema = {
  type: "object",
  properties: {
    sheet: { type: "string", enum: ["dharug", "yugambeh"] },
  },
  required: ["sheet"],
  default: { sheet: "dharug" },
};

const nextStationSchema: Schema = {
  type: "object",
  properties: {
    objectives: { type: "boolean" },
    powers: { type: "boolean" },
  },
  required: ["objectives", "powers"],
  default: { objectives: false, powers: false },
};

afterEach(() => {
  sessionMock.createSession.mockClear();
});

describe("game detail page", () => {
  it("renders runtime title, preview image, and description", () => {
    render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata({
        name: "Resolved Qwinto",
        categories: ["Dice", "Number"],
        mechanics: ["Dice Rolling", "Paper-and-Pencil"],
        imageUrl: "https://example.invalid/qwinto.jpg",
        description: "Resolved details.",
      }),
      canLaunchGame: true,
      schema: emptySchema,
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
      auth,
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
      canLaunchGame: true,
      schema: emptySchema,
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
      auth,
      slug: "qwinto",
      game: gameMetadata({
        minPlayers: 1,
        maxPlayers: 1,
        playingTime: 15,
        minPlayTime: 15,
        maxPlayTime: 15,
      }),
      canLaunchGame: true,
      schema: emptySchema,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("1");
    expect(document.querySelector('[aria-label="Players"]')?.textContent).not.toContain("1-1");
    expect(document.querySelector('[aria-label="Play time"]')?.textContent).toContain("15");
  });

  it("renders minimum-only play time as an open-ended value", () => {
    render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata({
        playingTime: null,
        minPlayTime: 20,
        maxPlayTime: null,
      }),
      canLaunchGame: true,
      schema: emptySchema,
    });

    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20+");
    expect(playTime).not.toContain("min");
  });

  it("omits missing provider metadata labels", () => {
    render(GamePage, {
      auth,
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
      canLaunchGame: true,
      schema: emptySchema,
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
      auth,
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
      canLaunchGame: true,
      schema: emptySchema,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    expect(document.querySelector('[aria-label="Play time"]')).toBeNull();
    expect(document.querySelector('[aria-label="Age"]')).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')).toBeNull();
    expect(document.querySelector('[aria-label="BGG rating"]')).toBeNull();
    expect(document.body.textContent).not.toContain("Not listed");
  });

  it("posts session creation to the internal slug route", async () => {
    render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata(),
      canLaunchGame: true,
      schema: emptySchema,
    });

    expect(document.querySelector("button")?.textContent).toContain("Play");

    document.querySelector("button")?.click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        "/games/qwinto/sessions",
        {},
        expect.objectContaining({ errorBag: "session" }),
      );
    });
  });

  it("keeps a query session in the lobby until it starts", () => {
    const session = {
      id: "session-a",
      slug: "qwinto",
      topic: "session:session-a",
    };

    render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata(),
      canLaunchGame: true,
      schema: emptySchema,
      session,
    });

    expect(sessionMock.createSession).toHaveBeenCalledWith("session:session-a");
    expect(document.body.textContent).toContain("Start");
    expect(document.body.textContent).toContain("Ada");
    expect(document.body.textContent).not.toContain("Play");
  });

  it("requests a page refresh without detaching the active lobby", async () => {
    const session = {
      id: "session-a",
      slug: "qwinto",
      topic: "session:session-a",
    };

    const { unmount } = render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata(),
      canLaunchGame: true,
      schema: emptySchema,
      session,
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

    expect(document.body.textContent).not.toContain("Play");
    expect(document.body.textContent).not.toContain("Start");
    expect(waitingDetach).not.toHaveBeenCalled();

    unmount();

    expect(waitingDetach).toHaveBeenCalledOnce();
  });

  it("detaches a waiting session when the caller leaves before Start", () => {
    const { unmount } = render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata(),
      canLaunchGame: true,
      schema: emptySchema,
      session: {
        id: "session-a",
        slug: "qwinto",
        topic: "session:session-a",
      },
    });

    unmount();

    expect(waitingDetach).toHaveBeenCalledOnce();
  });

  it("posts a selected enum value from the creation form schema", async () => {
    const { getByRole } = render(GamePage, {
      auth,
      slug: "koala-rescue-club",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      schema: koalaSchema,
      canLaunchGame: true,
    });

    const defaultSheet = getByRole("radio", { name: "dharug" }) as HTMLInputElement;
    const selectedSheet = getByRole("radio", { name: "yugambeh" }) as HTMLInputElement;

    expect(defaultSheet.checked).toBe(true);
    expect(selectedSheet.checked).toBe(false);

    await fireEvent.click(selectedSheet);
    document.querySelector("button")?.click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        "/games/koala-rescue-club/sessions",
        { sheet: "yugambeh" },
        expect.any(Object),
      );
    });
  });

  it("shows an Inertia field error on the SJSF control", async () => {
    render(GamePage, {
      auth,
      slug: "koala-rescue-club",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      schema: koalaSchema,
      canLaunchGame: true,
    });

    document.querySelector("button")?.click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledOnce();
    });

    const onError = inertiaMock.router.post.mock.calls[0]?.[2]?.onError;

    if (!onError) {
      throw new Error("Expected an Inertia error callback.");
    }

    onError({ sheet: "is invalid" });
    flushSync();

    expect(document.body.textContent).toContain("is invalid");
  });

  it("shows an Inertia session error outside the SJSF controls", () => {
    Object.assign(inertiaMock.page.props.errors, {
      session: { session: "Could not start session." },
    });

    render(GamePage, {
      auth,
      slug: "qwinto",
      game: gameMetadata(),
      canLaunchGame: true,
      schema: emptySchema,
    });

    expect(document.body.textContent).toContain("Could not start session.");
  });

  it("renders boolean schema properties as checkboxes and posts typed values", async () => {
    render(GamePage, {
      auth,
      slug: "next-station-london",
      game: gameMetadata({ name: "Next Station London" }),
      schema: nextStationSchema,
      canLaunchGame: true,
    });

    const objectives = inputByLabel("objectives");
    const powers = inputByLabel("powers");

    expect(objectives.type).toBe("checkbox");
    expect(powers.type).toBe("checkbox");
    expect(objectives.checked).toBe(false);
    expect(powers.checked).toBe(false);
    powers.click();
    document.querySelector("button")?.click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        "/games/next-station-london/sessions",
        { objectives: false, powers: true },
        expect.any(Object),
      );
    });
  });

  it("keeps game details visible without session controls when launch is unavailable", () => {
    render(GamePage, {
      auth,
      slug: "voyages",
      canLaunchGame: false,
      schema: null,
      game: gameMetadata({ name: "Voyages", description: "Chart a course." }),
    });

    expect(document.body.textContent).toContain("Voyages");
    expect(document.body.textContent).toContain("Chart a course.");
    expect(document.querySelector("form")).toBeNull();
    expect(document.querySelector("button")).toBeNull();
  });
});

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
    processing: { start: false },
    errors: { start: null },
    timeouts: { start: false },
  };
}
