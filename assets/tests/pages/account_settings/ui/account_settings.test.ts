import { fireEvent, render, screen } from "@testing-library/svelte";
import type { ComponentProps } from "svelte";
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
    facebook: { available: false },
    google: { available: true },
    steam: { available: false },
  },
};

const providers = [
  {
    available: true,
    href: "/profile/auth/google",
    id: "google",
    linked: false,
    name: "Google",
  },
  {
    available: true,
    href: "/profile/auth/apple",
    id: "apple",
    linked: false,
    name: "Apple",
  },
  {
    available: true,
    href: "/profile/auth/discord",
    id: "discord",
    linked: false,
    name: "Discord",
  },
  {
    available: true,
    href: "/profile/auth/facebook",
    id: "facebook",
    linked: false,
    name: "Facebook",
  },
  {
    available: true,
    href: "/profile/auth/steam",
    id: "steam",
    linked: false,
    name: "Steam",
  },
] satisfies ComponentProps<typeof AccountSettingsPage>["providers"];

describe("account settings page", () => {
  it("submits email and password changes as independent Inertia forms", async () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    const email = screen.getByRole("textbox", { name: "New email address" });
    const password = screen.getByPlaceholderText("New password");
    const confirmation = screen.getByPlaceholderText("Confirm new password");

    expect((email as HTMLInputElement).value).toBe("player@example.com");
    expect(email.getAttribute("autocomplete")).toBe("email");
    expect(password.getAttribute("autocomplete")).toBe("new-password");
    expect(confirmation.getAttribute("autocomplete")).toBe("new-password");

    await fireEvent.input(email, { target: { value: "next@example.com" } });
    await fireEvent.click(screen.getByRole("button", { name: "Change email" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/profile",
      method: "put",
      data: { action: "update_email", user: { email: "next@example.com" } },
    });

    await fireEvent.input(password, { target: { value: "new valid password" } });
    await fireEvent.input(confirmation, { target: { value: "new valid password" } });
    await fireEvent.click(screen.getByRole("button", { name: "Save password" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/profile",
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

  it("offers first-email verification to a provider-only account", async () => {
    render(AccountSettingsPage, {
      auth,
      email: null,
      providers: providers.map((provider) =>
        provider.id === "google" ? { ...provider, linked: true } : provider,
      ),
      username: "provider_only",
    });

    expect(
      screen.getByText(
        "Add and verify an email to enable magic-link recovery and email notifications.",
      ),
    ).not.toBeNull();
    expect(
      screen.getByText("Add a password for username sign-in while email recovery is unavailable."),
    ).not.toBeNull();
    expect(screen.getByRole("link", { name: "Link Facebook" }).getAttribute("href")).toBe(
      "/profile/auth/facebook",
    );

    const email = screen.getByRole("textbox", { name: "Email address" });
    expect((email as HTMLInputElement).value).toBe("");
    expect(email.getAttribute("autocomplete")).toBe("email");

    await fireEvent.input(email, { target: { value: "provider@example.com" } });
    await fireEvent.click(screen.getByRole("button", { name: "Add email" }));

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/profile",
      method: "put",
      data: { action: "update_email", user: { email: "provider@example.com" } },
    });
  });

  it("displays the account username without an edit action", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    expect(screen.getByText("table_master")).not.toBeNull();
    expect(screen.getByText("Your username identifies you to other D20 players.")).not.toBeNull();
    expect(screen.queryByRole("textbox", { name: "Username" })).toBeNull();
    expect(screen.queryByRole("button", { name: "Save username" })).toBeNull();
  });

  it("switches between the Google Link action and Linked text without secondary status copy", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    expect(screen.getByRole("heading", { name: "Sign-in methods" })).not.toBeNull();
    expect(screen.getByText("Google")).not.toBeNull();
    expect(screen.queryByText("Not linked")).toBeNull();
    expect(screen.getByRole("link", { name: "Link Google" })).not.toBeNull();

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "google" ? { ...provider, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.getByText("Linked")).not.toBeNull();
    expect(screen.queryByText("Not linked")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
  });

  it("reports Facebook linking states and uses the server-provided full-document URL", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Facebook" });
    expect(link.getAttribute("href")).toBe("/profile/auth/facebook");

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "facebook" ? { ...provider, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Facebook" })).toBeNull();
  });

  it("uses the server-provided Google linking URL", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "google" ? { ...provider, href: "/server-provided/google-link" } : provider,
      ),
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Google" });
    expect(link.getAttribute("href")).toBe("/server-provided/google-link");
  });

  it("omits Google while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "google" ? { ...provider, available: false, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByText("Google")).toBeNull();
    expect(screen.queryByText("Unavailable")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Google" })).toBeNull();
  });

  it("reports Apple linking states and uses a normal full-document anchor", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Apple" });
    expect(link.getAttribute("href")).toBe("/profile/auth/apple");

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "apple" ? { ...provider, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Apple" })).toBeNull();
  });

  it("reports Discord linking states and uses a normal full-document anchor", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Discord" });
    expect(link.getAttribute("href")).toBe("/profile/auth/discord");

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "discord" ? { ...provider, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Discord" })).toBeNull();
  });

  it("omits Discord while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "discord" ? { ...provider, available: false, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByText("Discord")).toBeNull();
    expect(screen.queryByText("Unavailable")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Discord" })).toBeNull();
  });

  it("reports Steam linking states and uses a normal full-document anchor", () => {
    const { unmount } = render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers,
      username: "table_master",
    });

    const link = screen.getByRole("link", { name: "Link Steam" });
    expect(link.getAttribute("href")).toBe("/profile/auth/steam");

    unmount();
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "steam" ? { ...provider, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByRole("link", { name: "Link Steam" })).toBeNull();
  });

  it("omits Steam while the provider is unavailable", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) =>
        provider.id === "steam" ? { ...provider, available: false, linked: true } : provider,
      ),
      username: "table_master",
    });

    expect(screen.queryByText("Steam")).toBeNull();
    expect(screen.queryByText("Unavailable")).toBeNull();
    expect(screen.queryByRole("link", { name: "Link Steam" })).toBeNull();
  });

  it("omits Sign-in methods when every provider is unavailable", () => {
    render(AccountSettingsPage, {
      auth,
      email: "player@example.com",
      providers: providers.map((provider) => ({
        ...provider,
        available: false,
        linked: provider.id === "discord",
      })),
      username: "table_master",
    });

    expect(screen.queryByRole("heading", { name: "Sign-in methods" })).toBeNull();
    expect(screen.getByRole("heading", { name: "Username" })).not.toBeNull();
    expect(screen.getByRole("heading", { name: "Email address" })).not.toBeNull();
    expect(screen.getByRole("heading", { name: "Password" })).not.toBeNull();
  });
});
