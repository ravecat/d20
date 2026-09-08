import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import {
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
type Story = StoryObj<typeof meta>;

export const Index: Story = {
  play: async ({ canvasElement }) => {
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
    await expect(canvas.getByRole("link", { name: "Privacy" })).toBeVisible();
  },
};

export const Empty: Story = {
  args: { playableGames: [], games: [] },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("region", { name: "Playable" })).not.toBeInTheDocument();
    await expect(canvas.queryByRole("region", { name: "Games" })).not.toBeInTheDocument();
    await expect(canvas.getByRole("contentinfo")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "Privacy" })).toBeVisible();
  },
};

export const EightPlayable: Story = {
  args: {
    playableGames: eightPlayableGames,
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
};

export const OnePlayableGame: Story = {
  args: {
    playableGames: threePlayableGames.slice(0, 1),
    games: [],
  },
};

export const TwoPlayableGames: Story = {
  args: {
    playableGames: threePlayableGames.slice(0, 2),
  },
};

export const NoBrowseGames: Story = {
  args: {
    games: [],
  },
};

export const OneBrowseGame: Story = {
  args: {
    playableGames: [],
    games: homeBrowseGames.slice(0, 1),
  },
};

export const FallbackMetadata: Story = {
  args: {
    playableGames: [],
    games: fallbackBrowseGames,
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
