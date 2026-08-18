import type { Meta, StoryObj } from "@storybook/svelte-vite";
import PlayerCountLabel from "~/shared/components/player_count_label.svelte";

const meta = {
  title: "Shared/Player Count Label",
  component: PlayerCountLabel,
  parameters: {
    layout: "centered",
  },
  args: {
    game: {
      name: "Qwinto",
      alternateNames: [],
      categories: [],
      mechanics: [],
      minPlayers: 2,
      maxPlayers: 6,
    },
  },
} satisfies Meta<typeof PlayerCountLabel>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Range: Story = {};

export const Fixed: Story = {
  args: {
    game: {
      name: "Solo Game",
      alternateNames: [],
      categories: [],
      mechanics: [],
      minPlayers: 1,
      maxPlayers: 1,
    },
  },
};

export const MinimumOnly: Story = {
  args: {
    game: {
      name: "Open Group Game",
      alternateNames: [],
      categories: [],
      mechanics: [],
      minPlayers: 3,
    },
  },
};

export const MaximumOnly: Story = {
  args: {
    game: {
      name: "Capped Group Game",
      alternateNames: [],
      categories: [],
      mechanics: [],
      maxPlayers: 8,
    },
  },
};
