import { describe, expect, it } from "vitest";
import Layout from "~/app/layout.svelte";
import { usePage } from "~stories/mocks/inertia_svelte";
import accountSettings from "~stories/pages/authenticated/account_settings.stories";
import authenticatedAuthConfirmation from "~stories/pages/authenticated/auth_confirmation.stories";
import authenticatedHome from "~stories/pages/authenticated/home.stories";
import publicAuthConfirmation, {
  Login as confirmation,
} from "~stories/pages/public/auth_confirmation.stories";
import publicHome from "~stories/pages/public/home.stories";
import registrationCompletion, * as registrationCompletionStories from "~stories/pages/public/registration_completion.stories";
import playerCountLabel from "~stories/shared/player_count_label.stories";
import workspace from "~stories/widgets/workspace.stories";

describe("Storybook page layout", () => {
  it("registers matching production layout context on every complete routed page", () => {
    const pages = [
      { authenticated: false, meta: publicHome, url: "/" },
      { authenticated: true, meta: authenticatedHome, url: "/" },
      { authenticated: true, meta: accountSettings, url: "/users/settings" },
      {
        authenticated: false,
        meta: publicAuthConfirmation,
        url: "/users/log-in/storybook-login-token",
      },
      {
        authenticated: true,
        meta: authenticatedAuthConfirmation,
        url: "/users/log-in/storybook-login-token",
      },
      {
        authenticated: false,
        meta: registrationCompletion,
        url: "/users/register/complete",
      },
    ] as const;

    for (const { authenticated, meta, url } of pages) {
      const result = meta.decorators[0](undefined, { args: meta.args });

      expect(result.Component).toBe(Layout);
      expect(usePage().url).toBe(url);
      expect(usePage().props.auth).toEqual(meta.args.auth);
      expect(usePage().props.auth.authenticated).toBe(authenticated);
    }
  });

  it("organizes complete pages by public or authenticated access", () => {
    expect(publicHome.title).toBe("Pages/Public/∕");
    expect(publicHome.id).toBe("home");
    expect(publicAuthConfirmation.title).toBe("Pages/Public/∕users∕log-in∕:token");
    expect(publicAuthConfirmation.id).toBe("pages-sign-in-magic-link-confirmation");
    expect(registrationCompletion.title).toBe("Pages/Public/∕users∕register∕complete");
    expect(registrationCompletion.id).toBe("pages-sign-up-registration-completion");

    expect(authenticatedHome.title).toBe("Pages/Authenticated/∕");
    expect(authenticatedHome.id).toBe("pages-authenticated-home");
    expect(authenticatedAuthConfirmation.title).toBe("Pages/Authenticated/∕users∕log-in∕:token");
    expect(authenticatedAuthConfirmation.id).toBe(
      "pages-authenticated-sign-in-magic-link-confirmation",
    );
    expect(accountSettings.title).toBe("Pages/Authenticated/∕settings");
    expect(accountSettings.id).toBe("pages-settings");
  });

  it("gives the tokenized confirmation route access-specific layout context", () => {
    expect(confirmation.name).toBe("Confirmation");

    publicAuthConfirmation.decorators[0](undefined, { args: publicAuthConfirmation.args });

    expect(usePage().url).toBe("/users/log-in/storybook-login-token");
    expect(usePage().props.auth.authenticated).toBe(false);

    authenticatedAuthConfirmation.decorators[0](undefined, {
      args: authenticatedAuthConfirmation.args,
    });

    expect(usePage().url).toBe("/users/log-in/storybook-login-token");
    expect(usePage().props.auth.authenticated).toBe(true);
  });

  it("keeps Registration Completion focused on distinct workflows", () => {
    expect(Object.keys(registrationCompletionStories).sort()).toEqual([
      "AuthProvider",
      "MagicLink",
      "default",
    ]);
    expect(registrationCompletionStories.AuthProvider.args?.email).toBeNull();
  });

  it("leaves shared and widget stories undecorated", () => {
    expect(playerCountLabel).not.toHaveProperty("decorators");
    expect(workspace).not.toHaveProperty("decorators");
  });
});
