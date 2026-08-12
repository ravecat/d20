import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AccountSettingsPage } from "~/pages/account_settings";
import inertiaMock from "../../../mocks/inertia";

const auth = {
  authenticated: false,
  local: false,
  prompt: null,
  providers: { google: { available: true } },
};
const googleUnlinked = { available: true, linked: false };

describe("account settings page", () => {
  it("submits email and password changes as independent Inertia forms", async () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

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

  it("lets an existing account claim a username once", async () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: googleUnlinked,
      username: null,
    });

    const username = screen.getByRole("textbox", { name: "Username" });
    expect(username.getAttribute("autocomplete")).toBe("username");
    expect(username.getAttribute("minlength")).toBe("3");
    expect(username.getAttribute("maxlength")).toBe("32");

    await fireEvent.input(username, { target: { value: "  Table_Master  " } });
    expect((username as HTMLInputElement).value).toBe("table_master");
    await fireEvent.click(screen.getByRole("button", { name: "Save username" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/settings",
      method: "put",
      data: { action: "claim_username", user: { username: "table_master" } },
    });

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.getByText("table_master")).not.toBeNull();
    expect(screen.queryByRole("button", { name: "Save username" })).toBeNull();
  });

  it("reports unlinked and linked Google states", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.getByRole("heading", { name: "Sign-in methods" })).not.toBeNull();
    expect(screen.getByText("Not linked")).not.toBeNull();
    expect(screen.getByRole("link", { name: "Link Google" })).not.toBeNull();

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: { available: true, linked: true },
      username: "table_master",
    });

    expect(screen.getByText("Linked")).not.toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
  });

  it("offers a normal Google linking anchor when unlinked", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Google" });
    expect(link.getAttribute("href")).toBe("/users/settings/auth/google");
  });

  it("disables Google linking while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      google: { available: false, linked: false },
      username: "table_master",
    });

    expect(screen.getByText("Unavailable")).not.toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
    expect(
      (screen.getByRole("button", { name: "Link Google" }) as HTMLButtonElement).disabled,
    ).toBe(true);
  });
});
