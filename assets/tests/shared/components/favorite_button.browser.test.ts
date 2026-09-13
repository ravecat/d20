import { flushSync } from "svelte";
import { afterEach, beforeEach, expect, it } from "vitest";
import { page, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import { HomePage } from "~/pages/home";
import { threePlayableGames } from "~stories/fixtures/home";
import inertiaMock from "../../mocks/inertia";

const auth = {
  ...(inertiaMock.page.props.auth as InertiaProps["auth"]),
  authenticated: true,
};

beforeEach(() => {
  inertiaMock.setPage({ props: { ...inertiaMock.page.props, auth } });
});

afterEach(() => inertiaMock.reset());

it("keeps processing local, retains keyboard focus, and renders confirmed props on all copies", async () => {
  const entry = threePlayableGames[0];
  const view = await render(HomePage, {
    auth,
    playableGames: [entry],
    games: [entry],
  });
  const playable = page.getByRole("region", { name: "Playable" });
  const games = page.getByRole("region", { name: "Hot (by BGG)" });
  const icon = playable.getByRole("button", {
    name: "Add Koala Rescue Club to favorites",
  });
  await playable.getByRole("heading", { name: "Playable" }).click();
  await userEvent.tab();
  await userEvent.tab();
  await expect.element(icon).toHaveFocus();
  await userEvent.keyboard("{Enter}");
  await expect.element(icon).toHaveAttribute("aria-disabled", "true");
  await expect.element(icon).toHaveFocus();
  await expect.element(icon).toHaveAttribute("aria-busy", "true");
  await expect.element(games.getByRole("button")).toHaveAttribute("aria-busy", "false");
  await expect.element(games.getByRole("button")).toHaveAttribute("aria-disabled", "false");
  await expect.element(icon).toHaveAttribute("aria-pressed", "false");
  await userEvent.keyboard(" ");
  expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
  expect(inertiaMock.formSubmit).toHaveBeenCalledWith(
    expect.objectContaining({
      method: "put",
      action: entry.favorite.action,
      data: { slug: entry.favorite.slug, response_to: inertiaMock.page.url },
      options: expect.objectContaining({
        only: ["favorites", "auth", "errors"],
        preserveState: true,
        preserveScroll: true,
      }),
    }),
  );
  inertiaMock.setPage({
    props: { ...inertiaMock.page.props, favorites: [entry.id] },
  });
  await view.rerender({ favorites: [entry.id] });
  inertiaMock.respondWithSuccess();
  flushSync();
  const saved = playable.getByRole("button", {
    name: "Remove Koala Rescue Club from favorites",
  });
  await expect.element(saved).toHaveAttribute("aria-pressed", "true");
  await expect.element(saved).toHaveFocus();
  await expect.element(games.getByRole("button")).toHaveAttribute("aria-pressed", "true");
  expect(page.getByRole("status").elements()).toHaveLength(0);
  expect(page.getByRole("alert").elements()).toHaveLength(0);
  await expect.element(saved).not.toHaveAttribute("aria-describedby");
  await userEvent.keyboard("{Enter}");
  expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith(
    expect.objectContaining({
      method: "delete",
      action: entry.favorite.action,
      data: { response_to: inertiaMock.page.url },
    }),
  );
});

it("keeps confirmed membership after a lost response and retries through the same form", async () => {
  const entry = {
    ...threePlayableGames[0],
    game: { ...threePlayableGames[0].game, name: null },
  };
  const view = await render(HomePage, {
    auth,
    playableGames: [entry],
    games: [],
  });
  const button = page.getByRole("button", {
    name: "Add to favorites",
    exact: true,
  });
  await button.click();
  inertiaMock.respondWithNetworkError();
  expect(page.getByRole("alert").elements()).toHaveLength(0);
  expect(page.getByRole("status").elements()).toHaveLength(0);
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
  await expect.element(button).toHaveAttribute("aria-disabled", "false");
  await expect.element(button).toHaveAttribute("aria-busy", "false");
  await expect.element(button).not.toHaveAttribute("aria-describedby");
  await button.click();
  expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(2);
  expect(inertiaMock.formSubmit.mock.calls[1]).toEqual(inertiaMock.formSubmit.mock.calls[0]);
  inertiaMock.setPage({
    props: { ...inertiaMock.page.props, favorites: [entry.id] },
  });
  await view.rerender({ favorites: [entry.id] });
  inertiaMock.respondWithSuccess();
  await expect
    .element(page.getByRole("button", { name: "Remove from favorites", exact: true }))
    .toHaveAttribute("aria-pressed", "true");
  expect(page.getByRole("alert").elements()).toHaveLength(0);
});

it("keeps confirmed membership after identity errors without a notification", async () => {
  await render(HomePage, {
    auth,
    playableGames: [threePlayableGames[0]],
    games: [],
  });
  const button = page.getByRole("button", {
    name: "Add Koala Rescue Club to favorites",
  });
  await button.click();
  inertiaMock.respondWithErrors({
    favorite: "This game has changed. Refresh the page and try again.",
  });
  expect(page.getByRole("alert").elements()).toHaveLength(0);
  expect(page.getByRole("status").elements()).toHaveLength(0);
  await expect.element(button).not.toHaveAttribute("aria-describedby");
  await expect.element(button).toHaveAttribute("aria-disabled", "false");
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
});

it("has no tooltip on hover or focus and preserves keyboard activation", async () => {
  await render(HomePage, {
    auth,
    playableGames: [threePlayableGames[0]],
    games: [],
  });
  const playable = page.getByRole("region", { name: "Playable" });
  const heading = page.getByRole("heading", { name: "Playable" });
  const button = page.getByRole("button", {
    name: "Add Koala Rescue Club to favorites",
  });
  const tooltip = page.getByText("Add to favorites", { exact: true });

  await heading.hover();
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
  await expect.element(tooltip).not.toBeInTheDocument();
  expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  await expect(playable).toMatchScreenshot("favorite-rest.png");

  await button.hover();
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
  await expect.element(tooltip).not.toBeInTheDocument();
  expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  await expect(playable).toMatchScreenshot("favorite-hovered.png");

  await heading.hover();
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
  await expect.element(tooltip).not.toBeInTheDocument();
  expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  await expect(playable).toMatchScreenshot("favorite-pointer-left.png");

  await heading.click();
  await userEvent.tab();
  await userEvent.tab();
  await expect.element(button).toHaveFocus();
  await expect.element(button).toHaveAttribute("aria-pressed", "false");
  await expect.element(tooltip).not.toBeInTheDocument();
  expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  await expect(playable).toMatchScreenshot("favorite-keyboard-focused.png");
  await userEvent.keyboard("{Enter}");
  expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(1);
});
