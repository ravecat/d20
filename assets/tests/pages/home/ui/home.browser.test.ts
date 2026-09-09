import { afterEach, describe, expect, it, vi } from "vitest";
import { cdp, page, server, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import { HomePage } from "~/pages/home";
import { fourBrowseGames, providerOnlyGames, threePlayableGames } from "~stories/fixtures/home";
import inertiaMock from "../../../mocks/inertia";
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

  it("uses Inertia for both local and numeric provider detail links", async () => {
    inertiaMock.reset();
    const originalAction = inertiaMock.inertia.getMockImplementation();
    if (!originalAction) throw new Error("Expected an Inertia action mock.");
    inertiaMock.inertia.mockImplementation((node: HTMLElement, params: { href: string }) => {
      const navigate = (event: MouseEvent) => {
        event.preventDefault();
        inertiaMock.router.visit(params.href);
      };
      node.addEventListener("click", navigate);
      return {
        update: vi.fn(),
        destroy: () => node.removeEventListener("click", navigate),
      };
    });

    try {
      await render(HomePage, {
        auth,
        playableGames: threePlayableGames.slice(0, 1),
        games: providerOnlyGames,
      });

      const localLink = page.getByRole("link", { name: "Koala Rescue Club" });
      await expect.element(localLink).toHaveAttribute("href", "/games/koala-rescue-club");
      await localLink.click();
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/koala-rescue-club");

      const providerLink = page.getByRole("link", { name: "Voyages" });
      await expect.element(providerLink).toHaveAttribute("href", "/games/350736");
      await expect.element(page.getByText("In development")).not.toBeInTheDocument();
      await providerLink.click();
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/350736");
      expect(inertiaMock.router.visit).toHaveBeenCalledTimes(2);
    } finally {
      inertiaMock.inertia.mockImplementation(originalAction);
      inertiaMock.reset();
    }
  });

  it("renders one-game sections at a narrow viewport", async () => {
    await page.viewport(320, 900);
    await render(HomePage, {
      auth,
      playableGames: threePlayableGames.slice(0, 1),
      games: fourBrowseGames.slice(0, 1),
    });

    await page.getByRole("heading", { name: "Playable", exact: true }).hover();
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
