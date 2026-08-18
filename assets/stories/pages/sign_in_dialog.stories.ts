import type { Meta, StoryObj } from "@storybook/svelte-vite";
import AuthDialog from "~/shared/components/auth_dialog.svelte";
import { prepareAuthDialog } from "../fixtures/auth_dialog";
import PreventNavigation from "../mocks/prevent_navigation.svelte";

const meta = {
  title: "Pages/Sign In/Authentication Dialog",
  component: AuthDialog,
  decorators: [() => ({ Component: PreventNavigation })],
  parameters: {
    layout: "fullscreen",
  },
} satisfies Meta<typeof AuthDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const LoginMethods: Story = {
  beforeEach: () => prepareAuthDialog({ mode: "login" }),
};

export const MagicLinkSent: Story = {
  beforeEach: () => prepareAuthDialog({ mode: "login", outcome: "magic_link_sent" }),
};

export const Reauthentication: Story = {
  beforeEach: () =>
    prepareAuthDialog({
      mode: "login",
      prompt: {
        email: "player@example.com",
        kind: "warning",
        message: "You must re-authenticate to access this page.",
        reauthenticate: true,
        returnTo: "/users/settings",
      },
    }),
};
