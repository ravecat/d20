import type { GameCatalogEntry, GameMetadata, GameStage } from "~/shared/types/game";

export const threePlayableGames: GameCatalogEntry[] = [
  game("game_01h45y0sxkfmntta78gqs1vsw6", "koala-rescue-club", "Koala Rescue Club", "released", [
    "Animals",
    "Puzzle",
  ]),
  game("game_01h45yhtgqfhxbcrsfbhxdsdvy", "qwinto", "Qwinto", "released", ["Dice", "Number"]),
  game(
    "game_01h45ynextstationlondon000",
    "next-station-london",
    "Next Station: London",
    "in_development",
    ["Trains", "Transportation"],
  ),
];

export const eightPlayableGames: GameCatalogEntry[] = [
  ...threePlayableGames,
  game("game_01h45yplayableaquamarine0", "aquamarine", "Aquamarine", "released", ["Exploration"]),
  game("game_01h45yplayablefliptown000", "fliptown", "Fliptown", "released", ["American West"]),
  game("game_01h45yplayableflipseven00", "flip-7", "Flip 7", "released", ["Card Game"]),
  game("game_01h45yplayablelostcities0", "lost-cities", "Lost Cities", "released", ["Card Game"]),
  game("game_01h45yplayableskyteam000", "sky-team", "Sky Team", "released", ["Aviation"]),
];

export const homeBrowseGames: GameCatalogEntry[] = [
  game("game_01h45ybmy7fj7b4r9vvp74ms6k", "voyages", "Voyages", "in_development", [
    "Exploration",
    "Nautical",
  ]),
  game("game_01h45ybrowsedeathvalley00", "death-valley", "Death Valley", "in_development", [
    "Card Game",
  ]),
  game(
    "game_01h45ybrowsedeepsea00000",
    "deep-sea-adventure",
    "Deep Sea Adventure",
    "in_development",
    ["Adventure"],
  ),
  game("game_01h45ybrowseconfusing000", "confusing-lands", "Confusing Lands", "in_development", [
    "Fantasy",
  ]),
  game("game_01h45ybrowselostcities00", "lost-cities", "Lost Cities", "in_development", [
    "Card Game",
  ]),
  game("game_01h45ybrowsenimalia00000", "nimalia", "Nimalia", "in_development", ["Animals"]),
  game("game_01h45ybrowseqwiixx000000", "qwixx", "Qwixx", "in_development", ["Dice"]),
  game("game_01h45ybrowserailroad0000", "railroad-ink", "Railroad Ink", "in_development", [
    "Transportation",
  ]),
  game("game_01h45ybrowseshifting0000", "shifting-stones", "Shifting Stones", "in_development", [
    "Abstract Strategy",
  ]),
  game("game_01h45ybrowseskyteam00000", "sky-team", "Sky Team", "in_development", ["Aviation"]),
  game("game_01h45ybrowsetrailblazer0", "trailblazers", "Trailblazers", "in_development", [
    "Travel",
  ]),
  game("game_01h45ybrowsetrailstucana", "trails-of-tucana", "Trails of Tucana", "in_development", [
    "Travel",
  ]),
  game("game_01h45ybrowsewaypoints000", "waypoints", "Waypoints", "in_development", [
    "Exploration",
  ]),
  game("game_01h45ybrowseaquamarine0", "aquamarine", "Aquamarine", "in_development", [
    "Exploration",
  ]),
  game("game_01h45ybrowsefliptown000", "fliptown", "Fliptown", "in_development", ["American West"]),
  game("game_01h45ybrowseinprogress0", "prototype-station", "Prototype Station", "in_development", [
    "Trains",
  ]),
  game("game_01h45ybrowsecalico000000", "calico", "Calico", "in_development", ["Animals"]),
  game("game_01h45ybrowsecascadia0000", "cascadia", "Cascadia", "in_development", ["Animals"]),
  game("game_01h45ybrowsecartographer", "cartographers", "Cartographers", "in_development", [
    "Fantasy",
  ]),
  game("game_01h45ybrowsewelcometo000", "welcome-to", "Welcome To", "in_development", [
    "City Building",
  ]),
  game(
    "game_01h45ybrowserailroadchall",
    "railroad-ink-challenge",
    "Railroad Ink Challenge",
    "in_development",
    ["Transportation"],
  ),
  game(
    "game_01h45ybrowsemycityroll00",
    "my-city-roll-build",
    "My City: Roll & Build",
    "in_development",
    ["City Building"],
  ),
  game(
    "game_01h45ybrowseclever000000",
    "ganz-schon-clever",
    "Ganz Schön Clever",
    "in_development",
    ["Dice"],
  ),
];

export const fourBrowseGames = homeBrowseGames.slice(0, 4);

export const fallbackBrowseGames = [
  game("game_01h45ybrowsefallback000", "fallback-game", null, "in_development"),
];

function game(
  id: string,
  slug: string,
  name: string | null,
  stage: GameStage,
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
