import type { Meta, StoryObj } from "@storybook/svelte-vite";
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
