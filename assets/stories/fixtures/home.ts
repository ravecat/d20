import type { GameCatalogEntry } from "~/shared/types/game";

export const homeGames: GameCatalogEntry[] = [
  {
    id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
    slug: "qwinto",
    stage: "released",
    game: {
      name: "Qwinto",
      alternateNames: [],
      categories: ["Dice", "Number"],
      mechanics: ["Dice Rolling", "Paper-and-Pencil"],
    },
  },
  {
    id: "game_01h45y0sxkfmntta78gqs1vsw6",
    slug: "koala-rescue-club",
    stage: "in_development",
    game: {
      name: "Koala Rescue Club",
      alternateNames: [],
      categories: ["Animals", "Puzzle"],
      mechanics: ["Dice Rolling", "Pattern Building"],
    },
  },
  {
    id: "game_01h45ybmy7fj7b4r9vvp74ms6k",
    slug: "voyages",
    stage: "planned",
    game: {
      name: "Voyages",
      alternateNames: [],
      categories: ["Exploration", "Nautical"],
      mechanics: ["Dice Rolling", "Grid Coverage"],
    },
  },
];
