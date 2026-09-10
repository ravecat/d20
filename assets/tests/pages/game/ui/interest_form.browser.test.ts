import { beforeEach, describe, expect, it } from "vitest";
import { page, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import InterestForm from "~/pages/game/ui/interest_form.svelte";
import { auth } from "~/shared/stores/auth";
import inertiaMock from "../../../mocks/inertia";
import "../../../../css/app.css";

const interest = { action: "/games/00900001/interest", requested: false, count: 12 };

beforeEach(async () => {
  inertiaMock.reset();
  auth.trigger.reset();
  inertiaMock.setPage({ url: "/games/00900001" });
  await page.viewport(320, 720);
});

function signIn() {
  inertiaMock.setPage({
    props: {
      ...inertiaMock.page.props,
      auth: { ...inertiaMock.page.props.auth, authenticated: true },
    },
  });
}

describe("interest form", () => {
  it.each([0, 1, 1234])("shows %i requests with an accessible description", async (count) => {
    await render(InterestForm, { interest: { ...interest, count } });
    const button = page.getByRole("button", { name: "I want this game!", exact: true });
    await expect
      .element(button)
      .toHaveAccessibleDescription(
        `${count} ${count === 1 ? "player has" : "players have"} requested this game.`,
      );
    await expect.element(button.getByText(String(count), { exact: true })).toBeVisible();
  });

  it("opens login for guests and never replays on cancellation or sign-in", async () => {
    await render(InterestForm, { interest });
    const button = page.getByRole("button", { name: "I want this game!", exact: true });
    expect(page.getByRole("button").elements()).toHaveLength(1);
    expect(document.querySelectorAll("input, select, textarea")).toHaveLength(0);
    await button.click();
    expect(auth.getSnapshot().context.open).toBe(true);
    expect(auth.getSnapshot().context.prompt?.returnTo).toBe("/games/00900001");
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
    await expect.element(button).toBeEnabled();
    auth.trigger.close();
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
    signIn();
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
    await button.click();
    expect(inertiaMock.formSubmit).toHaveBeenCalledOnce();
  });

  it("submits by keyboard, disables pending requests, and trusts persisted membership", async () => {
    signIn();
    const view = await render(InterestForm, { interest });
    await userEvent.tab();
    await expect.element(page.getByRole("button", { name: "I want this game!" })).toHaveFocus();
    await userEvent.keyboard("{Enter}");
    await expect.element(page.getByRole("button", { name: "Saving..." })).toBeDisabled();
    await expect
      .element(page.getByRole("button"))
      .toHaveAccessibleDescription("12 players have requested this game.");
    expect(inertiaMock.formSubmit).toHaveBeenCalledWith({
      action: interest.action,
      method: "post",
      data: {},
      errorBag: "interest",
    });
    await userEvent.keyboard("{Enter}");
    expect(inertiaMock.formSubmit).toHaveBeenCalledOnce();
    inertiaMock.respondWithSuccess();
    await expect.element(page.getByRole("button", { name: "I want this game!" })).toBeEnabled();
    await view.rerender({ interest: { ...interest, requested: true, count: 13 } });
    await expect
      .element(page.getByRole("button", { name: "Requested", exact: true }))
      .toBeDisabled();
    await expect.element(page.getByRole("status")).not.toBeInTheDocument();
    await expect.element(page.getByText("Request saved.")).not.toBeInTheDocument();
    await expect
      .element(page.getByRole("button"))
      .toHaveAccessibleDescription("13 players have requested this game.");
  });

  it("shows saved membership on a fresh render", async () => {
    signIn();
    await render(InterestForm, { interest: { ...interest, requested: true, count: 13 } });
    await expect
      .element(page.getByRole("button", { name: "Requested", exact: true }))
      .toBeDisabled();
    await expect.element(page.getByRole("alert")).not.toBeInTheDocument();
    await expect.element(page.getByText("Request saved.")).not.toBeInTheDocument();
    expect(inertiaMock.formSubmit).not.toHaveBeenCalled();
  });

  it("shows server validation feedback and permits an explicit retry", async () => {
    signIn();
    await render(InterestForm, { interest });
    await page.getByRole("button").click();
    inertiaMock.respondWithErrors({ message: "The request could not be recorded." });
    await expect
      .element(page.getByRole("alert"))
      .toHaveTextContent("The request could not be recorded.");
    await page.getByRole("button", { name: "I want this game!" }).click();
    expect(inertiaMock.formSubmit).toHaveBeenCalledTimes(2);
    await expect.element(page.getByRole("button", { name: "Saving..." })).toBeDisabled();
    expect(page.getByRole("alert").elements()).toHaveLength(0);
  });
});
