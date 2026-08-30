import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import { HomePage } from "~/pages/home";
import { auth } from "~/shared/stores";
import { homeGames } from "../../fixtures/home";
import { withLayout } from "../../decorators/layout";

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
    games: homeGames,
  },
} satisfies Meta<typeof HomePage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Index: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await expect(canvas.getByRole("banner")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "D20" })).toBeVisible();
    await expect(canvas.getByRole("main")).toBeVisible();
    await expect(canvas.getByText("Qwinto")).toBeVisible();
    await expect(canvas.getByRole("contentinfo")).toBeVisible();
    await expect(canvas.getByRole("link", { name: "for developers" })).toBeVisible();
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
    await expect(await canvas.findByRole("status")).toHaveTextContent(
      "If your email is in our system, a login link will arrive shortly.",
    );
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
    await expect(await canvas.findByRole("status")).toHaveTextContent(
      "Open the confirmation link to finish creating your account and log in.",
    );
    await expect(canvas.getByRole("link", { name: "local mailbox" })).toBeVisible();
  },
};
