import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import type { GameCatalogEntry } from "~/shared/types/game";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import {
  compactMetadataGames,
  eightPlayableGames,
  fallbackBrowseGames,
  homeBrowseGames,
  threePlayableGames,
} from "~stories/fixtures/home";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  id: "home",
  title: "Pages/Public/∕",
  component: HomePage,
  decorators: [withLayout({ url: "/" })],
  parameters: {
    layout: "fullscreen",
  },
  beforeEach: () => {
    auth.trigger.reset();
    return () => auth.trigger.reset();
  },
  args: {
    auth: {
      authenticated: false,
      local: false,
      prompt: null,
      providers: {
        apple: { available: true },
        discord: { available: true },
        facebook: { available: true },
        google: { available: true },
        steam: { available: true },
      },
    },
    playableGames: threePlayableGames,
    games: homeBrowseGames,
  },
} satisfies Meta<typeof HomePage>;

export default meta;
type Story = StoryObj<InertiaProps<Pick<typeof meta.args, "playableGames" | "games">>>;

async function expectCollections(
  canvasElement: HTMLElement,
  { playableGames, games }: { playableGames: GameCatalogEntry[]; games: GameCatalogEntry[] },
  heroCount: number,
) {
  const main = within(within(canvasElement).getByRole("main"));
  await expect(main.getByRole("heading", { name: "Games", level: 1 })).toBeInTheDocument();
  await expect(
    main.queryAllByRole("heading", { level: 2 }).map((heading) => heading.textContent),
  ).toEqual([...(playableGames.length ? ["Playable"] : []), ...(games.length ? ["Games"] : [])]);
  await expect(main.queryByRole("button")).not.toBeInTheDocument();
  await expect(main.queryByRole("status")).not.toBeInTheDocument();

  for (const [name, entries] of [
    ["Playable", playableGames],
    ["Games", games],
  ] as const) {
    const section = main.queryByRole("region", { name });
    if (!entries.length) {
      await expect(section).not.toBeInTheDocument();
      continue;
    }
    const links = within(section!).getAllByRole("link");
    await expect(links.map((link) => link.getAttribute("href"))).toEqual(
      entries.map((entry) => `/games/${entry.slug}`),
    );
    for (const [index, entry] of entries.entries()) {
      await expect(links[index]).toHaveAccessibleName(entry.game.name || "Open game");
    }
  }

  for (const [name, entries] of [
    ["Featured games", games.slice(0, heroCount)],
    ["More games", games.slice(heroCount)],
  ] as const) {
    const lane = main.queryByRole("list", { name });
    if (!entries.length) {
      await expect(lane).not.toBeInTheDocument();
      continue;
    }
    await expect(
      within(lane!)
        .getAllByRole("link")
        .map((link) => link.getAttribute("href")),
    ).toEqual(entries.map((entry) => `/games/${entry.slug}`));
  }
}

export const Index: Story = {
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
    const canvas = within(canvasElement);

    await expect(canvas.getByRole("banner")).toBeVisible();
    await expect(
      within(canvas.getByRole("banner")).getByRole("link", { name: "D20" }),
    ).toBeVisible();
    await expect(canvas.getByRole("main")).toBeVisible();
    await expect(canvas.getByRole("region", { name: "Playable" })).toBeVisible();
    await expect(canvas.getByRole("region", { name: "Games" })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Voyages" })).toBeVisible();
    await expect(canvas.getAllByRole("contentinfo")).toHaveLength(1);
    await expect(canvas.getByRole("navigation", { name: "Explore" })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Terms" })).toBeVisible();
  },
};

export const Empty: Story = {
  args: { playableGames: [], games: [] },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 0);
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("region", { name: "Playable" })).not.toBeInTheDocument();
    await expect(canvas.queryByRole("region", { name: "Games" })).not.toBeInTheDocument();
    await expect(canvas.getByRole("contentinfo")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Terms" })).toBeVisible();
  },
};

export const EightPlayable: Story = {
  args: {
    playableGames: eightPlayableGames,
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
  },
};

export const Dark: Story = {
  ...Index,
  globals: { theme: "dark" },
};

export const NoPlayableGames: Story = {
  args: {
    playableGames: [],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
  },
};

export const OnePlayableGame: Story = {
  args: {
    playableGames: threePlayableGames.slice(0, 1),
    games: [],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 0);
  },
};

