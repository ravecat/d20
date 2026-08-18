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
    apple: { available: true, linked: false },
    discord: { available: false, linked: false },
    email: "player@example.com",
    google: { available: true, linked: true },
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
    apple: { available: false, linked: false },
    discord: { available: false, linked: true },
    google: { available: false, linked: false },
  },
};
