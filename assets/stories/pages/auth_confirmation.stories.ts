import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AuthConfirmationPage } from "~/pages/auth_confirmation";

const meta = {
  title: "Pages/Auth Confirmation",
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

export const SignIn: Story = {};

export const Reauthentication: Story = {
  args: {
    reauthenticate: true,
  },
};
