import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import type { GameCatalogEntry } from "~/shared/types/game";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import { fourBrowseGames, threePlayableGames } from "~stories/fixtures/home";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  id: "home",
  title: "Pages/Public/∕",
  component: HomePage,
  decorators: [withLayout({ url: "/" })],
  parameters: {
    layout: "fullscreen",
  },
  beforeEach: async () => {
    auth.trigger.reset();
    if (import.meta.env.VITEST === "true") {
      const { userEvent: browserUserEvent } = await import("vitest/browser");
      await browserUserEvent.unhover(document.body, { position: { x: 0, y: 0 } });
    }
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
    games: fourBrowseGames,
  },
} satisfies Meta<typeof HomePage>;

export default meta;
type Story = StoryObj<InertiaProps<Pick<typeof meta.args, "playableGames" | "games">>>;

async function expectCollections(
  canvasElement: HTMLElement,
  { playableGames, games }: { playableGames: GameCatalogEntry[]; games: GameCatalogEntry[] },
) {
  const main = within(within(canvasElement).getByRole("main"));
  await expect(main.getByRole("heading", { name: "Games", level: 1 })).toBeInTheDocument();
  await expect(
    main.queryAllByRole("heading", { level: 2 }).map((heading) => heading.textContent?.trim()),
  ).toEqual([
    ...(playableGames.length ? ["Playable"] : []),
    ...(games.length ? ["Hot (by BGG)"] : []),
  ]);
  await expect(main.queryAllByRole("button", { name: /favorites/ })).toHaveLength(
    playableGames.length + games.length,
  );
  await expect(main.queryByRole("status")).not.toBeInTheDocument();

  for (const [name, entries] of [
    ["Playable", playableGames],
    ["Hot (by BGG)", games],
  ] as const) {
    const section = main.queryByRole("region", { name });
    if (!entries.length) {
      await expect(section).not.toBeInTheDocument();
      continue;
    }
    const collection = within(section!);
    const attribution = collection.queryByRole("link", { name: "by BGG" });
    if (name === "Hot (by BGG)") {
      await expect(attribution).toBeVisible();
      await expect(attribution).toHaveAttribute("href", "https://boardgamegeek.com/hotness");
    } else {
      await expect(attribution).not.toBeInTheDocument();
    }
    const links = collection
      .getAllByRole("list")
      .flatMap((list) => within(list).queryAllByRole("link"));
    await expect(links.map((link) => link.getAttribute("href"))).toEqual(
      entries.map((entry) => `/games/${entry.slug}`),
    );
    for (const [index, entry] of entries.entries()) {
      await expect(links[index]).toHaveAccessibleName(entry.game.name || "Open game");
    }
  }
}

export const Index: Story = {
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args);
    const canvas = within(canvasElement);

    await expect(canvas.getByRole("banner")).toBeVisible();
    await expect(
      within(canvas.getByRole("banner")).getByRole("link", { name: "D20" }),
    ).toBeVisible();
    await expect(canvas.getByRole("main")).toBeVisible();
    await expect(canvas.getByRole("region", { name: "Playable" })).toBeVisible();
    await expect(canvas.getByRole("region", { name: "Hot (by BGG)" })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Voyages" })).toBeVisible();
    await expect(canvas.getAllByRole("contentinfo")).toHaveLength(1);
    await expect(canvas.getByRole("navigation", { name: "Explore" })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Terms" })).toBeVisible();
  },
};

export const Empty: Story = {
  args: { playableGames: [], games: [] },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args);
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("region", { name: "Playable" })).not.toBeInTheDocument();
    await expect(canvas.queryByRole("region", { name: "Hot (by BGG)" })).not.toBeInTheDocument();
    await expect(canvas.getByRole("contentinfo")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Terms" })).toBeVisible();
  },
};

export const NoPlayableGames: Story = {
  args: {
    playableGames: [],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args);
  },
};

export const NoBrowseGames: Story = {
  args: {
    games: [],
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args);
  },
};

export const OverlappingSingletons: Story = {
  args: {
    playableGames: threePlayableGames.slice(1, 2),
    games: threePlayableGames.slice(1, 2),
  },
  play: async ({ canvasElement, args }) => {
    await expectCollections(canvasElement, args);
    const main = within(within(canvasElement).getByRole("main"));
    await expect(main.getAllByRole("link", { name: "Qwinto" })).toHaveLength(2);
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
