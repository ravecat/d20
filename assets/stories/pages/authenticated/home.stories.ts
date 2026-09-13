import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import { fourBrowseGames, homeBrowseGames, threePlayableGames } from "~stories/fixtures/home";
import { formRequests, setFormHandler } from "~stories/mocks/inertia_svelte";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  id: "pages-authenticated-home",
  title: "Pages/Authenticated/∕",
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
      authenticated: true,
      local: false,
      prompt: {
        email: "player@example.com",
        identifier: "table_master",
        kind: "warning" as const,
        message: "You must re-authenticate to access this page.",
        reauthenticate: true,
        returnTo: "/profile",
      },
      providers: {
        apple: { available: true },
        discord: { available: true },
        facebook: { available: true },
        google: { available: true },
        steam: { available: true },
      },
    },
    favorites: [],
    playableGames: threePlayableGames,
    games: fourBrowseGames,
  },
} satisfies Meta<typeof HomePage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Index: Story = {
  args: { auth: { ...meta.args.auth, prompt: null } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "Settings" })).toBeVisible();
    await expect(canvas.getAllByRole("contentinfo")).toHaveLength(1);
    await expect(canvas.getByRole("navigation", { name: "Explore" })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Terms" })).toBeVisible();
  },
};

export const ConfirmationWithMagicLink: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await expect(await canvas.findByRole("dialog", { name: "Confirm it is you" })).toBeVisible();
    await expect(canvas.getByText("You must re-authenticate to access this page.")).toBeVisible();
    await expect(canvas.getByRole("textbox", { name: "Email address" })).toHaveValue(
      "player@example.com",
    );
  },
};

export const FavoritesSavedOverlap: Story = {
  args: {
    auth: { ...meta.args.auth, prompt: null },
    favorites: [threePlayableGames[0].id],
    playableGames: [threePlayableGames[0]],
    games: [threePlayableGames[0], ...homeBrowseGames.slice(0, 3)],
  },
  play: async ({ canvasElement }) => {
    const buttons = within(canvasElement).getAllByRole("button", {
      name: "Remove Koala Rescue Club from favorites",
    });
    await expect(buttons).toHaveLength(2);
    for (const button of buttons) await expect(button).toHaveAttribute("aria-pressed", "true");
    await userEvent.hover(buttons[0]);
  },
};

export const FavoritesPendingOverlap: Story = {
  args: {
    auth: { ...meta.args.auth, prompt: null },
    playableGames: [threePlayableGames[0]],
    games: [threePlayableGames[0]],
  },
  beforeEach: () => {
    setFormHandler(() => new Promise(() => undefined));
    return () => setFormHandler();
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const buttons = canvas.getAllByRole("button", {
      name: "Add Koala Rescue Club to favorites",
    });
    await userEvent.click(buttons[0]);
    await expect(buttons[0]).toHaveAttribute("aria-disabled", "true");
    await expect(buttons[0]).toHaveAttribute("aria-busy", "true");
    await expect(buttons[1]).toHaveAttribute("aria-disabled", "false");
    await expect(buttons[1]).toHaveAttribute("aria-busy", "false");
    for (const button of buttons) await expect(button).toHaveAttribute("aria-pressed", "false");
    await expect(formRequests).toHaveLength(1);
  },
};

export const FavoritesRetry: Story = {
  args: {
    auth: { ...meta.args.auth, prompt: null },
    playableGames: [threePlayableGames[0]],
    games: [threePlayableGames[0]],
  },
  beforeEach: () => {
    setFormHandler(async () => ({
      errors: {
        favorite: "Favorites are temporarily unavailable. Please retry.",
      },
    }));
    return () => setFormHandler();
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(
      canvas.getAllByRole("button", {
        name: "Add Koala Rescue Club to favorites",
      })[0],
    );
    await expect(canvas.queryByRole("alert")).not.toBeInTheDocument();
    await expect(canvas.queryByRole("status")).not.toBeInTheDocument();
    await expect(
      canvas.getAllByRole("button", {
        name: "Add Koala Rescue Club to favorites",
      })[0],
    ).toHaveAttribute("aria-disabled", "false");
    await userEvent.click(
      canvas.getAllByRole("button", {
        name: "Add Koala Rescue Club to favorites",
      })[0],
    );
    await expect(formRequests).toHaveLength(2);
    await expect(formRequests[1]).toEqual(formRequests[0]);
    await expect(
      canvas.getAllByRole("button", {
        name: "Add Koala Rescue Club to favorites",
      }),
    ).toHaveLength(2);
  },
};
