import { fireEvent, render, screen } from "@testing-library/svelte";
import { flushSync } from "svelte";
import { writable, type Writable } from "svelte/store";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Schema } from "@sjsf/form";
import { GamePage } from "~/pages/game";
import type { SessionState, SessionStore } from "~/shared/stores";
import type { GameMetadata, Session } from "~/shared/types/game";
import inertiaMock from "../../../mocks/inertia";
import { auth as authStore } from "~/shared/stores/auth";

const qwintoId = "game_01h45yhtgqfhxbcrsfbhxdsdvy";
const koalaId = "game_01h45y0sxkfmntta78gqs1vsw6";
const nextStationId = "game_01h45ykcj8exz9cknf3mj4z6bx";
const voyagesId = "game_01h45ybmy7fj7b4r9vvp74ms6k";

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
    facebook: { available: false },
    google: { available: true },
    steam: { available: false },
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
  authStore.trigger.reset();
  vi.unstubAllGlobals();
});

describe("game detail page", () => {
  it("submits the hero through Inertia and reads saved state from server props", async () => {
    const props = {
      auth: { ...auth, authenticated: true },
      id: null,
      slug: "350736",
      stage: null,
      favorite: {
        bggId: 350736,
        action: "/favorites/350736",
        slug: "350736",
      },
      favorites: [] as number[],
      playable: false,
      interest: {
        action: "/games/350736/interest",
        requested: false,
        count: 0,
      },
      schema: null,
      session: null,
      game: gameMetadata({ name: "Voyages" }),
    };
    inertiaMock.setPage({
      url: "/games/350736?session=table",
      props: { ...inertiaMock.page.props, auth: props.auth },
    });
    const { rerender } = render(GamePage, props);
    const favoriteButton = screen.getByRole("button", {
      name: "Add Voyages to favorites",
    });
    expect(favoriteButton.textContent?.trim()).toBe("");
    await fireEvent.click(favoriteButton);
    expect(favoriteButton.textContent?.trim()).toBe("");
    expect(favoriteButton.getAttribute("aria-busy")).toBe("true");
    expect(favoriteButton.getAttribute("aria-disabled")).toBe("true");
    await fireEvent.click(favoriteButton);
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/favorites/350736",
      method: "put",
      data: { slug: "350736", response_to: "/games/350736?session=table" },
      options: expect.objectContaining({
        only: ["favorites", "auth", "errors"],
        preserveState: true,
        preserveScroll: true,
      }),
    });
    expect(
      screen.getByRole("button", { name: "Add Voyages to favorites" }).getAttribute("aria-pressed"),
    ).toBe("false");
    inertiaMock.setPage({
      props: { ...inertiaMock.page.props, favorites: [350736] },
    });
    await rerender({ ...props, favorites: [350736] });
    inertiaMock.respondWithSuccess();
    flushSync();
    expect(favoriteButton.textContent?.trim()).toBe("");
    expect(screen.queryByRole("status")).toBeNull();
    expect(screen.queryByRole("alert")).toBeNull();
    expect(
      screen
        .getByRole("button", { name: "Remove Voyages from favorites" })
        .getAttribute("aria-pressed"),
    ).toBe("true");
    await fireEvent.click(screen.getByRole("button", { name: "Remove Voyages from favorites" }));
    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith(
      expect.objectContaining({
        action: "/favorites/350736",
        method: "delete",
        data: { response_to: "/games/350736?session=table" },
      }),
    );
    expect(favoriteButton.textContent?.trim()).toBe("");
    expect(favoriteButton.getAttribute("aria-busy")).toBe("true");
    expect(favoriteButton.getAttribute("aria-disabled")).toBe("true");
    expect(favoriteButton.getAttribute("aria-label")).toBe("Remove Voyages from favorites");
    inertiaMock.respondWithNetworkError();
    flushSync();
    expect(screen.queryByRole("alert")).toBeNull();
    expect(screen.queryByRole("status")).toBeNull();
    expect(
      screen
        .getByRole("button", { name: "Remove Voyages from favorites" })
        .getAttribute("aria-disabled"),
    ).toBe("false");
    expect(
      screen
        .getByRole("button", { name: "Remove Voyages from favorites" })
        .getAttribute("aria-pressed"),
    ).toBe("true");
    expect(sessionMock.createSession).not.toHaveBeenCalled();
  });

  it("uses fresh account props and prompts guests or expired sessions without replay", async () => {
    const props = {
      auth,
      id: null,
      slug: "350736",
      stage: null,
      favorite: {
        bggId: 350736,
        action: "/favorites/350736",
        slug: "350736",
      },
      favorites: [] as number[],
      playable: false,
      interest: {
        action: "/games/350736/interest",
        requested: false,
        count: 0,
      },
      schema: null,
      session: null,
      game: gameMetadata({ name: "Voyages" }),
    };
    inertiaMock.setPage({ props: { ...inertiaMock.page.props, auth } });
    const { rerender } = render(GamePage, props);
    await fireEvent.click(screen.getByRole("button", { name: "Add Voyages to favorites" }));
    expect(authStore.getSnapshot().context.open).toBe(true);
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
    authStore.trigger.close();
    inertiaMock.setPage({
      props: { ...inertiaMock.page.props, auth: { ...auth, authenticated: true } },
    });
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
    await fireEvent.click(screen.getByRole("button", { name: "Add Voyages to favorites" }));
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
    inertiaMock.respondWithSuccess();
    flushSync();
    inertiaMock.setPage({ props: { ...inertiaMock.page.props, auth } });
    await fireEvent.click(screen.getByRole("button", { name: "Add Voyages to favorites" }));
    expect(authStore.getSnapshot().context.open).toBe(true);
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
    authStore.trigger.close();
    inertiaMock.setPage({
      props: { ...inertiaMock.page.props, auth: { ...auth, authenticated: true } },
    });
    await rerender({ ...props, favorites: [350736] });
    expect(
      screen
        .getByRole("button", { name: "Remove Voyages from favorites" })
        .getAttribute("aria-pressed"),
    ).toBe("true");
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
    await fireEvent.click(screen.getByRole("button", { name: "Remove Voyages from favorites" }));
    inertiaMock.respondWithErrors({
      authentication: "Sign in to save favorites.",
    });
    inertiaMock.setPage({ props: { ...inertiaMock.page.props, auth } });
    await rerender(props);
    expect(authStore.getSnapshot().context.open).toBe(true);
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(2);
    expect(
      screen.getByRole("button", { name: "Add Voyages to favorites" }).getAttribute("aria-pressed"),
    ).toBe("false");
  });

  it("renders runtime title, preview image, and description", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata({
        name: "Resolved Qwinto",
        categories: ["Dice", "Number"],
        mechanics: ["Dice Rolling", "Paper-and-Pencil"],
        imageUrl: "https://example.invalid/qwinto.jpg",
        description: "Resolved details.",
      }),
      playable: true,
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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
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
      playable: true,
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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata({
        minPlayers: 1,
        maxPlayers: 1,
        playingTime: 15,
        minPlayTime: 15,
        maxPlayTime: 15,
      }),
      playable: true,
      schema: emptySchema,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("1");
    expect(document.querySelector('[aria-label="Players"]')?.textContent).not.toContain("1-1");
    expect(document.querySelector('[aria-label="Play time"]')?.textContent).toContain("15");
  });

  it("renders minimum-only play time as an open-ended value", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata({
        playingTime: null,
        minPlayTime: 20,
        maxPlayTime: null,
      }),
      playable: true,
      schema: emptySchema,
    });

    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20+");
    expect(playTime).not.toContain("min");
  });

  it("omits missing provider metadata labels", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
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
      playable: true,
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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
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
      playable: true,
      schema: emptySchema,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    expect(document.querySelector('[aria-label="Play time"]')).toBeNull();
    expect(document.querySelector('[aria-label="Age"]')).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')).toBeNull();
    expect(document.querySelector('[aria-label="BGG rating"]')).toBeNull();
    expect(document.body.textContent).not.toContain("Not listed");
  });

  it("posts session creation to the slug-based route", async () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata(),
      playable: true,
      schema: emptySchema,
    });

    expect(screen.getByRole("button", { name: "Play" }).textContent).toContain("Play");

    screen.getByRole("button", { name: "Play" }).click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        `/games/qwinto/sessions`,
        {},
        expect.objectContaining({ errorBag: "session" }),
      );
    });
  });

  it("saves only game data while retaining the query session and active lobby", async () => {
    inertiaMock.setPage({
      url: "/games/qwinto?session=session-a",
      props: { ...inertiaMock.page.props, auth: { ...auth, authenticated: true } },
    });
    const session = {
      id: "session-a",
      gameId: qwintoId,
      slug: "qwinto",
      topic: "session:session-a",
    };

    render(GamePage, {
      auth: { ...auth, authenticated: true },
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata(),
      playable: true,
      schema: emptySchema,
      session,
    });

    expect(sessionMock.createSession).toHaveBeenCalledWith("session:session-a");
    expect(document.body.textContent).toContain("Start");
    expect(document.body.textContent).toContain("Ada");
    expect(document.body.textContent).not.toContain("Play");
    await fireEvent.click(screen.getByRole("button", { name: "Add Qwinto to favorites" }));
    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith(
      expect.objectContaining({
        action: "/favorites/183006",
        method: "put",
        data: {
          slug: "qwinto",
          response_to: "/games/qwinto?session=session-a",
        },
      }),
    );
    expect(waitingDetach).not.toHaveBeenCalled();
    expect(screen.getByRole("button", { name: "Start" })).toBeTruthy();
    expect(screen.getByText("Ada")).toBeTruthy();
  });

  it("requests a page refresh without detaching the active lobby", async () => {
    const session = {
      id: "session-a",
      gameId: qwintoId,
      slug: "qwinto",
      topic: "session:session-a",
    };

    const { unmount } = render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata(),
      playable: true,
      schema: emptySchema,
      session,
    });

    waitingControllerState.set(waitingState("in_progress"));
    flushSync();

    await vi.waitFor(() => {
      expect(inertiaMock.router.get).toHaveBeenCalledWith(
        `/games/qwinto`,
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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata(),
      playable: true,
      schema: emptySchema,
      session: {
        id: "session-a",
        gameId: qwintoId,
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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: koalaId,
      slug: "koala-rescue-club",
      favorite: {
        bggId: 360471,
        action: "/favorites/360471",
        slug: "koala-rescue-club",
      },
      stage: "released",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      schema: koalaSchema,
      playable: true,
    });

    const defaultSheet = getByRole("radio", {
      name: "dharug",
    }) as HTMLInputElement;
    const selectedSheet = getByRole("radio", {
      name: "yugambeh",
    }) as HTMLInputElement;

    expect(defaultSheet.checked).toBe(true);
    expect(selectedSheet.checked).toBe(false);

    await fireEvent.click(selectedSheet);
    screen.getByRole("button", { name: "Play" }).click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        `/games/koala-rescue-club/sessions`,
        { sheet: "yugambeh" },
        expect.any(Object),
      );
    });
  });

  it("shows an Inertia field error on the SJSF control", async () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: koalaId,
      slug: "koala-rescue-club",
      favorite: {
        bggId: 360471,
        action: "/favorites/360471",
        slug: "koala-rescue-club",
      },
      stage: "released",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      schema: koalaSchema,
      playable: true,
    });

    screen.getByRole("button", { name: "Play" }).click();

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
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      game: gameMetadata(),
      playable: true,
      schema: emptySchema,
    });

    expect(document.body.textContent).toContain("Could not start session.");
  });

  it("renders boolean schema properties as checkboxes and posts typed values", async () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: nextStationId,
      slug: "next-station-london",
      favorite: {
        bggId: 353545,
        action: "/favorites/353545",
        slug: "next-station-london",
      },
      stage: "in_development",
      game: gameMetadata({ name: "Next Station London" }),
      schema: nextStationSchema,
      playable: true,
    });

    const objectives = inputByLabel("objectives");
    const powers = inputByLabel("powers");

    expect(objectives.type).toBe("checkbox");
    expect(powers.type).toBe("checkbox");
    expect(objectives.checked).toBe(false);
    expect(powers.checked).toBe(false);
    powers.click();
    screen.getByRole("button", { name: "Play" }).click();

    await vi.waitFor(() => {
      expect(inertiaMock.router.post).toHaveBeenCalledWith(
        `/games/next-station-london/sessions`,
        { objectives: false, powers: true },
        expect.any(Object),
      );
    });
  });

  it("does not infer interest eligibility from a missing playable schema", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/qwinto/interest",
        requested: false,
        count: 0,
      },
      id: qwintoId,
      slug: "qwinto",
      favorite: {
        bggId: 183006,
        action: "/favorites/183006",
        slug: "qwinto",
      },
      stage: "released",
      playable: true,
      schema: null,
      game: gameMetadata(),
    });

    expect(screen.queryByRole("button", { name: "I want this game!" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Play" })).toBeNull();
    expect(screen.getByRole("button", { name: "Add Qwinto to favorites" })).toBeTruthy();
  });

  it("renders the interest form for provider-only details", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/350736/interest",
        requested: false,
        count: 0,
      },
      id: null,
      slug: "350736",
      favorite: {
        bggId: 350736,
        action: "/favorites/350736",
        slug: "350736",
      },
      stage: null,
      playable: false,
      schema: null,
      session: null,
      game: gameMetadata({ name: "Voyages", description: "Chart a course." }),
    });

    expect(screen.getByRole("heading", { name: "Voyages", level: 1 })).toBeTruthy();
    expect(screen.getByText("Chart a course.")).toBeTruthy();
    expect(screen.getByLabelText("Players").textContent).toContain("2-6");
    expect(screen.getByRole("button", { name: "I want this game!" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Play" })).toBeNull();
    expect(screen.getByRole("button", { name: "Add Voyages to favorites" })).toBeTruthy();
    expect(sessionMock.createSession).not.toHaveBeenCalled();
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  });

  it("keeps game details visible with the interest form when play is unavailable", () => {
    render(GamePage, {
      auth,
      interest: {
        action: "/games/voyages/interest",
        requested: false,
        count: 0,
      },
      id: voyagesId,
      slug: "voyages",
      favorite: {
        bggId: 350736,
        action: "/favorites/350736",
        slug: "voyages",
      },
      stage: "in_development",
      playable: false,
      schema: null,
      game: gameMetadata({ name: "Voyages", description: "Chart a course." }),
    });

    expect(document.body.textContent).toContain("Voyages");
    expect(document.body.textContent).toContain("Chart a course.");
    expect(screen.getByRole("button", { name: "I want this game!" })).toBeTruthy();
    expect(screen.queryByRole("button", { name: "Play" })).toBeNull();
    expect(screen.getByRole("button", { name: "Add Voyages to favorites" })).toBeTruthy();
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
