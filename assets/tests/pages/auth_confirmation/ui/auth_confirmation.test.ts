import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AuthConfirmationPage } from "~/pages/auth_confirmation";
import inertiaMock from "../../../mocks/inertia";

const auth = { authenticated: false, local: false, prompt: null };

describe("magic-link confirmation page", () => {
  it("submits username with the existing confirmation token contract", async () => {
    render(AuthConfirmationPage, {
      auth,
      confirmed: false,
      email: "player@example.com",
      reauthenticate: false,
      token: "confirmation-token",
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

  it("does not offer persistent login during sudo reauthentication", () => {
    render(AuthConfirmationPage, {
      auth,
      confirmed: true,
      email: "player@example.com",
      reauthenticate: true,
      token: "login-token",
    });

    expect(screen.getByRole("heading", { name: "Log in" })).not.toBeNull();
    expect(screen.queryByRole("textbox", { name: "Username" })).toBeNull();
    expect(screen.queryByLabelText("Keep me signed in")).toBeNull();
  });
});
