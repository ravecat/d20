import type { Meta, StoryObj } from "@storybook/svelte-vite";
import AuthDialog from "~/shared/components/auth_dialog.svelte";
import { prepareAuthDialog } from "../fixtures/auth_dialog";
import PreventNavigation from "../mocks/prevent_navigation.svelte";

const meta = {
  title: "Pages/Sign Up/Authentication Dialog",
  component: AuthDialog,
  decorators: [() => ({ Component: PreventNavigation })],
  parameters: {
    layout: "fullscreen",
  },
} satisfies Meta<typeof AuthDialog>;

export default meta;
type Story = StoryObj<typeof meta>;

export const RegistrationMethods: Story = {
  beforeEach: () => prepareAuthDialog({ mode: "register" }),
};

export const ConfirmationEmailSent: Story = {
  beforeEach: () => prepareAuthDialog({ mode: "register", outcome: "registration_email_sent" }),
};
