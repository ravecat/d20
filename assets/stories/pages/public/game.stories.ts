import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import type { SessionDescriptor } from "~/shared/types/game";
import { GamePage } from "~/pages/game";
import { auth } from "~/shared/stores";
import { withLayout } from "~stories/decorators/layout";
import { reset } from "~stories/mocks/inertia_svelte";
import { clear, set } from "~stories/mocks/phoenix_session";

const meta = {
  title: "Pages/Public/∕games∕:slug",
  id: "pages-game",
  component: GamePage,
  decorators: [
    (
      story: unknown,
      context: {
        args: { slug?: string; auth?: InertiaProps["auth"]; session?: SessionDescriptor | null };
      },
    ) =>
      withLayout({
        url: `/games/${context.args.slug}${context.args.session ? `?session=${context.args.session.id}` : ""}`,
        variant: "wide",
      })(story, context),
  ],
  parameters: { layout: "fullscreen" },
  beforeEach: () => {
    auth.trigger.reset();
    clear();
    reset();
    return () => {
      auth.trigger.reset();
      clear();
      reset();
    };
  },
  args: {
    auth: {
      authenticated: false,
      local: false,
      prompt: null,
      providers: {
        apple: { available: false },
        discord: { available: true },
        facebook: { available: false },
        google: { available: true },
        steam: { available: false },
      },
    },
    id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
    slug: "qwinto",
    stage: "released",
    playable: true,
    interest: { action: "/games/qwinto/interest", requested: false, count: 12 },
    game: {
      name: "Qwinto",
      alternateNames: [],
      categories: ["Dice", "Number"],
      mechanics: ["Dice Rolling", "Paper-and-Pencil"],
      description:
        "Roll the dice and fill your score sheet with increasing numbers. Choose where to write each total, complete rows, and collect bonuses while avoiding failed attempts.",
      minPlayers: 2,
      maxPlayers: 6,
      playingTime: 15,
      minAge: 8,
      complexity: 1.2,
      rating: 7.4,
      imageUrl: null,
      thumbnailUrl: null,
    },
    schema: { type: "object", properties: {}, default: {} },
    session: null,
  },
} satisfies Meta<typeof GamePage>;

export default meta;
type Story = StoryObj<typeof meta>;

export const WithoutSession: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("heading", { name: "Qwinto", level: 1 })).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Play" })).toBeEnabled();
    await expect(canvas.queryByRole("list", { name: "Joined players" })).not.toBeInTheDocument();
    await expect(
      canvas.queryByRole("button", { name: "I want this game!" }),
    ).not.toBeInTheDocument();
  },
};

export const WithSession: Story = {
  args: {
    session: {
      id: "session-qwinto",
      gameId: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
      slug: "qwinto",
      topic: "session:session-qwinto",
    },
  },
  beforeEach: () => {
    set({
      id: "session-qwinto",
      phase: "waiting_for_players",
      owner_id: "player-alex",
      members: {
        "player-alex": { status: "online", display_name: "Alex", avatar: null },
        "player-sam": { status: "online", display_name: "Sam", avatar: null },
      },
      permissions: { can_start_game: true },
      game: {},
    });
    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const players = within(await canvas.findByRole("list", { name: "Joined players" }));
    await expect(players.getByText("Alex")).toBeVisible();
    await expect(players.getByText("Sam")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Start" })).toBeEnabled();
    await expect(canvas.queryByRole("button", { name: "Play" })).not.toBeInTheDocument();
    await expect(
      canvas.queryByRole("button", { name: "I want this game!" }),
    ).not.toBeInTheDocument();
  },
};

export const UnavailableGame: Story = {
  args: {
    id: null,
    slug: "183006",
    stage: null,
    playable: false,
    schema: null,
    interest: { action: "/games/183006/interest", requested: false, count: 12 },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "I want this game!" })).toBeEnabled();
    await expect(
      canvas.getByRole("button", { name: "I want this game!" }),
    ).toHaveAccessibleDescription("12 players have requested this game.");
    await expect(canvas.queryByRole("button", { name: "Play" })).not.toBeInTheDocument();
    await expect(canvas.queryByRole("list", { name: "Joined players" })).not.toBeInTheDocument();
  },
};

export const Requested: Story = {
  args: {
    ...UnavailableGame.args,
    auth: { ...meta.args.auth, authenticated: true },
    interest: { action: "/games/183006/interest", requested: true, count: 13 },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Requested" })).toBeDisabled();
    await expect(canvas.getByRole("button", { name: "Requested" })).toHaveAccessibleDescription(
      "13 players have requested this game.",
    );
    await expect(canvas.queryByRole("status")).not.toBeInTheDocument();
    await expect(canvas.queryByText("Request saved.")).not.toBeInTheDocument();
    await expect(
      canvas.queryByRole("button", { name: "I want this game!" }),
    ).not.toBeInTheDocument();
  },
};

export const HeaderFocused: Story = {
  play: async ({ canvasElement }) => {
    await userEvent.tab();
    await expect(within(canvasElement).getByRole("link", { name: "D20" })).toHaveFocus();
  },
};
