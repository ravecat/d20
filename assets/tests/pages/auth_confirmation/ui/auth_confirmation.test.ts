import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AuthConfirmationPage } from "~/pages/auth_confirmation";
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
  },
};

describe("magic-link confirmation page", () => {
  it("does not offer persistent login during sudo reauthentication", () => {
    render(AuthConfirmationPage, {
      auth,
      email: "player@example.com",
      reauthenticate: true,
      token: "login-token",
    });

    expect(screen.getByRole("heading", { name: "Log in" })).not.toBeNull();
    expect(screen.queryByRole("textbox", { name: "Username" })).toBeNull();
    expect(screen.queryByLabelText("Keep me signed in")).toBeNull();
  });

  it("submits a confirmed user's magic-link token", async () => {
    render(AuthConfirmationPage, {
      auth,
      email: "player@example.com",
      reauthenticate: false,
      token: "login-token",
    });

    await fireEvent.click(screen.getByLabelText("Keep me signed in"));
    await fireEvent.click(screen.getByRole("button", { name: "Log in" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-in",
      method: "post",
      data: { user: { remember_me: "true", token: "login-token" } },
    });
  });
});
