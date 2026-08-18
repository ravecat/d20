import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { RegistrationCompletionPage } from "~/pages/registration_completion";

const meta = {
  title: "Pages/Sign Up/Registration Completion",
  component: RegistrationCompletionPage,
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
        google: { available: true },
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
