import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { page } from "vitest/browser";
import { GamePage } from "~/pages/game";
import type { Attrs, GameMetadata } from "~/shared/types";

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  await page.viewport(412, 915);
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("game detail responsive spacing", () => {
  it("uses compact intrinsic spacing when the detail panels stack", () => {
    renderGame();

    const activation = page.getByRole("complementary", { name: "Game activation" }).element();
    const description = page.getByRole("region", { name: "Description" }).element();
    const descriptionContent = page.getByText(/^Long game description\./).element();
    const action = page.getByRole("button", { name: "Play" }).element();
    const shell = requiredElement(".game-detail-shell");
    const preview = requiredElement(".game-detail-preview");

    expect(preview.getBoundingClientRect().top).toBeCloseTo(shell.getBoundingClientRect().top, 0);
    expect(preview.getBoundingClientRect().left - shell.getBoundingClientRect().left).toBeCloseTo(
      16,
      3,
    );
    expect(shell.getBoundingClientRect().right - preview.getBoundingClientRect().right).toBeCloseTo(
      16,
      3,
    );
    expect(
      activation.getBoundingClientRect().bottom - action.getBoundingClientRect().bottom,
    ).toBeCloseTo(0, 3);
    expect(action.getBoundingClientRect().left).toBeCloseTo(
      activation.getBoundingClientRect().left,
      3,
    );
    expect(action.getBoundingClientRect().right).toBeCloseTo(
      activation.getBoundingClientRect().right,
      3,
    );
    expect(descriptionContent.getBoundingClientRect().top).toBeCloseTo(
      description.getBoundingClientRect().top,
      3,
    );
    expect(descriptionContent.getBoundingClientRect().left).toBeCloseTo(
      description.getBoundingClientRect().left,
      3,
    );
    expect(
      description.getBoundingClientRect().top - activation.getBoundingClientRect().bottom,
    ).toBeCloseTo(16, 3);
  });

  it("uses compact intrinsic activation sizing in the wide split layout", async () => {
    await page.viewport(1280, 800);
    renderGame();

    const activation = page.getByRole("complementary", { name: "Game activation" }).element();
    const description = page.getByRole("region", { name: "Description" }).element();
    const descriptionContent = page.getByText(/^Long game description\./).element();
    const action = page.getByRole("button", { name: "Play" }).element();
    const shell = requiredElement(".game-detail-shell");
    const preview = requiredElement(".game-detail-preview");

    expect(preview.getBoundingClientRect().top).toBeCloseTo(shell.getBoundingClientRect().top, 0);
    expect(preview.getBoundingClientRect().left - shell.getBoundingClientRect().left).toBeCloseTo(
      24,
      3,
    );
    expect(shell.getBoundingClientRect().right - preview.getBoundingClientRect().right).toBeCloseTo(
      24,
      3,
    );
    expect(activation.getBoundingClientRect().top).toBeCloseTo(
      description.getBoundingClientRect().top,
      0,
    );
    expect(activation.getBoundingClientRect().right).toBeLessThan(
      description.getBoundingClientRect().left,
    );
    expect(
      description.getBoundingClientRect().left - activation.getBoundingClientRect().right,
    ).toBeCloseTo(20, 3);
    expect(
      activation.getBoundingClientRect().bottom - action.getBoundingClientRect().bottom,
    ).toBeCloseTo(0, 3);
    expect(action.getBoundingClientRect().left).toBeCloseTo(
      activation.getBoundingClientRect().left,
      3,
    );
    expect(action.getBoundingClientRect().right).toBeCloseTo(
      activation.getBoundingClientRect().right,
      3,
    );
    expect(descriptionContent.getBoundingClientRect().top).toBeCloseTo(
      description.getBoundingClientRect().top,
      3,
    );
    expect(descriptionContent.getBoundingClientRect().left).toBeCloseTo(
      description.getBoundingClientRect().left,
      3,
    );
    expect(activation.getBoundingClientRect().height).toBeLessThan(
      description.getBoundingClientRect().height,
    );
    expect(getComputedStyle(description).overflowY).toBe("auto");
    expect(description.scrollHeight).toBeGreaterThan(description.clientHeight);
  });
});

function renderGame() {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() =>
    mount(GamePage as SvelteComponent<Record<string, unknown>>, {
      target,
      props: {
        slug: "koala-rescue-club",
        canLaunchGame: true,
        game: gameMetadata(),
        attrs: gameAttrs(),
        session: null,
      },
    }),
  );

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}

function requiredElement(selector: string) {
  const element = document.querySelector(selector);

  if (!(element instanceof HTMLElement)) {
    throw new Error(`Expected ${selector}.`);
  }

  return element;
}

function gameAttrs(): Attrs {
  return {
    sheet: {
      id: "attrs_sheet",
      name: "sheet",
      type: "enum",
      value: "dharug",
      required: true,
      values: ["dharug", "yugambeh"],
      errors: [],
    },
  };
}

function gameMetadata(): GameMetadata {
  return {
    name: "Koala Rescue Club",
    alternateNames: [],
    categories: ["Animals"],
    mechanics: ["Dice Rolling"],
    description: "Long game description. ".repeat(120),
    thumbnailUrl: null,
    imageUrl: null,
    yearPublished: 2022,
    minPlayers: 1,
    maxPlayers: 100,
    playingTime: 30,
    minPlayTime: 20,
    maxPlayTime: 30,
    minAge: 6,
    complexity: 1,
    rating: 6.9,
  };
}
