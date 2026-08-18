import { fireEvent, render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AccountSettingsPage } from "~/pages/account_settings";
import inertiaMock from "../../../mocks/inertia";

const auth = {
  authenticated: false,
  local: false,
  prompt: null,
  providers: {
    apple: { available: false },
    discord: { available: true },
    google: { available: true },
  },
};
const discordUnlinked = { available: true, linked: false };
const googleUnlinked = { available: true, linked: false };
const appleUnlinked = { available: true, linked: false };

describe("account settings page", () => {
  it("submits email and password changes as independent Inertia forms", async () => {
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
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

  it("displays the account username without an edit action", () => {
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.getByText("table_master")).not.toBeNull();
    expect(screen.getByText("Your username identifies you to other D20 players.")).not.toBeNull();
    expect(screen.queryByRole("textbox", { name: "Username" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Save username" })).toBeNull();
  });

  it("switches between the Google Link action and Linked text without secondary status copy", () => {
    const { unmount } = render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.getByRole("heading", { name: "Sign-in methods" })).not.toBeNull();
    expect(screen.getByText("Google")).not.toBeNull();
    expect(screen.queryByText("Not linked")).toBeNull();
    expect(screen.getByRole("link", { name: "Link Google" })).not.toBeNull();

    unmount();
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: { available: true, linked: true },
      username: "table_master",
    });

    expect(screen.getByText("Linked")).not.toBeNull();
    expect(screen.queryByText("Not linked")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
  });

  it("offers a normal Google linking anchor when unlinked", () => {
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Google" });
    expect(link.getAttribute("href")).toBe("/users/settings/auth/google");
  });

  it("omits Google while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: { available: false, linked: true },
      username: "table_master",
    });

    expect(screen.queryByText("Google")).toBeNull();
    expect(screen.queryByText("Unavailable")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
  });

  it("reports Apple linking states and uses a normal full-document anchor", () => {
    const { unmount } = render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Apple" });
    expect(link.getAttribute("href")).toBe("/users/settings/auth/apple");

    unmount();
    render(AccountSettingsPage, {
      apple: { available: true, linked: true },
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Apple" })).toBeNull();
  });

  it("reports Discord linking states and uses a normal full-document anchor", () => {
    const { unmount } = render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: discordUnlinked,
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Discord" });
    expect(link.getAttribute("href")).toBe("/users/settings/auth/discord");

    unmount();
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: { available: true, linked: true },
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Discord" })).toBeNull();
  });

  it("omits Discord while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      apple: appleUnlinked,
      auth,
      discord: { available: false, linked: true },
      email: "player@example.com",
      google: googleUnlinked,
      username: "table_master",
    });

    expect(screen.queryByText("Discord")).toBeNull();
    expect(screen.queryByText("Unavailable")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Discord" })).toBeNull();
  });

  it("omits Sign-in methods when every provider is unavailable", () => {
    render(AccountSettingsPage, {
      apple: { available: false, linked: false },
      auth,
      discord: { available: false, linked: true },
      email: "player@example.com",
      google: { available: false, linked: false },
      username: "table_master",
    });

    expect(screen.queryByRole("heading", { name: "Sign-in methods" })).toBeNull();
    expect(screen.getByRole("heading", { name: "Username" })).not.toBeNull();
    expect(screen.getByRole("heading", { name: "Email address" })).not.toBeNull();
    expect(screen.getByRole("heading", { name: "Password" })).not.toBeNull();
  });
});
