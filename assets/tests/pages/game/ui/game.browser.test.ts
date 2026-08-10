import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { page } from "vitest/browser";
import type { Schema } from "@sjsf/form";
import { GamePage } from "~/pages/game";
import type { GameMetadata } from "~/shared/types";

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  await page.viewport(412, 915);
  document.documentElement.style.setProperty("--color-base-100", "rgb(250 250 250)");
  document.documentElement.style.setProperty("--color-base-300", "rgb(230 230 232)");
  document.documentElement.style.setProperty("--color-base-content", "rgb(20 20 24)");
  document.documentElement.style.setProperty("--color-primary", "rgb(210 90 30)");
  document.documentElement.style.setProperty("--radius-sm", "4px");
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  document.documentElement.style.removeProperty("--color-base-100");
  document.documentElement.style.removeProperty("--color-base-300");
  document.documentElement.style.removeProperty("--color-base-content");
  document.documentElement.style.removeProperty("--color-primary");
  document.documentElement.style.removeProperty("--radius-sm");
});

describe("game detail responsive spacing", () => {
  it("uses compact intrinsic spacing when the detail panels stack", () => {
    renderGame();

    const activation = page.getByRole("complementary", { name: "Game activation" }).element();
    const description = page.getByRole("region", { name: "Description" }).element();
    const descriptionContent = page.getByText(/^Long game description\./).element();
    const defaultSheet = page.getByRole("radio", { name: "dharug" }).element();
    const alternateSheet = page.getByRole("radio", { name: "yugambeh" }).element();
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
    expect(defaultSheet).toBeInstanceOf(HTMLInputElement);
    expect(alternateSheet).toBeInstanceOf(HTMLInputElement);
    expect((defaultSheet as HTMLInputElement).checked).toBe(true);
    expect((alternateSheet as HTMLInputElement).checked).toBe(false);
    expect(getComputedStyle(defaultSheet).accentColor).toBe(
      getComputedStyle(labelFor(defaultSheet)).color,
    );
    expect(action.getBoundingClientRect().height).toBeCloseTo(40, 3);
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

  it("stacks launch choices in equal full-width rows", () => {
    renderGame();

    const defaultChoice = labelFor(page.getByRole("radio", { name: "dharug" }).element());
    const alternateChoice = labelFor(page.getByRole("radio", { name: "yugambeh" }).element());
    const action = page.getByRole("button", { name: "Play" }).element();

    expect(defaultChoice.getBoundingClientRect().width).toBeCloseTo(
      alternateChoice.getBoundingClientRect().width,
      3,
    );
    expect(defaultChoice.getBoundingClientRect().left).toBeCloseTo(
      alternateChoice.getBoundingClientRect().left,
      3,
    );
    expect(defaultChoice.getBoundingClientRect().right).toBeCloseTo(
      alternateChoice.getBoundingClientRect().right,
      3,
    );
    expect(alternateChoice.getBoundingClientRect().top).toBeGreaterThan(
      defaultChoice.getBoundingClientRect().top,
    );
    expect(defaultChoice.getBoundingClientRect().height).toBeCloseTo(
      action.getBoundingClientRect().height,
      3,
    );
    expect(alternateChoice.getBoundingClientRect().height).toBeCloseTo(
      action.getBoundingClientRect().height,
      3,
    );
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
        schema: gameSchema(),
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

function labelFor(element: Element) {
  if (!(element instanceof HTMLInputElement)) {
    throw new Error("Expected an input choice.");
  }

  const label = element.labels?.item(0);

  if (!label) {
    throw new Error("Expected a labelled input choice.");
  }

  return label;
}

function gameSchema(): Schema {
  return {
    type: "object",
    properties: {
      sheet: { type: "string", enum: ["dharug", "yugambeh"] },
    },
    required: ["sheet"],
    default: { sheet: "dharug" },
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
