import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { RegistrationCompletionPage } from "~/pages/registration_completion";
import { withLayout } from "~stories/decorators/layout";

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
    email: null,
    submission: {
      action: "/auth/google/register",
      credential: { type: "server_session" },
    },
  },
};
