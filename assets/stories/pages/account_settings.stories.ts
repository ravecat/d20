import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AccountSettingsPage } from "~/pages/account_settings";

const meta = {
  title: "Pages/Account Settings",
  component: AccountSettingsPage,
  parameters: {
    layout: "fullscreen",
  },
  args: {
    auth: {
      authenticated: true,
      local: false,
      prompt: null,
      providers: {
        apple: { available: true },
        discord: { available: false },
        google: { available: true },
      },
    },
    email: "player@example.com",
    providers: [
      {
        available: true,
        href: "/users/settings/auth/google",
        id: "google",
        linked: true,
        name: "Google",
      },
      {
        available: true,
        href: "/users/settings/auth/apple",
        id: "apple",
        linked: false,
        name: "Apple",
      },
      {
        available: false,
        href: "/users/settings/auth/discord",
        id: "discord",
        linked: false,
        name: "Discord",
      },
    ],
    username: "table_master",
  },
} satisfies Meta<typeof AccountSettingsPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const EstablishedAccount: Story = {};

export const NoAvailableProviders: Story = {
  args: {
    auth: {
      authenticated: true,
      local: false,
      prompt: null,
      providers: {
        apple: { available: false },
        discord: { available: false },
        google: { available: false },
      },
    },
    providers: [
      {
        available: false,
        href: "/users/settings/auth/google",
        id: "google",
        linked: false,
        name: "Google",
      },
      {
        available: false,
        href: "/users/settings/auth/apple",
        id: "apple",
        linked: false,
        name: "Apple",
      },
      {
        available: false,
        href: "/users/settings/auth/discord",
        id: "discord",
        linked: true,
        name: "Discord",
      },
    ],
  },
};
