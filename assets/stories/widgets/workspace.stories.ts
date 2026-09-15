import type { Meta, StoryObj } from "@storybook/svelte-vite";
import { expect, userEvent, within } from "storybook/test";
import { Workspace } from "~/widgets/workspace";
import { clear, set, setStatus } from "~stories/mocks/phoenix_session";

const meta = {
  title: "Widgets/Workspace",
  component: Workspace,
  parameters: {
    layout: "fullscreen",
  },
} satisfies Meta<typeof Workspace>;

export default meta;
type Story = StoryObj<typeof meta>;

export const AutoSelection: Story = {
  beforeEach: () => {
    set({
      sessions: [
        {
          id: "session-a",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:session-a",
            token: "token-session-a",
          },
        },
        {
          id: "session-b",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:session-b",
            token: "token-session-b",
          },
        },
      ],
    });

    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const firstDialog = await canvas.findByRole("dialog", {
      name: "Game session session-a",
    });
    const secondDialog = canvas.getByRole("dialog", {
      name: "Game session session-b",
    });
    const compactFirst = canvas.getByRole("button", {
      name: "Compact Game session session-a",
    });
    const expandSecond = canvas.getByRole("button", {
      name: "Expand Game session session-b",
    });

    await expect(firstDialog).toBeVisible();
    await expect(secondDialog).toBeVisible();
    await expect(compactFirst).toBeVisible();
    await expect(expandSecond).toBeVisible();

    await userEvent.click(compactFirst);

    const restoreFirst = await canvas.findByRole("button", {
      name: "Expand Game session session-a",
    });
    const closeFirst = canvas.getByRole("button", {
      name: "Close Game session session-a",
    });
    const enterFullscreen = canvas.getByRole("button", {
      name: "Enter Game session session-a fullscreen",
    });

    restoreFirst.focus();
    await expect(restoreFirst).toHaveFocus();
    await userEvent.tab();
    await expect(closeFirst).toHaveFocus();
    await userEvent.tab();
    await expect(enterFullscreen).toHaveFocus();

    restoreFirst.focus();
    await userEvent.keyboard("{Enter}");

    const compactRestored = await canvas.findByRole("button", {
      name: "Compact Game session session-a",
    });
    await expect(
      within(
        canvas.getByRole("group", {
          name: "Game session session-a window controls",
        }),
      ).getAllByRole("button"),
    ).toEqual([closeFirst, enterFullscreen, compactRestored]);

    closeFirst.focus();
    await userEvent.tab();
    await expect(enterFullscreen).toHaveFocus();
    await userEvent.tab();
    await expect(compactRestored).toHaveFocus();
    await userEvent.keyboard(" ");

    const restoreWithKeyboard = await canvas.findByRole("button", {
      name: "Expand Game session session-a",
    });
    restoreWithKeyboard.focus();
    await userEvent.keyboard(" ");
    await expect(
      await canvas.findByRole("button", {
        name: "Compact Game session session-a",
      }),
    ).toBeVisible();

    // Fullscreen requires trusted user activation in browser tests.
    if (import.meta.env.VITEST === "true") {
      const { userEvent: browserUserEvent } = await import("vitest/browser");
      await browserUserEvent.click(enterFullscreen);
      await browserUserEvent.unhover(enterFullscreen);
    } else {
      await userEvent.click(enterFullscreen);
    }
    const exitFullscreen = await canvas.findByRole("button", {
      name: "Exit Game session session-a fullscreen",
    });
    await userEvent.click(exitFullscreen);
    await expect(
      await canvas.findByRole("button", {
        name: "Enter Game session session-a fullscreen",
      }),
    ).toBeVisible();

    await userEvent.click(canvas.getByRole("button", { name: "Compact Game session session-a" }));
    await userEvent.click(canvas.getByRole("button", { name: "Expand Game session session-b" }));
    await expect(
      await canvas.findByRole("button", {
        name: "Compact Game session session-b",
      }),
    ).toBeVisible();
  },
};

