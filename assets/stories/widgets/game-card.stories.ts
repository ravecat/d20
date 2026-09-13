import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import GameCard from "~/pages/home/ui/game-card.svelte";
import { compactMetadataGames, fallbackBrowseGames, homeBrowseGames } from "~stories/fixtures/home";
import GameWidgetFrame from "~stories/decorators/game-widget-frame.svelte";
import { reset, set, usePage } from "~stories/mocks/inertia_svelte";

const meta = {
  title: "Widgets/Game Card",
  component: GameCard,
  beforeEach: ({ args }) => {
    reset();
    const page = usePage();
    set({
      ...page,
      props: {
        ...page.props,
        auth: { ...page.props.auth, authenticated: args.saved ?? false },
      },
    });
    return reset;
  },
  decorators: [
    (_story, { args }) => ({
      Component: GameWidgetFrame,
      props: { compact: !args.hero },
    }),
  ],
  parameters: { layout: "fullscreen" },
  args: { entry: homeBrowseGames[0], hero: false },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    const title = args.entry.game.name;
    const link = canvas.getByRole("link", { name: title || "Open game" });
    await expect(link).toHaveAttribute("href", `/games/${args.entry.slug}`);
    const favoriteName = title
      ? `${args.saved ? "Remove" : "Add"} ${title} ${args.saved ? "from" : "to"} favorites`
      : args.saved
        ? "Remove from favorites"
        : "Add to favorites";
    await expect(canvas.getByRole("button", { name: favoriteName })).toHaveAttribute(
      "aria-pressed",
      String(args.saved ?? false),
    );
    if (title) {
      await expect(canvas.getByRole("heading", { name: title, level: 3 })).toBeVisible();
    } else {
      await expect(canvas.queryByRole("heading")).not.toBeInTheDocument();
    }
    const categories = canvas.queryByRole("list", { name: "Categories" });
    if (args.entry.game.categories.length) {
      await expect(
        within(categories!)
          .getAllByRole("listitem")
          .map((item) => item.textContent),
      ).toEqual(args.entry.game.categories);
    } else {
      await expect(categories).not.toBeInTheDocument();
    }
    if (args.entry.stage === "in_development") {
      await expect(canvas.getByText("In development")).toBeVisible();
    } else {
      await expect(canvas.queryByText("In development")).not.toBeInTheDocument();
    }
  },
} satisfies Meta<typeof GameCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Compact: Story = {};
export const Hero: Story = { args: { hero: true } };
export const FavoriteHovered: Story = {
  play: async (context) => {
    await meta.play(context);
    const canvas = within(context.canvasElement);
    const button = canvas.getByRole("button", {
      name: `Add ${context.args.entry.game.name} to favorites`,
    });
    await userEvent.hover(button);
    await expect(button).toHaveAttribute("aria-pressed", "false");
  },
};
export const FavoriteSaved: Story = {
  args: { saved: true },
};
export const HeroFavoriteSaved: Story = {
  args: { hero: true, saved: true },
};
export const FavoriteFocused: Story = {
  play: async (context) => {
    await meta.play(context);
    const canvas = within(context.canvasElement);
    canvas.getByRole("link", { name: context.args.entry.game.name! }).focus();
    await userEvent.tab();
    const button = canvas.getByRole("button", {
      name: `Add ${context.args.entry.game.name} to favorites`,
    });
    await expect(button).toHaveFocus();
    await expect(button).toHaveAttribute("aria-pressed", "false");
  },
};
export const CompactLongTitle: Story = {
  args: { entry: compactMetadataGames[2] },
};
export const HeroLongTitle: Story = {
  args: { entry: compactMetadataGames[2], hero: true },
};
export const FallbackMetadata: Story = {
  args: { entry: fallbackBrowseGames[0], hero: true },
};
export const Untitled: Story = {
  args: {
    entry: {
      ...homeBrowseGames[2],
      slug: "1011",
      stage: null,
      game: {
        ...homeBrowseGames[2].game,
        name: "",
        categories: [],
        imageUrl: null,
        thumbnailUrl: null,
      },
    },
  },
};
export const Image: Story = {
  args: {
    hero: true,
    entry: {
      ...homeBrowseGames[0],
      stage: "released",
      game: {
        ...homeBrowseGames[0].game,
        imageUrl: "/images/d20.svg",
        thumbnailUrl: "/images/logo.svg",
      },
    },
  },
};
export const Thumbnail: Story = {
  args: {
    entry: {
      ...homeBrowseGames[1],
      game: {
        ...homeBrowseGames[1].game,
        imageUrl: null,
        thumbnailUrl: "/images/logo.svg",
      },
    },
  },
};
