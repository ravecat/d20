import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AccountSettingsPage } from "~/pages/account_settings";
import inertiaMock from "../../../mocks/inertia";

const auth = { authenticated: false, local: false, prompt: null };

describe("account settings page", () => {
  it("submits email and password changes as independent Inertia forms", async () => {
    render(AccountSettingsPage, { auth, email: "player@example.com" });

    const email = screen.getByRole("textbox", { name: "Email address" });
    const password = screen.getByPlaceholderText("New password");
    const confirmation = screen.getByPlaceholderText("Confirm new password");

    expect((email as HTMLInputElement).value).toBe("player@example.com");
    expect(email.getAttribute("autocomplete")).toBe("username");
    expect(password.getAttribute("autocomplete")).toBe("new-password");
    expect(confirmation.getAttribute("autocomplete")).toBe("new-password");

    await fireEvent.input(email, { target: { value: "next@example.com" } });
    await fireEvent.click(screen.getByRole("button", { name: "Change email" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/settings",
      method: "put",
      data: { action: "update_email", user: { email: "next@example.com" } },
    });

    await fireEvent.input(password, { target: { value: "new valid password" } });
    await fireEvent.input(confirmation, { target: { value: "new valid password" } });
    await fireEvent.click(screen.getByRole("button", { name: "Save password" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/settings",
      method: "put",
      data: {
        action: "update_password",
        user: {
          password: "new valid password",
          password_confirmation: "new valid password",
        },
      },
    });
  });
});
