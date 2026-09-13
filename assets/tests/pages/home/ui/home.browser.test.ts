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
  it("attributes Hot to BGG without attributing Playable or hiding a focusable link", async () => {
    const view = await render(HomePage, {
      auth,
      playableGames: threePlayableGames,
      games: fourBrowseGames,
    });

    const pageHeading = page.getByRole("heading", {
      name: "Games",
      level: 1,
    });
    await expect.element(pageHeading).toBeInTheDocument();
    expect(pageHeading.getByRole("link").elements()).toHaveLength(0);
    const hot = page.getByRole("region", { name: "Hot (by BGG)" });
    const attribution = hot
      .getByRole("heading", { name: "Hot (by BGG)", level: 2 })
      .getByRole("link", { name: "by BGG" });
    await expect.element(attribution).toBeVisible();
    await expect.element(attribution).toHaveAttribute("href", "https://boardgamegeek.com/hotness");
    expect(page.getByRole("link", { name: "by BGG" }).elements()).toHaveLength(1);
    expect(
      page
        .getByRole("region", { name: "Playable" })
        .getByRole("link", { name: "by BGG" })
        .elements(),
    ).toHaveLength(0);
    attribution.element().focus();
    await expect.element(attribution).toHaveFocus();
    await userEvent.tab();
    await expect.element(hot.getByRole("link", { name: "Voyages" })).toHaveFocus();

    await view.rerender({ games: [] });
    expect(page.getByRole("region", { name: "Hot (by BGG)" }).elements()).toHaveLength(0);
    expect(page.getByRole("link", { name: "by BGG" }).elements()).toHaveLength(0);
    await expect.element(pageHeading).toBeInTheDocument();
    await expect.element(page.getByRole("region", { name: "Playable" })).toBeVisible();
  });

  it("reveals every canonical Playable link when tabbing through a narrow centered row", async () => {
    await page.viewport(320, 900);
    await render(HomePage, {
      auth,
      playableGames: threePlayableGames,
      games: [],
    });

    const playable = page.getByRole("region", { name: "Playable" });
    await playable.getByRole("heading", { name: "Playable" }).click();
    for (const name of ["Koala Rescue Club", "Qwinto", "Next Station: London"]) {
      await userEvent.tab();
      await expect.element(playable.getByRole("link", { name })).toHaveFocus();
      await expect(playable).toMatchScreenshot(
        `playable-focus-${name.toLowerCase().replace(/[: ]+/g, "-")}.png`,
      );
      await userEvent.tab();
      await expect
        .element(playable.getByRole("button", { name: `Add ${name} to favorites` }))
        .toHaveFocus();
    }
    await userEvent.tab();
    expect(playable.element().contains(document.activeElement)).toBe(false);
  });

  it("tabs through both canonical lanes and excludes loop copies", async () => {
    await page.viewport(320, 900);
    await render(HomePage, { auth, playableGames: [], games: fourBrowseGames });
    const afterGames = document.createElement("button");
    afterGames.textContent = "After games";
    document.body.append(afterGames);

    try {
      const games = page.getByRole("region", { name: "Hot (by BGG)" });
      games.getByRole("link", { name: "by BGG" }).element().focus();
      const names = ["Voyages", "Death Valley", "Deep Sea Adventure", "Confusing Lands"];
      expect(games.getByRole("link").elements()).toHaveLength(names.length + 1);

      for (const name of names) {
        await userEvent.tab();
        await expect.element(games.getByRole("link", { name })).toHaveFocus();
        await expect(games).toMatchScreenshot(`focus-${name.toLowerCase().replace(/ /g, "-")}.png`);
        await userEvent.tab();
        await expect
          .element(games.getByRole("button", { name: `Add ${name} to favorites` }))
          .toHaveFocus();
      }
      await userEvent.tab();
      await expect.element(page.getByRole("button", { name: "After games" })).toHaveFocus();
      expect(games.element().contains(document.activeElement)).toBe(false);
    } finally {
      afterGames.remove();
    }
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
          await render(HomePage, {
            auth,
            playableGames: [],
            games: homeBrowseGames,
          });
          document.body.append(afterGames);
          const games = page.getByRole("region", { name: "Hot (by BGG)" });
          games.getByRole("link", { name: "by BGG" }).element().focus();
          expect(games.getByRole("link").elements()).toHaveLength(33);
          for (const entry of homeBrowseGames) {
            await userEvent.tab();
            await expect
              .element(
                games.getByRole("link", {
                  name: entry.game.name!,
                  exact: true,
                }),
              )
              .toHaveFocus();
            await userEvent.tab();
            await expect
              .element(
                games.getByRole("button", {
                  name: `Add ${entry.game.name} to favorites`,
                }),
              )
              .toHaveFocus();
          }
          await expect(document.documentElement).toMatchScreenshot(
            `last-compact-focus${reducedMotion ? "-reduced-motion" : ""}.png`,
          );
          await userEvent.tab();
          expect(games.element().contains(document.activeElement)).toBe(false);
          await expect.element(page.getByRole("button", { name: "After games" })).toHaveFocus();
          for (const entry of [...homeBrowseGames].reverse()) {
            await userEvent.tab({ shift: true });
            await expect
              .element(
                games.getByRole("button", {
                  name: `Add ${entry.game.name} to favorites`,
                }),
              )
              .toHaveFocus();
            await userEvent.tab({ shift: true });
            await expect
              .element(
                games.getByRole("link", {
                  name: entry.game.name!,
                  exact: true,
                }),
              )
              .toHaveFocus();
          }
          await userEvent.tab({ shift: true });
          await expect.element(games.getByRole("link", { name: "by BGG" })).toHaveFocus();
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
      inertiaMock.setPage({
        props: {
          ...inertiaMock.page.props,
          auth: { ...auth, authenticated: true },
        },
      });
      const view = await render(HomePage, {
        auth: { ...auth, authenticated: true },
        playableGames: threePlayableGames.slice(0, 1),
        games: [fourBrowseGames[0], fourBrowseGames[1], providerOnlyGames[0]],
      });

      const games = page.getByRole("region", { name: "Hot (by BGG)" });
      await games.getByRole("heading", { name: "Hot (by BGG)" }).hover();
      const compact = games.getByRole("list", { name: "More games" });
      const visibleCopy = compact
        .getByRole("link", { name: "Death Valley", includeHidden: true })
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

      const compactLocalLink = compact.getByRole("link", {
        name: "Death Valley",
      });
      games.getByRole("link", { name: "by BGG" }).element().focus();
      await userEvent.tab();
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
      games.getByRole("link", { name: "by BGG" }).element().focus();
      const copyStar = compact
        .getByRole("listitem", { includeHidden: true })
        .filter({ hasText: "Death Valley" })
        .nth(1)
        .getByRole("button", { includeHidden: true });
      await copyStar.click();
      inertiaMock.setPage({
        props: {
          ...inertiaMock.page.props,
          favorites: [fourBrowseGames[1].id],
        },
      });
      await view.rerender({ favorites: [fourBrowseGames[1].id] });
      inertiaMock.respondWithSuccess();
      await expect
        .element(
          compact.getByRole("button", {
            name: "Remove Death Valley from favorites",
          }),
        )
        .toHaveAttribute("aria-pressed", "true");
      await expect.element(copyStar).toHaveAttribute("aria-pressed", "true");
      expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
      expect(inertiaMock.router.visit).toHaveBeenCalledTimes(5);
      expect(inertiaMock.router.reload).not.toHaveBeenCalled();
    } finally {
      inertiaMock.inertia.mockImplementation(originalAction);
      inertiaMock.reset();
      vi.unstubAllGlobals();
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
