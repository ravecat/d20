import { describe, expect, it } from "vitest";
import Layout from "~/app/layout.svelte";
import { usePage } from "../../stories/mocks/inertia_svelte";
import accountSettings from "../../stories/pages/account_settings.stories";
import authConfirmation, {
  Login as confirmation,
  Reauthentication,
} from "../../stories/pages/auth_confirmation.stories";
import home from "../../stories/pages/home.stories";
import registrationCompletion from "../../stories/pages/registration_completion.stories";
import playerCountLabel from "../../stories/shared/player_count_label.stories";
import workspace from "../../stories/widgets/workspace.stories";

describe("Storybook page layout", () => {
  it("registers the production layout on every complete routed page", () => {
    const pages = [
      { meta: home, url: "/" },
      { meta: accountSettings, url: "/users/settings" },
      { meta: authConfirmation, url: "/users/log-in/storybook-login-token" },
      { meta: registrationCompletion, url: "/users/register/complete" },
    ] as const;

    for (const { meta, url } of pages) {
      const result = meta.decorators[0](undefined, { args: meta.args });

      expect(result.Component).toBe(Layout);
      expect(usePage().url).toBe(url);
      expect(usePage().props.auth).toEqual(meta.args.auth);
    }
  });

  it("uses route metadata for Registration Completion without changing its story ID", () => {
    expect(registrationCompletion.title).toBe("Pages/∕users∕register∕complete");
    expect(registrationCompletion.id).toBe("pages-sign-up-registration-completion");
  });

  it("gives the tokenized confirmation route scenario-specific layout context", () => {
    const decorate = authConfirmation.decorators[0];

    expect(authConfirmation.id).toBe("pages-sign-in-magic-link-confirmation");
    expect(authConfirmation.title).toBe("Pages/∕users∕log-in∕:token");
    expect(confirmation.name).toBe("Confirmation");

    decorate(undefined, { args: authConfirmation.args });

    expect(usePage().url).toBe("/users/log-in/storybook-login-token");
    expect(usePage().props.auth.authenticated).toBe(false);

    decorate(undefined, {
      args: { ...authConfirmation.args, ...Reauthentication.args },
    });

    expect(usePage().url).toBe("/users/log-in/storybook-login-token");
    expect(usePage().props.auth.authenticated).toBe(true);
  });

  it("leaves shared and widget stories undecorated", () => {
    expect(playerCountLabel).not.toHaveProperty("decorators");
    expect(workspace).not.toHaveProperty("decorators");
  });
});
