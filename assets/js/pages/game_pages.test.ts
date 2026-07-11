import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { afterEach, describe, expect, it } from "vitest";
import GamePage from "~pages/game.svelte";
import HomePage from "~pages/home.svelte";
import type { Attrs, GameMetadata } from "~types/game";
import inertiaMock from "../test/mocks/inertia";

let cleanup: (() => Promise<void>) | undefined;

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

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("home page", () => {
  it("renders game tiles with preview images and slug links", () => {
    render(HomePage, {
      games: [
        {
          slug: "qwinto",
          status: "active",
          game: gameMetadata({
            name: "Qwinto",
            categories: ["Dice", "Number"],
            mechanics: ["Dice Rolling", "Paper-and-Pencil"],
            thumbnailUrl: "https://example.invalid/qwinto-thumb.jpg",
            imageUrl: "https://example.invalid/qwinto-image.jpg",
          }),
        },
      ],
    });

    const [link] = document.links;
    const [image] = document.images;
    const title = link?.querySelector("h2");
    const visibleText = link?.textContent ?? "";

    expect(link?.getAttribute("href")).toBe("/games/qwinto");
    expect(title?.textContent).toBe("Qwinto");
    expect(image?.getAttribute("src")).toBe("https://example.invalid/qwinto-image.jpg");
    expect(visibleText).toContain("Qwinto");
    expect(visibleText).toContain("Dice");
    expect(visibleText).toContain("Number");
    expect(visibleText).not.toContain("Dice Rolling");
    expect(visibleText).not.toContain("Paper-and-Pencil");
    expect(visibleText).not.toContain("Soon");
  });

  it("renders fallback preview state when metadata has no image", () => {
    render(HomePage, {
      games: [
        {
          slug: "qwinto",
          status: null,
          game: gameMetadata({ thumbnailUrl: null, imageUrl: null }),
        },
      ],
    });

    const [link] = document.links;

    expect(link?.textContent).toContain("Qwinto");
    expect(document.images).toHaveLength(0);
    expect(link?.getAttribute("href")).toBe("/games/qwinto");
  });

  it("renders the Soon label for in-progress games", () => {
    render(HomePage, {
      games: [
        {
          slug: "koala-rescue-club",
          status: "in_progress",
          game: gameMetadata({ name: "Koala Rescue Club" }),
        },
      ],
    });

    const [link] = document.links;

    expect(link?.getAttribute("href")).toBe("/games/koala-rescue-club");
    expect(link?.querySelector("h2")?.textContent).toBe("Koala Rescue Club");
    expect(link?.textContent).toContain("Koala Rescue Club");
    expect(link?.textContent).toContain("Soon");
  });

  it("renders games in the received catalog order", () => {
    render(HomePage, {
      games: [
        {
          slug: "inactive-first",
          status: null,
          game: gameMetadata({ name: "Inactive First" }),
        },
        {
          slug: "active-first",
          status: "active",
          game: gameMetadata({ name: "Active First" }),
        },
        {
          slug: "soon-first",
          status: "in_progress",
          game: gameMetadata({ name: "Soon First" }),
        },
        {
          slug: "active-second",
          status: "active",
          game: gameMetadata({ name: "Active Second" }),
        },
        {
          slug: "inactive-second",
          status: null,
          game: gameMetadata({ name: "Inactive Second" }),
        },
        {
          slug: "soon-second",
          status: "in_progress",
          game: gameMetadata({ name: "Soon Second" }),
        },
      ],
    });

    expect([...document.querySelectorAll("h2")].map((title) => title.textContent)).toEqual([
      "Inactive First",
      "Active First",
      "Soon First",
      "Active Second",
      "Inactive Second",
      "Soon Second",
    ]);
  });
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
      module: null,
      connection: null,
      session: null,
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
      module: null,
      connection: null,
      session: null,
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
    render(GamePage, {
      slug: "qwinto",
      game: gameMetadata(),
      status: "active",
      canLaunchGame: true,
      module: null,
      connection: null,
      session: null,
    });

    expect(document.querySelector("button")?.textContent).toContain("Play");

    document.querySelector("button")?.click();

    expect(inertiaMock.formSubmit).toHaveBeenCalledWith({
      action: "/games/qwinto/sessions",
      method: "post",
      data: {},
    });
  });

  it("posts selected creation attrs when creating a session", () => {
    render(GamePage, {
      slug: "koala-rescue-club",
      game: gameMetadata({ name: "Koala Rescue Club" }),
      attrs: koalaAttrs,
      status: "in_progress",
      canLaunchGame: true,
      module: null,
      connection: null,
      session: null,
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

  it("keeps game details visible without session controls when launch is unavailable", () => {
    render(GamePage, {
      slug: "voyages",
      status: null,
      canLaunchGame: false,
      game: gameMetadata({ name: "Voyages", description: "Chart a course." }),
      module: null,
      connection: null,
      session: null,
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
