import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, within } from "storybook/test";
import { RightsHoldersPage } from "~/pages/rights_holders";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  title: "Pages/Public/∕rights-holders",
  component: RightsHoldersPage,
  decorators: [
    (story: unknown) =>
      withLayout({ url: "/rights-holders" })(story, {
        args: {
          auth: {
            authenticated: false,
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
        },
      }),
  ],
  parameters: { layout: "fullscreen" },
  play: async ({ canvasElement }) => {
    const content = within(within(canvasElement).getByRole("main"));
    await expect(content.getByRole("link", { name: "rights@d20.ravecat.io" })).toHaveAttribute(
      "href",
      "mailto:rights@d20.ravecat.io",
    );
    await expect(content.getByRole("link", { name: "Contact / support" })).toHaveAttribute(
      "href",
      "/contact",
    );
  },
} satisfies Meta<typeof RightsHoldersPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Index: Story = {};
export const Dark: Story = { globals: { theme: "dark" } };
