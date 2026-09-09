import type { GameCatalogEntry, GameMetadata, GameStage } from "~/shared/types/game";

export const threePlayableGames: GameCatalogEntry[] = [
  game(1001, "koala-rescue-club", "Koala Rescue Club", "released", ["Animals", "Puzzle"]),
  game(1002, "qwinto", "Qwinto", "released", ["Dice", "Number"]),
  game(1003, "next-station-london", "Next Station: London", "in_development", [
    "Trains",
    "Transportation",
  ]),
];

export const eightPlayableGames: GameCatalogEntry[] = [
  ...threePlayableGames,
  game(1004, "aquamarine", "Aquamarine", "released", ["Exploration"]),
  game(1005, "fliptown", "Fliptown", "released", ["American West"]),
  game(1006, "flip-7", "Flip 7", "released", ["Card Game"]),
  game(1007, "lost-cities", "Lost Cities", "released", ["Card Game"]),
  game(1008, "sky-team", "Sky Team", "released", ["Aviation"]),
];

export const homeBrowseGames: GameCatalogEntry[] = [
  game(1009, "voyages", "Voyages", "in_development", ["Exploration", "Nautical"]),
  game(1010, "death-valley", "Death Valley", "in_development", ["Card Game"]),
  game(1011, "deep-sea-adventure", "Deep Sea Adventure", "in_development", ["Adventure"]),
  game(1012, "confusing-lands", "Confusing Lands", "in_development", ["Fantasy"]),
  game(1007, "lost-cities", "Lost Cities", "in_development", ["Card Game"]),
  game(1013, "nimalia", "Nimalia", "in_development", ["Animals"]),
  game(1014, "qwixx", "Qwixx", "in_development", ["Dice"]),
  game(1015, "railroad-ink", "Railroad Ink", "in_development", ["Transportation"]),
  game(1016, "shifting-stones", "Shifting Stones", "in_development", ["Abstract Strategy"]),
  game(1008, "sky-team", "Sky Team", "in_development", ["Aviation"]),
  game(1017, "trailblazers", "Trailblazers", "in_development", ["Travel"]),
  game(1018, "trails-of-tucana", "Trails of Tucana", "in_development", ["Travel"]),
  game(1019, "waypoints", "Waypoints", "in_development", ["Exploration"]),
  game(1004, "aquamarine", "Aquamarine", "in_development", ["Exploration"]),
  game(1005, "fliptown", "Fliptown", "in_development", ["American West"]),
  game(1020, "prototype-station", "Prototype Station", "in_development", ["Trains"]),
  game(1021, "calico", "Calico", "in_development", ["Animals"]),
  game(1022, "cascadia", "Cascadia", "in_development", ["Animals"]),
  game(1023, "cartographers", "Cartographers", "in_development", ["Fantasy"]),
  game(1024, "welcome-to", "Welcome To", "in_development", ["City Building"]),
  game(1025, "railroad-ink-challenge", "Railroad Ink Challenge", "in_development", [
    "Transportation",
  ]),
  game(1026, "my-city-roll-build", "My City: Roll & Build", "in_development", ["City Building"]),
  game(1027, "ganz-schon-clever", "Ganz Schön Clever", "in_development", ["Dice"]),
  game(1029, "azul", "Azul", null, ["Abstract Strategy"]),
  game(1030, "wingspan", "Wingspan", null, ["Animals"]),
  game(1031, "everdell", "Everdell", null, ["Fantasy"]),
  game(1032, "parks", "PARKS", null, ["Travel"]),
  game(1033, "dorfromantik", "Dorfromantik", null, ["City Building"]),
  game(1034, "harmonies", "Harmonies", null, ["Animals"]),
  game(1035, "sea-salt-paper", "Sea Salt & Paper", null, ["Card Game"]),
  game(1036, "scout", "SCOUT", null, ["Card Game"]),
  game(1037, "1037", "The Last Lighthouse", null, ["Exploration"]),
];

export const fourBrowseGames = homeBrowseGames.slice(0, 4);

export const providerOnlyGames = [game(350736, "350736", "Voyages", null)];

export const fallbackBrowseGames = [game(1028, "fallback-game", null, "in_development")];

export const compactMetadataGames = [
  homeBrowseGames[0],
  game(1039, "1039", null, null),
  game(
    1038,
    "long-journey",
    "The Extraordinary Journey Across the Uncharted Northern Archipelago",
    "in_development",
    ["Exploration", "Nautical", "Adventure"],
  ),
];

function game(
  id: number,
  slug: string,
  name: string | null,
  stage: GameStage | null,
  categories: string[] = [],
): GameCatalogEntry {
  const metadata: GameMetadata = {
    name,
    alternateNames: [],
    categories,
    mechanics: [],
    thumbnailUrl: null,
    imageUrl: null,
  };

  return { id, slug, stage, game: metadata };
}
