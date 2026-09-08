import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, within } from "storybook/test";
import { ContactPage } from "~/pages/contact";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  title: "Pages/Public/∕contact",
  component: ContactPage,
  decorators: [
    (story: unknown) =>
      withLayout({ url: "/contact" })(story, {
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
    await expect(content.getByRole("link", { name: "support@d20.ravecat.io" })).toHaveAttribute(
      "href",
      "mailto:support@d20.ravecat.io",
    );
    await expect(content.getByRole("link", { name: "rights@d20.ravecat.io" })).toHaveAttribute(
      "href",
      "mailto:rights@d20.ravecat.io",
    );
    await expect(
      content.getByRole("link", { name: "For publishers and rightholders" }),
    ).toHaveAttribute("href", "/rights-holders");
  },
} satisfies Meta<typeof ContactPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Index: Story = {};
export const Dark: Story = { globals: { theme: "dark" } };
