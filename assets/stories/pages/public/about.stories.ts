import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { AboutPage } from "~/pages/about";
import { withLayout } from "~stories/decorators/layout";

const meta = {
  title: "Pages/Public/∕about",
  component: AboutPage,
  decorators: [
    (story: unknown) =>
      withLayout({ url: "/about" })(story, {
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
} satisfies Meta<typeof AboutPage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Index: Story = {};
