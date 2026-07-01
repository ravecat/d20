import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { afterEach, describe, expect, it } from "vitest";
import GamePage from "~pages/game.svelte";
import HomePage from "~pages/home.svelte";
import type { GameCatalogEntry, GameMetadata } from "~types/game";
import inertiaMock from "../test/mocks/inertia";

let cleanup: (() => Promise<void>) | undefined;

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("home page", () => {
  it("renders game tiles with preview images and slug links", () => {
    render(HomePage, {
      games: [
        catalogEntry(
          gameMetadata({
            name: "Qwinto",
            categories: ["Dice", "Number"],
            mechanics: ["Dice Rolling", "Paper-and-Pencil"],
            thumbnailUrl: "https://example.invalid/qwinto-thumb.jpg",
            imageUrl: "https://example.invalid/qwinto-image.jpg",
          }),
        ),
      ],
    });

    const link = document.querySelector("a");
    const image = document.querySelector("img");
    const preview = document.querySelector(".game-preview");
    const titleChip = document.querySelector(".game-title-chip");
    const categoryChips = document.querySelectorAll(".game-metadata-chip--category");
    const mechanicChips = document.querySelectorAll(".game-metadata-chip--mechanic");

    expect(link?.getAttribute("href")).toBe("/games/qwinto");
    expect(document.body.textContent).toContain("Qwinto");
    expect(image?.getAttribute("src")).toBe("https://example.invalid/qwinto-image.jpg");
    expect(preview?.contains(titleChip)).toBe(true);
    expect(titleChip?.textContent).toBe("Qwinto");
    expect([...categoryChips].map((chip) => chip.textContent)).toEqual(["Dice", "Number"]);
    expect(mechanicChips).toHaveLength(0);
  });

  it("renders fallback preview state when metadata has no image", () => {
    render(HomePage, {
      games: [catalogEntry(gameMetadata({ thumbnailUrl: null, imageUrl: null }))],
    });

    expect(document.body.textContent).toContain("Qwinto");
    expect(document.querySelector("img")).toBeNull();
    expect(document.querySelector("a")?.getAttribute("href")).toBe("/games/qwinto");
  });
});

describe("game detail page", () => {
  it("renders runtime title, preview image, and description", () => {
    inertiaMock.prepareForm();

    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        name: "Resolved Qwinto",
        categories: ["Dice", "Number"],
        mechanics: ["Dice Rolling", "Paper-and-Pencil"],
        imageUrl: "https://example.invalid/qwinto.jpg",
        description: "Resolved details.",
      }),
      module: null,
      connection: null,
      session: null,
    });

    expect(document.body.textContent).toContain("Resolved Qwinto");
    expect(document.body.textContent).toContain("Resolved details.");
    expect(document.querySelector("img")?.getAttribute("src")).toBe(
      "https://example.invalid/qwinto.jpg",
    );
    expect(document.querySelector('a[href="/games"]')).toBeNull();
    expect(document.querySelector(".game-detail-preview img")).not.toBeNull();
    expect(document.querySelector(".game-detail-chip")?.textContent).toBe("Resolved Qwinto");
    expect(document.querySelector(".game-detail-description")?.textContent).toBe(
      "Resolved details.",
    );
    expect(document.querySelector(".game-detail-layout")).not.toBeNull();
    expect(document.querySelector(".game-detail-description-panel")).not.toBeNull();
    expect(document.querySelector(".game-detail-activation")).not.toBeNull();
    expect(document.querySelector(".game-detail-layout")?.children[0]?.classList).toContain(
      "game-detail-activation",
    );
    expect(document.querySelector(".game-detail-layout")?.children[1]?.classList).toContain(
      "game-detail-description-panel",
    );
    expect(
      document
        .querySelector(".game-detail-preview")
        ?.contains(document.querySelector(".game-detail-metadata")),
    ).toBe(true);
    expect(
      [...document.querySelectorAll(".game-detail-metadata__block")].map((block) =>
        block.getAttribute("aria-label"),
      ),
    ).toEqual(["Categories", "Mechanics"]);
    expect(
      [...document.querySelectorAll(".game-detail-metadata__chip--mechanic")].map(
        (chip) => chip.textContent,
      ),
    ).toEqual(["Dice Rolling", "Paper-and-Pencil"]);
    expect(
      [...document.querySelectorAll(".game-detail-metadata__chip--category")].map(
        (chip) => chip.textContent,
      ),
    ).toEqual(["Dice", "Number"]);
  });

  it("renders provider metadata labels in the activation panel", () => {
    inertiaMock.prepareForm();

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
      module: null,
      connection: null,
      session: null,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20-40");
    expect(playTime).not.toContain("min");
    const age = document.querySelector('[aria-label="Age"]');
    expect(age?.textContent).toContain("8+");
    expect(age?.querySelector(".game-metadata-label__age-value")).toBeNull();
    expect(age?.querySelector("svg")).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')?.textContent).toContain("2.1/5");
    expect(document.querySelector('[aria-label="BGG rating"]')?.textContent).toContain("7.4/10");
  });

  it("renders single metadata values without fake ranges", () => {
    inertiaMock.prepareForm();

    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        minPlayers: 1,
        maxPlayers: 1,
        playingTime: 15,
        minPlayTime: 15,
        maxPlayTime: 15,
      }),
      module: null,
      connection: null,
      session: null,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("1");
    expect(document.querySelector('[aria-label="Players"]')?.textContent).not.toContain("1-1");
    expect(document.querySelector('[aria-label="Play time"]')?.textContent).toContain("15");
  });

  it("renders minimum-only play time as an open-ended value", () => {
    inertiaMock.prepareForm();

    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata({
        playingTime: null,
        minPlayTime: 20,
        maxPlayTime: null,
      }),
      module: null,
      connection: null,
      session: null,
    });

    const playTime = document.querySelector('[aria-label="Play time"]')?.textContent;
    expect(playTime).toContain("20+");
    expect(playTime).not.toContain("min");
  });

  it("omits missing provider metadata labels", () => {
    inertiaMock.prepareForm();

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
      module: null,
      connection: null,
      session: null,
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
    expect(document.querySelector(".game-detail-chip")).toBeNull();
  });

  it("keeps available metadata while omitting missing metadata labels", () => {
    inertiaMock.prepareForm();

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
      module: null,
      connection: null,
      session: null,
    });

    expect(document.querySelector('[aria-label="Players"]')?.textContent).toContain("2-6");
    expect(document.querySelector('[aria-label="Play time"]')).toBeNull();
    expect(document.querySelector('[aria-label="Age"]')).toBeNull();
    expect(document.querySelector('[aria-label="Complexity"]')).toBeNull();
    expect(document.querySelector('[aria-label="BGG rating"]')).toBeNull();
    expect(document.body.textContent).not.toContain("Not listed");
  });

  it("posts session creation to the internal slug route", () => {
    const form = inertiaMock.prepareForm();

    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata(),
      module: null,
      connection: null,
      session: null,
    });

    expect(document.querySelector("button")?.textContent).toContain("Play");

    document.querySelector("button")?.click();
    flushSync();

    expect(form.clearErrors).toHaveBeenCalled();
    expect(form.post).toHaveBeenCalledWith("/games/qwinto/sessions");
  });
});

function render(Component: unknown, props: Record<string, unknown>) {
  const target = document.createElement("div");
  document.body.append(target);

  const component = mount(Component as SvelteComponent<Record<string, unknown>>, { target, props });
  flushSync();

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
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

function catalogEntry(game: GameMetadata): GameCatalogEntry {
  return {
    slug: "qwinto",
    game,
  };
}