export const Fullscreen: Story = {
  beforeEach: () => {
    set({
      sessions: [
        {
          id: "fullscreen",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:fullscreen",
            token: "token-fullscreen",
          },
        },
      ],
    });

    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const enterFullscreen = await canvas.findByRole("button", {
      name: "Enter Game session fullscreen fullscreen",
    });

    // Fullscreen requires trusted user activation in browser tests.
    if (import.meta.env.VITEST === "true") {
      const { userEvent: browserUserEvent } = await import("vitest/browser");
      await browserUserEvent.click(enterFullscreen);
      await browserUserEvent.unhover(enterFullscreen);
    } else {
      await userEvent.click(enterFullscreen);
    }

    await expect(
      await canvas.findByRole("button", { name: "Exit Game session fullscreen fullscreen" }),
    ).toBeVisible();
    await expect(
      canvas.getByRole("button", { name: "Close Game session fullscreen" }),
    ).toBeVisible();
    await expect(
      canvas.queryByRole("button", { name: "Compact Game session fullscreen" }),
    ).not.toBeInTheDocument();
  },
};

export const ConnectionStatuses: Story = {
  beforeEach: () => {
    set({
      sessions: [
        {
          id: "live",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:live",
            token: "token-live",
          },
        },
        {
          id: "finished",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "finished",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:finished",
            token: "token-finished",
          },
        },
        {
          id: "session-with-an-identifier-that-exceeds-the-available-compact-lane",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:session-with-an-identifier-that-exceeds-the-available-compact-lane",
            token: "token-session-with-an-identifier-that-exceeds-the-available-compact-lane",
          },
        },
      ],
    });

    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await userEvent.click(await canvas.findByRole("button", { name: "Compact Game session live" }));

    await expect(canvas.getByText("Session live", { exact: true })).toBeVisible();
    await expect(canvas.getByText("Session finished", { exact: true })).toBeVisible();
    const longSessionLabel = canvas.getByText(
      "Session session-with-an-identifier-that-exceeds-the-available-compact-lane",
      { exact: true },
    );
    await expect(longSessionLabel).toBeVisible();

    const liveStatuses = canvas.getAllByText("Live", { exact: true });
    expect(liveStatuses).toHaveLength(2);
    for (const status of liveStatuses) {
      await expect(status).toBeVisible();
    }
    await expect(canvas.getByText("Finished", { exact: true })).toBeVisible();
  },
};

export const Reconnecting: Story = {
  beforeEach: () => {
    set({
      sessions: [
        {
          id: "reconnecting",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:reconnecting",
            token: "token-reconnecting",
          },
        },
      ],
    });
    setStatus("stale");

    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await expect(await canvas.findByRole("status")).toHaveTextContent("Reconnecting to game");
    await userEvent.click(
      canvas.getByRole("button", { name: "Compact Game session reconnecting" }),
    );
    await expect(canvas.getByText("Reconnecting", { exact: true })).toBeVisible();
    await expect(canvas.getByText("Session reconnecting", { exact: true })).toBeVisible();
  },
};

export const Failed: Story = {
  beforeEach: () => {
    set({
      sessions: [
        {
          id: "failed",
          game_id: "game_01h45yhtgqfhxbcrsfbhxdsdvy",
          phase: "in_progress",
          module: {
            embed_url: "about:blank",
            allowed_origins: ["null"],
            sandbox: [],
          },
          connection: {
            endpoint: "wss://module.example.test/socket",
            topic: "session:failed",
            token: "token-failed",
          },
        },
      ],
    });
    setStatus("failed");

    return clear;
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);

    await expect(await canvas.findByRole("status")).toHaveTextContent("Connection to game failed");
    await userEvent.click(canvas.getByRole("button", { name: "Compact Game session failed" }));
    await expect(canvas.getByText("Failed", { exact: true })).toBeVisible();
    await expect(canvas.getByText("Session failed", { exact: true })).toBeVisible();
  },
};