export const TwoPlayableGames: Story = {
  args: {
    playableGames: threePlayableGames.slice(0, 2),
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
  },
};

export const NoBrowseGames: Story = {
  args: {
    games: [],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 0);
  },
};

export const OneBrowseGame: Story = {
  args: {
    playableGames: [],
    games: homeBrowseGames.slice(0, 1),
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const TwoBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 2) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const ThreeBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 3) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const FiveBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 5) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 2);
  },
};

export const ThirtyTwoBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
  },
};

export const CompactMetadata: Story = {
  args: { playableGames: [], games: compactMetadataGames },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const FallbackMetadata: Story = {
  args: {
    playableGames: [],
    games: fallbackBrowseGames,
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const FourBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 4) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
  },
};

export const EightBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 8) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 2);
  },
};

export const ThirtyOneBrowseGames: Story = {
  args: { playableGames: [], games: homeBrowseGames.slice(0, 31) },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 8);
  },
};

export const OverlappingSingletons: Story = {
  args: {
    playableGames: threePlayableGames.slice(1, 2),
    games: threePlayableGames.slice(1, 2),
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
    const main = within(within(canvasElement).getByRole("main"));
    await expect(main.getAllByRole("link", { name: "Qwinto" })).toHaveLength(2);
  },
};

export const ImageMetadata: Story = {
  args: {
    playableGames: [],
    games: [
      {
        ...homeBrowseGames[0],
        stage: "released",
        game: {
          ...homeBrowseGames[0].game,
          imageUrl: "/images/d20.svg",
          thumbnailUrl: "/images/logo.svg",
        },
      },
      {
        ...homeBrowseGames[1],
        game: {
          ...homeBrowseGames[1].game,
          imageUrl: null,
          thumbnailUrl: "/images/logo.svg",
        },
      },
      {
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
    ],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args, 1);
    const games = within(within(canvasElement).getByRole("region", { name: "Games" }));
    const released = within(games.getByRole("link", { name: "Voyages" }));
    await expect(released.queryByText("In development")).not.toBeInTheDocument();
    const developing = within(games.getByRole("link", { name: "Death Valley" }));
    await expect(developing.getByText("In development")).toBeInTheDocument();
    const fallback = within(games.getByRole("link", { name: "Open game" }));
    await expect(fallback.queryByText("In development")).not.toBeInTheDocument();
    await expect(fallback.queryByRole("list", { name: "Categories" })).not.toBeInTheDocument();
    await expect(fallback.queryByRole("heading")).not.toBeInTheDocument();
  },
};

export const SignIn: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await userEvent.click(canvas.getByRole("button", { name: "Log in" }));
    await expect(canvas.getByRole("dialog", { name: "Log in" })).toBeVisible();
  },
};

export const SignInSentMagicLink: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await userEvent.click(canvas.getByRole("button", { name: "Log in" }));
    await expect(canvas.getByRole("dialog", { name: "Log in" })).toBeVisible();
    auth.trigger.magicLinkSucceeded();
    await expect(
      await canvas.findByText("If your email is in our system, a login link will arrive shortly.", {
        exact: false,
      }),
    ).toBeVisible();
  },
};

export const SignUp: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await userEvent.click(canvas.getByRole("button", { name: "Log in" }));
    await expect(canvas.getByRole("dialog", { name: "Log in" })).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Create account" }));
    await expect(canvas.getByRole("dialog", { name: "Create your free account" })).toBeVisible();
  },
};

export const SignUpWithEmail: Story = {
  args: {
    auth: {
      authenticated: false,
      local: true,
      prompt: null,
      providers: {
        apple: { available: true },
        discord: { available: true },
        facebook: { available: true },
        google: { available: true },
        steam: { available: true },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await userEvent.click(canvas.getByRole("button", { name: "Log in" }));
    await expect(canvas.getByRole("dialog", { name: "Log in" })).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: "Create account" }));
    await expect(canvas.getByRole("dialog", { name: "Create your free account" })).toBeVisible();
    auth.trigger.registrationSucceeded();
    await expect(
      await canvas.findByText(
        "Open the confirmation link to finish creating your account and log in.",
        { exact: false },
      ),
    ).toBeVisible();
    await expect(canvas.getByRole("link", { name: "local mailbox" })).toBeVisible();
  },
};
