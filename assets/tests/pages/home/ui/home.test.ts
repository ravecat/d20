import { render } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { HomePage } from "~/pages/home";
import type { GameMetadata } from "~/shared/types/game";

const qwintoId = "game_01h45yhtgqfhxbcrsfbhxdsdvy";
const voyagesId = "game_01h45ybmy7fj7b4r9vvp74ms6k";
const koalaId = "game_01h45y0sxkfmntta78gqs1vsw6";

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

describe("home page", () => {
  it("renders game tiles with preview images and id-only links", () => {
    render(HomePage, {
      auth,
      games: [
        {
          id: qwintoId,
          stage: "released",
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

    expect(link?.getAttribute("href")).toBe(`/games/${qwintoId}`);
    expect(title?.textContent).toBe("Qwinto");
    expect(image?.getAttribute("src")).toBe("https://example.invalid/qwinto-image.jpg");
    expect(visibleText).toContain("Qwinto");
    expect(visibleText).toContain("Dice");
    expect(visibleText).toContain("Number");
    expect(visibleText).not.toContain("Dice Rolling");
    expect(visibleText).not.toContain("Paper-and-Pencil");
    expect(visibleText).not.toContain("In development");
    expect(visibleText).not.toContain("Planned");
  });

  it("renders fallback preview state when metadata has no image", () => {
    render(HomePage, {
      auth,
      games: [
        {
          id: voyagesId,
          stage: "planned",
          game: gameMetadata({ thumbnailUrl: null, imageUrl: null }),
        },
      ],
    });

    const [link] = document.links;

    expect(link?.textContent).toContain("Qwinto");
    expect(document.images).toHaveLength(0);
    expect(link?.getAttribute("href")).toBe(`/games/${voyagesId}`);
    expect(link?.textContent).toContain("Planned");
  });

  it("renders the In development label for games under development", () => {
    render(HomePage, {
      auth,
      games: [
        {
          id: koalaId,
          stage: "in_development",
          game: gameMetadata({ name: "Koala Rescue Club" }),
        },
      ],
    });

    const [link] = document.links;

    expect(link?.getAttribute("href")).toBe(`/games/${koalaId}`);
    expect(link?.querySelector("h2")?.textContent).toBe("Koala Rescue Club");
    expect(link?.textContent).toContain("Koala Rescue Club");
    expect(link?.textContent).toContain("In development");
  });

  it("renders games in the received catalog order", () => {
    render(HomePage, {
      auth,
      games: [
        {
          id: "game_01h4rn40ybeqws3gfp073jt81b",
          stage: "planned",
          game: gameMetadata({ name: "Planned First" }),
        },
        {
          id: "game_01h45y849qfqvbeayxmwkxg5x9",
          stage: "released",
          game: gameMetadata({ name: "Released First" }),
        },
        {
          id: "game_01h45ypmyxekaa2apdhevf7bve",
          stage: "in_development",
          game: gameMetadata({ name: "Development First" }),
        },
        {
          id: "game_01h45ydzqkemsb9x8gq2q7vpvb",
          stage: "released",
          game: gameMetadata({ name: "Released Second" }),
        },
        {
          id: "game_01h45y3ps9e18adjv9zvx743s2",
          stage: "planned",
          game: gameMetadata({ name: "Planned Second" }),
        },
        {
          id: "game_01h45y6thxeyg95gnpgqqefgpa",
          stage: "in_development",
          game: gameMetadata({ name: "Development Second" }),
        },
      ],
    });

    expect([...document.querySelectorAll("h2")].map((title) => title.textContent)).toEqual([
      "Planned First",
      "Released First",
      "Development First",
      "Released Second",
      "Planned Second",
      "Development Second",
    ]);
  });
});

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
