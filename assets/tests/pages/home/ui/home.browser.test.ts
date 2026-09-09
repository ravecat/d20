import { afterEach, describe, expect, it, vi } from "vitest";
import { cdp, page, server, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import { HomePage } from "~/pages/home";
import {
  fourBrowseGames,
  homeBrowseGames,
  providerOnlyGames,
  threePlayableGames,
} from "~stories/fixtures/home";
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
  it("reveals every canonical Playable link when tabbing through a narrow centered row", async () => {
    await page.viewport(320, 900);
    await render(HomePage, { auth, playableGames: threePlayableGames, games: [] });

    const playable = page.getByRole("region", { name: "Playable" });
    await playable.getByRole("heading", { name: "Playable" }).click();
    for (const name of ["Koala Rescue Club", "Qwinto", "Next Station: London"]) {
      await userEvent.tab();
      await expect.element(playable.getByRole("link", { name })).toHaveFocus();
      await expect(playable).toMatchScreenshot(
        `playable-focus-${name.toLowerCase().replace(/[: ]+/g, "-")}.png`,
      );
    }
    await userEvent.tab();
    expect(playable.element().contains(document.activeElement)).toBe(false);
  });

  it("tabs through both canonical lanes and excludes loop copies", async () => {
    await page.viewport(320, 900);
    await render(HomePage, { auth, playableGames: [], games: fourBrowseGames });

    const games = page.getByRole("region", { name: "Games" });
    await games.getByRole("heading", { name: "Games" }).click();
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

  for (const reducedMotion of [false, true]) {
    it.skipIf(reducedMotion && server.browser !== "chromium")(
      `reaches all 32 Games links forward and backward${reducedMotion ? " with reduced motion" : ""}`,
      async () => {
        const session = reducedMotion ? cdp() : undefined;
        await session?.send("Emulation.setEmulatedMedia", {
          features: [{ name: "prefers-reduced-motion", value: "reduce" }],
        });
        const afterGames = document.createElement("button");
        afterGames.textContent = "After games";
        try {
          await page.viewport(320, 900);
          await render(HomePage, { auth, playableGames: [], games: homeBrowseGames });
          document.body.append(afterGames);
          const games = page.getByRole("region", { name: "Games" });
          await games.getByRole("heading", { name: "Games" }).click();
          expect(games.getByRole("link").elements()).toHaveLength(32);
          for (const entry of homeBrowseGames) {
            await userEvent.tab();
            await expect
              .element(games.getByRole("link", { name: entry.game.name!, exact: true }))
              .toHaveFocus();
          }
          await expect(games).toMatchScreenshot(
            `last-compact-focus${reducedMotion ? "-reduced-motion" : ""}.png`,
          );
          await userEvent.tab();
          expect(games.element().contains(document.activeElement)).toBe(false);
          await expect.element(page.getByRole("button", { name: "After games" })).toHaveFocus();
          for (const entry of [...homeBrowseGames].reverse()) {
            await userEvent.tab({ shift: true });
            await expect
              .element(games.getByRole("link", { name: entry.game.name!, exact: true }))
              .toHaveFocus();
          }
          await userEvent.tab({ shift: true });
          expect(games.element().contains(document.activeElement)).toBe(false);
        } finally {
          afterGames.remove();
          await session?.send("Emulation.setEmulatedMedia", { features: [] });
        }
      },
    );
  }

  it("delivers pointer and Enter activation to the Inertia action mock for local and numeric links", async () => {
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
        games: [fourBrowseGames[0], fourBrowseGames[1], providerOnlyGames[0]],
      });

      const games = page.getByRole("region", { name: "Games" });
      await games.getByRole("heading", { name: "Games" }).hover();
      const compact = games.getByRole("list", { name: "More games" });
      const visibleCopy = compact
        .getByRole("link", { includeHidden: true })
        .filter({ hasText: "Death Valley" })
        .nth(1);
      await expect.element(visibleCopy).toHaveAttribute("href", "/games/death-valley");
      await visibleCopy.click({ position: { x: 2, y: 20 } });
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/death-valley");

      const providerLink = compact.getByRole("link", { name: "Voyages" });
      await expect.element(providerLink).toHaveAttribute("href", "/games/350736");
      await providerLink.click();
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/350736");

      const heroLink = games
        .getByRole("list", { name: "Featured games" })
        .getByRole("link", { name: "Voyages" });
      await heroLink.click();
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/voyages");

      const compactLocalLink = compact.getByRole("link", { name: "Death Valley" });
      await games.getByRole("heading", { name: "Games" }).click();
      await userEvent.tab();
      await userEvent.tab();
      await expect.element(compactLocalLink).toHaveFocus();
      await userEvent.keyboard("{Enter}");
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/death-valley");

      const localLink = page.getByRole("link", { name: "Koala Rescue Club" });
      await expect.element(localLink).toHaveAttribute("href", "/games/koala-rescue-club");
      await localLink.click();
      expect(inertiaMock.router.visit).toHaveBeenLastCalledWith("/games/koala-rescue-club");
      expect(inertiaMock.router.visit).toHaveBeenCalledTimes(5);
    } finally {
      inertiaMock.inertia.mockImplementation(originalAction);
      inertiaMock.reset();
    }
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
      await page.getByRole("heading", { name: "Playable", exact: true }).hover();
      await expect(document.documentElement).toMatchScreenshot("reduced-motion.png");
      await userEvent.tab();
      await expect.element(page.getByRole("link", { name: "Koala Rescue Club" })).toHaveFocus();
    } finally {
      await session.send("Emulation.setEmulatedMedia", { features: [] });
    }
  });
});
