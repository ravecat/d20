import { afterEach, describe, expect, it } from "vitest";
import { cdp, page, server, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import { HomePage } from "~/pages/home";
import { fourBrowseGames, threePlayableGames } from "~stories/fixtures/home";
import "../../../../css/app.css";

const auth = {
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
};

afterEach(async () => {
  await page.viewport(1280, 800);
});

describe("home page", () => {
  it("tabs through canonical links and excludes decorative duplicates", async () => {
    await render(HomePage, { auth, playableGames: [], games: fourBrowseGames });

    const games = page.getByRole("region", { name: "Games" });
    const names = ["Voyages", "Death Valley", "Deep Sea Adventure", "Confusing Lands"];
    expect(games.getByRole("link").elements()).toHaveLength(names.length);

    for (const name of names) {
      await userEvent.tab();
      await expect.element(games.getByRole("link", { name })).toHaveFocus();
      await expect(games).toMatchScreenshot(`focus-${name.toLowerCase().replace(/ /g, "-")}.png`);
    }
    await userEvent.tab();
    expect(games.element().contains(document.activeElement)).toBe(false);
  });

  it("renders one-game sections at a narrow viewport", async () => {
    await page.viewport(320, 900);
    await render(HomePage, {
      auth,
      playableGames: threePlayableGames.slice(0, 1),
      games: fourBrowseGames.slice(0, 1),
    });

    await expect(document.documentElement).toMatchScreenshot("single-game-mobile.png");
  });

  it.skipIf(server.browser !== "chromium")("renders the reduced-motion presentation", async () => {
    const session = cdp();
    await session.send("Emulation.setEmulatedMedia", {
      features: [{ name: "prefers-reduced-motion", value: "reduce" }],
    });
    try {
      await render(HomePage, {
        auth,
        playableGames: threePlayableGames,
        games: fourBrowseGames,
      });
      await expect(document.documentElement).toMatchScreenshot("reduced-motion.png");
      await userEvent.tab();
      await expect.element(page.getByRole("link", { name: "Koala Rescue Club" })).toHaveFocus();
    } finally {
      await session.send("Emulation.setEmulatedMedia", { features: [] });
    }
  });
});
