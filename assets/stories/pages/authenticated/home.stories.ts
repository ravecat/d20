import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, within } from "storybook/test";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import { homeGames } from "~stories/fixtures/home";
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
    games: homeGames,
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
    await expect(canvas.getByRole("link", { name: "Privacy" })).toBeVisible();
  },
};

export const ConfirmationWithMagicLink: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await expect(await canvas.findByRole("dialog", { name: "Confirm it is you" })).toBeVisible();
    await expect(canvas.getByRole("status")).toHaveTextContent(
      "You must re-authenticate to access this page.",
    );
    await expect(canvas.getByRole("textbox", { name: "Email address" })).toHaveValue(
      "player@example.com",
    );
  },
};
