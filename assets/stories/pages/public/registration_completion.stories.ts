import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { RegistrationCompletionPage } from "~/pages/registration_completion";
import { withLayout } from "../../decorators/layout";

const meta = {
  title: "Pages/Public/∕users∕register∕complete",
  id: "pages-sign-up-registration-completion",
  component: RegistrationCompletionPage,
  decorators: [withLayout({ url: "/users/register/complete" })],
  parameters: {
    layout: "fullscreen",
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
    email: "player@example.com",
    submission: {
      action: "/users/log-in",
      credential: { type: "magic_link", token: "storybook-confirmation-token" },
    },
  },
} satisfies Meta<typeof RegistrationCompletionPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const MagicLink: Story = {};

export const AuthProvider: Story = {
  args: {
    cancelAction: "/auth/google/register/cancel",
    submission: {
      action: "/auth/google/register",
      credential: { type: "server_session" },
    },
  },
};

export const FacebookWithEmail: Story = {
  args: {
    cancelAction: "/auth/facebook/register/cancel",
    email: "facebook-candidate@example.com",
    submission: {
      action: "/auth/facebook/register",
      credential: { type: "server_session" },
    },
  },
};

export const FacebookProviderOnly: Story = {
  args: {
    cancelAction: "/auth/facebook/register/cancel",
    email: null,
    submission: {
      action: "/auth/facebook/register",
      credential: { type: "server_session" },
    },
  },
};

export const SteamProviderOnly: Story = {
  args: {
    cancelAction: "/auth/steam/register/cancel",
    email: null,
    submission: {
      action: "/auth/steam/register",
      credential: { type: "server_session" },
    },
  },
};
