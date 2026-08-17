import { render } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { HomePage } from "~/pages/home";
import type { GameMetadata } from "~/shared/types";

const auth = {
  authenticated: false,
  local: false,
  prompt: null,
  providers: {
    discord: { available: true },
    google: { available: true },
  },
};

describe("home page", () => {
  it("renders game tiles with preview images and slug links", () => {
    render(HomePage, {
      auth,
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
      auth,
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
      auth,
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
      auth,
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
