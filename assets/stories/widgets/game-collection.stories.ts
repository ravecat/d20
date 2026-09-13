import { createRawSnippet } from "svelte";
import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, within } from "storybook/test";
import type { GameCatalogEntry } from "~/shared/types/game";
import GameCollection from "~/pages/home/ui/game-collection.svelte";
import { eightPlayableGames, fourBrowseGames } from "~stories/fixtures/home";
import GameWidgetFrame from "~stories/decorators/game-widget-frame.svelte";
import { reset } from "~stories/mocks/inertia_svelte";

const hotHeader = createRawSnippet(() => ({
  render: () => '<span>Hot (<a href="https://boardgamegeek.com/hotness">by BGG</a>)</span>',
}));
const playableHeader = createRawSnippet(() => ({
  render: () => "<span>Playable</span>",
}));

const meta = {
  title: "Widgets/Game Collection",
  component: GameCollection,
  beforeEach: () => {
    reset();
    return reset;
  },
  decorators: [() => ({ Component: GameWidgetFrame })],
  parameters: { layout: "fullscreen" },
  args: {
    games: fourBrowseGames,
    header: hotHeader,
    variant: "browse",
  },
  play: async ({ canvasElement, args, parameters }) => {
    const canvas = within(canvasElement);
    const headingName = args.variant === "compact" ? "Playable" : "Hot (by BGG)";
    const collection = within(canvas.getByRole("region", { name: headingName }));
    const heading = collection.getByRole("heading", {
      name: headingName,
      level: 2,
    });
    await expect(heading).toBeVisible();
    const attributionLink = within(heading).queryByRole("link");
    if (args.variant !== "compact") {
      await expect(attributionLink).toHaveAccessibleName("by BGG");
      await expect(attributionLink).toHaveAttribute("href", "https://boardgamegeek.com/hotness");
    } else {
      await expect(attributionLink).not.toBeInTheDocument();
    }
    const links = collection.getAllByRole("link").filter((link) => link !== attributionLink);
    await expect(links.map((link) => link.getAttribute("href"))).toEqual(
      args.games.map((entry: GameCatalogEntry) => `/games/${entry.slug}`),
    );
    for (const [index, entry] of args.games.entries()) {
      await expect(links[index]).toHaveAccessibleName(entry.game.name || "Open game");
    }
    if (args.variant === "compact") {
      await expect(
        collection.queryByRole("list", { name: "Featured games" }),
      ).not.toBeInTheDocument();
      await expect(collection.queryByRole("list", { name: "More games" })).not.toBeInTheDocument();
      for (const [index, entries] of [
        args.games.slice(0, parameters.expectedFirstRowCount),
        args.games.slice(parameters.expectedFirstRowCount),
      ].entries()) {
        const row = collection.queryByRole("list", {
          name: `Row ${index + 1}`,
        });
        if (parameters.expectedFirstRowCount === undefined) {
          await expect(row).not.toBeInTheDocument();
        } else {
          await expect(
            within(row!)
              .getAllByRole("link")
              .map((link) => link.getAttribute("href")),
          ).toEqual(entries.map((entry: GameCatalogEntry) => `/games/${entry.slug}`));
        }
      }
      return;
    }
    const heroCount: number = parameters.expectedHeroCount;
    for (const [name, entries] of [
      ["Featured games", args.games.slice(0, heroCount)],
      ["More games", args.games.slice(heroCount)],
    ] as const) {
      const lane = collection.queryByRole("list", { name });
      if (!entries.length) {
        await expect(lane).not.toBeInTheDocument();
        continue;
      }
      await expect(
        within(lane!)
          .getAllByRole("link")
          .map((link) => link.getAttribute("href")),
      ).toEqual(entries.map((entry: GameCatalogEntry) => `/games/${entry.slug}`));
    }
  },
} satisfies Meta<typeof GameCollection>;

export default meta;
type Story = StoryObj<typeof meta>;

export const OneBrowseGame: Story = {
  args: { games: fourBrowseGames.slice(0, 1) },
  parameters: { expectedHeroCount: 1 },
};

export const TwoBrowseGames: Story = {
  args: { games: fourBrowseGames.slice(0, 2) },
  parameters: { expectedHeroCount: 1 },
};

export const ThreeBrowseGames: Story = {
  args: { games: fourBrowseGames.slice(0, 3) },
  parameters: { expectedHeroCount: 1 },
};

export const FourBrowseGames: Story = {
  args: { games: fourBrowseGames.slice(0, 4) },
  parameters: { expectedHeroCount: 1 },
};

export const OnePlayableGame: Story = {
  args: {
    games: eightPlayableGames.slice(0, 1),
    variant: "compact",
    header: playableHeader,
  },
};

export const TwoPlayableGames: Story = {
  args: {
    games: eightPlayableGames.slice(0, 2),
    variant: "compact",
    header: playableHeader,
  },
};

export const FourPlayableGames: Story = {
  args: {
    games: eightPlayableGames.slice(0, 4),
    variant: "compact",
    header: playableHeader,
  },
};

export const SevenPlayableGames: Story = {
  args: {
    games: eightPlayableGames.slice(0, 7),
    variant: "compact",
    header: playableHeader,
  },
  parameters: { expectedFirstRowCount: 4 },
};
