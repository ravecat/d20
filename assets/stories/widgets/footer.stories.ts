import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { userEvent, within } from "storybook/test";
import Footer from "~/app/ui/footer.svelte";

const meta = {
  title: "Widgets/Footer",
  component: Footer,
  parameters: { layout: "fullscreen" },
  args: { variant: "narrow" },
} satisfies Meta<typeof Footer>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
export const MobileExpanded: Story = {
  globals: { viewport: { value: "mobile" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    for (const name of ["Explore", "Help"]) {
      await userEvent.click(await canvas.findByRole("heading", { name }));
    }
  },
};
