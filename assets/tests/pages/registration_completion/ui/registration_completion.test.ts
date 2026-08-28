import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { RegistrationCompletionPage } from "~/pages/registration_completion";
import inertiaMock from "../../../mocks/inertia";

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

describe("registration completion page", () => {
  it("completes Magic Link registration with its confirmation token", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: "player@example.com",
      submission: {
        action: "/users/log-in",
        credential: { type: "magic_link", token: "confirmation-token" },
      },
    });

    expect(screen.getByRole("heading", { name: "Finish creating your account" })).not.toBeNull();
    expect(screen.getByText("player@example.com")).not.toBeNull();

    const username = screen.getByRole("textbox", { name: "Username" });
    expect(username.getAttribute("autocomplete")).toBe("username");
    expect(username.getAttribute("minlength")).toBe("3");
    expect(username.getAttribute("maxlength")).toBe("32");

    await fireEvent.input(username, { target: { value: "  Table_Master  " } });
    expect((username as HTMLInputElement).value).toBe("table_master");
    await fireEvent.click(screen.getByLabelText("Keep me signed in"));
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-in",
      method: "post",
      data: {
        _action: "confirmed",
        user: {
          remember_me: "true",
          token: "confirmation-token",
          username: "table_master",
        },
      },
    });
  });

  it("completes OAuth registration without exposing provider identity fields", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: "player@example.com",
      submission: { action: "/auth/google/register", credential: { type: "server_session" } },
      cancelAction: "/auth/google/register/cancel",
    });

    const username = screen.getByRole("textbox", { name: "Username" });
    await fireEvent.input(username, { target: { value: "oauth_player" } });
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/google/register",
      method: "post",
      data: { user: { username: "oauth_player" } },
    });
    expect(document.querySelectorAll('input[type="hidden"]')).toHaveLength(0);
  });

  it("completes provider-only registration without exposing or requiring email", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: null,
      submission: { action: "/auth/google/register", credential: { type: "server_session" } },
      cancelAction: "/auth/google/register/cancel",
    });

    expect(
      screen.queryByText("You can add and verify an email later from account settings."),
    ).toBeNull();
    expect(screen.queryByText("player@example.com")).toBeNull();

    await fireEvent.input(screen.getByRole("textbox", { name: "Username" }), {
      target: { value: "provider_only" },
    });
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/google/register",
      method: "post",
      data: { user: { username: "provider_only" } },
    });
  });

  it("uses the same server-session completion contract for Discord", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: "player@example.com",
      submission: { action: "/auth/discord/register", credential: { type: "server_session" } },
      cancelAction: "/auth/discord/register/cancel",
    });

    await fireEvent.input(screen.getByRole("textbox", { name: "Username" }), {
      target: { value: "discord_player" },
    });
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/discord/register",
      method: "post",
      data: { user: { username: "discord_player" } },
    });
    expect(document.querySelectorAll('input[type="hidden"]')).toHaveLength(0);
  });

  it("uses username-only Facebook completion with a server-owned email candidate", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: "facebook-candidate@example.com",
      submission: { action: "/auth/facebook/register", credential: { type: "server_session" } },
      cancelAction: "/auth/facebook/register/cancel",
    });

    expect(screen.getByText("facebook-candidate@example.com")).not.toBeNull();
    expect(screen.queryByRole("textbox", { name: "Email address" })).toBeNull();

    await fireEvent.input(screen.getByRole("textbox", { name: "Username" }), {
      target: { value: "facebook_player" },
    });
    await fireEvent.click(screen.getByLabelText("Keep me signed in"));
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/facebook/register",
      method: "post",
      data: {
        user: {
          remember_me: "true",
          username: "facebook_player",
        },
      },
    });
    expect(document.querySelectorAll('input[type="hidden"]')).toHaveLength(0);
  });

  it("completes provider-only Facebook registration without requesting email", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: null,
      submission: { action: "/auth/facebook/register", credential: { type: "server_session" } },
      cancelAction: "/auth/facebook/register/cancel",
    });

    expect(screen.queryByRole("textbox", { name: "Email address" })).toBeNull();

    await fireEvent.input(screen.getByRole("textbox", { name: "Username" }), {
      target: { value: "facebook_provider_only" },
    });
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/facebook/register",
      method: "post",
      data: { user: { username: "facebook_provider_only" } },
    });
  });

  it("reports username errors and offers a provider-neutral alternate action", async () => {
    render(RegistrationCompletionPage, {
      auth,
      email: "player@example.com",
      submission: { action: "/auth/google/register", credential: { type: "server_session" } },
      cancelAction: "/auth/google/register/cancel",
    });

    const username = screen.getByRole("textbox", { name: "Username" });
    await fireEvent.input(username, { target: { value: "taken_player" } });
    await fireEvent.click(screen.getByRole("button", { name: "Finish registration" }));
    inertiaMock.respondWithErrors({ username: "has already been taken" });

    expect((await screen.findByRole("alert")).textContent).toContain("has already been taken");

    await fireEvent.click(
      screen.getByRole("button", { name: "Choose another registration method" }),
    );

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/auth/google/register/cancel",
      method: "post",
      data: {},
    });
  });
});
