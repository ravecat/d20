import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AuthConfirmationPage } from "~/pages/auth_confirmation";

const meta = {
  title: "Pages/Sign In/Magic Link Confirmation",
  component: AuthConfirmationPage,
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
        facebook: { available: false },
        google: { available: true },
      },
    },
    email: "player@example.com",
    reauthenticate: false,
    token: "storybook-login-token",
  },
} satisfies Meta<typeof AuthConfirmationPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Login: Story = {};

export const Reauthentication: Story = {
  args: {
    reauthenticate: true,
  },
};
