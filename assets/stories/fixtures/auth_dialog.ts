import { auth } from "~/shared/stores/auth";
import { resetStoryPage, setStoryPage } from "../mocks/inertia_svelte";

type AuthPrompt = NonNullable<InertiaProps["auth"]["prompt"]>;

type AuthDialogState = {
  mode: "login" | "register";
  outcome?: "magic_link_sent" | "registration_email_sent";
  prompt?: AuthPrompt;
};

export function prepareAuthDialog({ mode, outcome, prompt }: AuthDialogState) {
  setStoryPage({
    url: "/",
    props: {
      auth: {
        authenticated: prompt?.reauthenticate ?? false,
        local: true,
        prompt: prompt ?? null,
        providers: {
          apple: { available: true },
          discord: { available: true },
          facebook: { available: true },
          google: { available: true },
        },
      },
      errors: {},
    },
  });

  auth.trigger.reset();

  if (prompt) {
    auth.trigger.open({ prompt });
  } else {
    auth.trigger.open();
    auth.trigger.switchMode({ mode });
  }

  if (outcome === "magic_link_sent") auth.trigger.magicLinkSucceeded();
  if (outcome === "registration_email_sent") auth.trigger.registrationSucceeded();

  return () => {
    auth.trigger.reset();
    resetStoryPage();
  };
}
