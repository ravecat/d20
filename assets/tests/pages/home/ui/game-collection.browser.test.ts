import { createRawSnippet } from "svelte";
import { afterEach, expect, it } from "vitest";
import { page, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import GameCollection from "~/pages/home/ui/game-collection.svelte";
import { eightPlayableGames } from "~stories/fixtures/home";
import inertiaMock from "../../../mocks/inertia";
import "../../../../css/app.css";

afterEach(() => inertiaMock.reset());

it.each([
  { count: 6, rowCounts: [6] },
  { count: 7, rowCounts: [4, 3] },
  { count: 8, rowCounts: [4, 4] },
])(
  "keeps $count playable games in ordered compact rows and keyboard order",
  async ({ count, rowCounts }) => {
    const games = eightPlayableGames.slice(0, count);
    await render(GameCollection, {
      games,
      header: createRawSnippet(() => ({
        render: () => "<span>Playable</span>",
      })),
      variant: "compact",
    });
    const collection = page.getByRole("region", { name: "Playable" });
    expect(collection.getByRole("list", { name: "Featured games" }).elements()).toHaveLength(0);
    expect(collection.getByRole("list", { name: "More games" }).elements()).toHaveLength(0);
    expect(
      collection
        .getByRole("link")
        .elements()
        .map((link) => link.getAttribute("href")),
    ).toEqual(games.map((entry) => `/games/${entry.slug}`));

    let offset = 0;
    for (const [index, rowCount] of rowCounts.entries()) {
      const name = rowCounts.length === 1 ? "" : `Row ${index + 1}`;
      const row = collection.getByRole("list", { name, exact: true });
      expect(row.elements()).toHaveLength(1);
      expect(
        row
          .getByRole("link")
          .elements()
          .map((link) => link.getAttribute("href")),
      ).toEqual(games.slice(offset, offset + rowCount).map((entry) => `/games/${entry.slug}`));
      offset += rowCount;
    }
    if (rowCounts.length === 1) {
      expect(collection.getByRole("list", { name: /^Row / }).elements()).toHaveLength(0);
    }

    await collection.getByRole("heading", { name: "Playable" }).click();
    for (const entry of games) {
      await userEvent.tab();
      await expect.element(collection.getByRole("link", { name: entry.game.name! })).toHaveFocus();
      await userEvent.tab();
      await expect
        .element(
          collection.getByRole("button", {
            name: `Add ${entry.game.name} to favorites`,
          }),
        )
        .toHaveFocus();
    }
  },
);
