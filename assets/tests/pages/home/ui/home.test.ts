import { render, screen, within } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { HomePage } from "~/pages/home";
import type { GameCatalogEntry, GameMetadata, GameStage } from "~/shared/types/game";
import inertiaMock from "../../../mocks/inertia";

const qwintoId = "game_01h45yhtgqfhxbcrsfbhxdsdvy";
const voyagesId = "game_01h45ybmy7fj7b4r9vvp74ms6k";
const koalaId = "game_01h45y0sxkfmntta78gqs1vsw6";
const deepSeaId = "game_01h45ybrowsedeepsea00000";

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

describe("home page", () => {
  it("renders semantic sections in server order with one canonical link per game", () => {
    const { container } = render(HomePage, {
      auth,
      playableGames: [
        gameEntry(qwintoId, "qwinto", "Qwinto", "released", {
          categories: ["Dice", "Number"],
          imageUrl: "https://example.invalid/qwinto-image.jpg",
        }),
        gameEntry(koalaId, "koala-rescue-club", "Koala Rescue Club", "in_development"),
      ],
      games: [
        gameEntry(voyagesId, "voyages", "Voyages", "released"),
        gameEntry(
          "game_01h45y849qfqvbeayxmwkxg5x9",
          "next-station-london",
          "Next Station",
          "in_development",
        ),
        gameEntry(deepSeaId, "deep-sea-adventure", "Deep Sea Adventure", "released"),
      ],
    });

    const playableSection = screen.getByRole("region", { name: "Playable" });
    const browseSection = screen.getByRole("region", { name: "Games" });

    expect(screen.getByRole("heading", { name: "Games", level: 1 })).toBeTruthy();
    expect(
      [...screen.getAllByRole("heading", { level: 2 })].map((heading) => heading.textContent),
    ).toEqual(["Playable", "Games"]);

    expect(
      within(playableSection)
        .getAllByRole("link")
        .map((link) => link.getAttribute("href")),
    ).toEqual(["/games/qwinto", "/games/koala-rescue-club"]);
    expect(
      within(browseSection)
        .getAllByRole("link")
        .map((link) => link.getAttribute("href")),
    ).toEqual(["/games/voyages", "/games/next-station-london", "/games/deep-sea-adventure"]);

    // Exactly one accessible link per delivered game across every collection;
    // duplicated loop tracks and the decorative compact strip stay hidden.
    expect(screen.getAllByRole("link")).toHaveLength(5);
    expect(screen.getByRole("link", { name: "Qwinto" }).getAttribute("href")).toBe("/games/qwinto");
    expect(screen.getByRole("link", { name: "Voyages" }).getAttribute("href")).toBe(
      "/games/voyages",
    );

    // The animated loops duplicate each sequence once with inert copies, and
    // the compact Games row is one inert decorative track. Svelte assigns the
    // reflected `inert` property, so match either the property or attribute.
    const inertSlides = Array.from(container.querySelectorAll("li")).filter(
      (slide) => slide.inert === true || slide.hasAttribute("inert"),
    );
    expect(inertSlides).toHaveLength(5);
    expect(
      container.querySelectorAll(".carousel--compact[inert][aria-hidden='true']"),
    ).toHaveLength(1);

    expect(document.querySelector("img")?.getAttribute("src")).toBe(
      "https://example.invalid/qwinto-image.jpg",
    );
    expect(within(playableSection).queryByText("In development")).toBeNull();
    expect(within(browseSection).getAllByText("In development")).toHaveLength(4);
    expect(
      within(screen.getByRole("link", { name: "Voyages" })).queryByText("In development"),
    ).toBeNull();
  });

  it("renders one browse game without duplicates or controls", () => {
    const { container } = render(HomePage, {
      auth,
      playableGames: [gameEntry(qwintoId, "qwinto", "Qwinto", "released")],
      games: [gameEntry(voyagesId, "voyages", "Voyages", "in_development")],
    });

    const browseSection = screen.getByRole("region", { name: "Games" });

    expect(within(browseSection).getAllByRole("link")).toHaveLength(1);
    expect(container.querySelectorAll("li[inert]")).toHaveLength(0);
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.queryByRole("status")).toBeNull();
  });

  it("omits the games section when no browse game exists", () => {
    render(HomePage, {
      auth,
      playableGames: [gameEntry(qwintoId, "qwinto", "Qwinto", "released")],
      games: [],
    });

    expect(screen.getByRole("region", { name: "Playable" })).toBeTruthy();
    expect(screen.queryByRole("region", { name: "Games" })).toBeNull();
    expect(screen.queryByText("No additional games are available to browse.")).toBeNull();
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.queryByRole("status")).toBeNull();
  });

  it("omits the playable section when no playable game exists", () => {
    render(HomePage, {
      auth,
      playableGames: [],
      games: [gameEntry(voyagesId, "voyages", "Voyages", "in_development")],
    });

    expect(screen.queryByRole("region", { name: "Playable" })).toBeNull();
    expect(screen.queryByText("No playable games are currently available.")).toBeNull();
    expect(screen.getByRole("region", { name: "Games" })).toBeTruthy();
    expect(screen.getAllByRole("link")).toHaveLength(1);
  });

  it("omits both collection sections when both collections are empty", () => {
    const { container } = render(HomePage, { auth, playableGames: [], games: [] });

    expect(screen.getByRole("heading", { name: "Games", level: 1 })).toBeTruthy();
    expect(screen.queryByRole("heading", { level: 2 })).toBeNull();
    expect(screen.queryByRole("region")).toBeNull();
    expect(screen.queryByRole("button")).toBeNull();
    expect(screen.queryByRole("link")).toBeNull();
    expect(screen.queryByRole("status")).toBeNull();
    expect(container.querySelector(".carousel-group")).toBeNull();
  });

  it("keeps fallback cards linked with generic accessible names", () => {
    render(HomePage, {
      auth,
      playableGames: [],
      games: [
        gameEntry(voyagesId, "voyages", null, "in_development", {
          imageUrl: null,
          thumbnailUrl: null,
        }),
      ],
    });

    expect(screen.getByRole("link", { name: "Open game" }).getAttribute("href")).toBe(
      "/games/voyages",
    );
    expect(screen.queryByRole("img")).toBeNull();
  });

  it("introduces no scripted navigation and performs no request during presentation", () => {
    render(HomePage, {
      auth,
      playableGames: [gameEntry(qwintoId, "qwinto", "Qwinto", "released")],
      games: [
        ...Array.from({ length: 16 }, (_, index) =>
          gameEntry(
            `game_first_${index}`,
            `first-${index}`,
            `First ${index + 1}`,
            "in_development",
          ),
        ),
      ],
    });

    expect(screen.getAllByRole("link")).toHaveLength(17);
    expect(inertiaMock.router.visit).not.toHaveBeenCalled();
    expect(inertiaMock.router.get).not.toHaveBeenCalled();
  });
});

function gameEntry(
  id: string,
  slug: string,
  name: string | null,
  stage: GameStage,
  metadata: Partial<GameMetadata> = {},
): GameCatalogEntry {
  return {
    id,
    slug,
    stage,
    game: gameMetadata({ name, ...metadata }),
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
