import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { HomePage } from "~/pages/home";

const meta = {
  id: "home",
  title: "Pages/∕",
  component: HomePage,
  parameters: {
    layout: "fullscreen",
  },
  args: {
    auth: {
      authenticated: false,
      local: false,
      prompt: null,
      providers: {
        apple: { available: true },
        discord: { available: true },
        facebook: { available: true },
        google: { available: true },
        steam: { available: true },
      },
    },
    games: [
      {
        id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
        stage: "released",
        game: {
          name: "Qwinto",
          alternateNames: [],
          categories: ["Dice", "Number"],
          mechanics: ["Dice Rolling", "Paper-and-Pencil"],
        },
      },
      {
        id: "game_01h45y0sxkfmntta78gqs1vsw6",
        stage: "in_development",
        game: {
          name: "Koala Rescue Club",
          alternateNames: [],
          categories: ["Animals", "Puzzle"],
          mechanics: ["Dice Rolling", "Pattern Building"],
        },
      },
      {
        id: "game_01h45ybmy7fj7b4r9vvp74ms6k",
        stage: "planned",
        game: {
          name: "Voyages",
          alternateNames: [],
          categories: ["Exploration", "Nautical"],
          mechanics: ["Dice Rolling", "Grid Coverage"],
        },
      },
    ],
  },
} satisfies Meta<typeof HomePage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Catalog: Story = {};
