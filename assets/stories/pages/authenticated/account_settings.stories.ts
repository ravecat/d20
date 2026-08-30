import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AccountSettingsPage } from "~/pages/account_settings";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  title: "Pages/Authenticated/∕profile",
  id: "pages-settings",
  component: AccountSettingsPage,
  decorators: [withLayout({ url: "/profile" })],
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
        facebook: { available: true },
        google: { available: true },
        steam: { available: true },
      },
    },
    email: "player@example.com",
    providers: [
      {
        available: true,
        href: "/profile/auth/google",
        id: "google",
        linked: true,
        name: "Google",
      },
      {
        available: true,
        href: "/profile/auth/apple",
        id: "apple",
        linked: false,
        name: "Apple",
      },
      {
        available: false,
        href: "/profile/auth/discord",
        id: "discord",
        linked: false,
        name: "Discord",
      },
      {
        available: true,
        href: "/profile/auth/facebook",
        id: "facebook",
        linked: false,
        name: "Facebook",
      },
      {
        available: true,
        href: "/profile/auth/steam",
        id: "steam",
        linked: false,
        name: "Steam",
      },
    ],
    username: "table_master",
  },
} satisfies Meta<typeof AccountSettingsPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const EstablishedAccount: Story = {};

export const ProviderOnlyAccount: Story = {
  args: {
    email: null,
    providers: [
      {
        available: true,
        href: "/profile/auth/google",
        id: "google",
        linked: true,
        name: "Google",
      },
      {
        available: true,
        href: "/profile/auth/apple",
        id: "apple",
        linked: false,
        name: "Apple",
      },
      {
        available: false,
        href: "/profile/auth/discord",
        id: "discord",
        linked: false,
        name: "Discord",
      },
      {
        available: true,
        href: "/profile/auth/facebook",
        id: "facebook",
        linked: true,
        name: "Facebook",
      },
      {
        available: true,
        href: "/profile/auth/steam",
        id: "steam",
        linked: true,
        name: "Steam",
      },
    ],
    username: "provider_only",
  },
};

export const NoAvailableProviders: Story = {
  args: {
    auth: {
      authenticated: true,
      local: false,
      prompt: null,
      providers: {
        apple: { available: false },
        discord: { available: false },
        facebook: { available: false },
        google: { available: false },
        steam: { available: false },
      },
    },
    providers: [
      {
        available: false,
        href: "/profile/auth/google",
        id: "google",
        linked: false,
        name: "Google",
      },
      {
        available: false,
        href: "/profile/auth/apple",
        id: "apple",
        linked: false,
        name: "Apple",
      },
      {
        available: false,
        href: "/profile/auth/discord",
        id: "discord",
        linked: true,
        name: "Discord",
      },
      {
        available: false,
        href: "/profile/auth/facebook",
        id: "facebook",
        linked: false,
        name: "Facebook",
      },
      {
        available: false,
        href: "/profile/auth/steam",
        id: "steam",
        linked: false,
        name: "Steam",
      },
    ],
  },
};
