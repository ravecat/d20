import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AuthConfirmationPage } from "~/pages/auth_confirmation";
import { withLayout } from "../decorators/layout";

const meta = {
  title: "Pages/∕users∕log-in∕:token",
  id: "pages-sign-in-magic-link-confirmation",
  component: AuthConfirmationPage,
  decorators: [withLayout({ url: "/users/log-in/storybook-login-token" })],
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
        steam: { available: false },
      },
    },
    email: "player@example.com",
    reauthenticate: false,
    token: "storybook-login-token",
  },
} satisfies Meta<typeof AuthConfirmationPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Login: Story = {
  name: "Confirmation",
};

export const Reauthentication: Story = {
  args: {
    auth: {
      authenticated: true,
      local: false,
      prompt: null,
      providers: {
        apple: { available: true },
        discord: { available: true },
        facebook: { available: false },
        google: { available: true },
        steam: { available: false },
      },
    },
    reauthenticate: true,
  },
};
