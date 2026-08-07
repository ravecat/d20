import { beforeEach, describe, expect, it } from "vitest";
import { auth } from "~/shared/stores";

const prompt: NonNullable<InertiaProps["auth"]["prompt"]> = {
  email: "player@example.com",
  message: "You must log in to access this page.",
  reauthenticate: false,
  returnTo: "/users/settings",
};

beforeEach(() => {
  auth.trigger.reset();
});

describe("auth store", () => {
  it("opens a clean registration dialog", () => {
    auth.trigger.open({ prompt });
    auth.trigger.magicLinkSucceeded();

    auth.trigger.open();

    expect(auth.get().context).toEqual({
      open: true,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
    });
  });

  it("captures a server prompt as a login dialog session", () => {
    auth.trigger.open({ prompt });

    expect(auth.get().context).toEqual({
      open: true,
      mode: "login",
      email: "player@example.com",
      prompt,
      registrationCompleted: false,
      magicLinkCompleted: false,
    });
  });

  it("preserves prompt and email while resetting mode-specific interaction state", () => {
    auth.trigger.open({ prompt });
    auth.trigger.updateEmail({ email: "changed@example.com" });
    auth.trigger.magicLinkSucceeded();

    auth.trigger.switchMode({ mode: "register" });

    expect(auth.get().context).toEqual({
      open: true,
      mode: "register",
      email: "changed@example.com",
      prompt,
      registrationCompleted: false,
      magicLinkCompleted: false,
    });
  });

  it("resets the complete dialog session when closed", () => {
    auth.trigger.open({ prompt });

    auth.trigger.close();

    expect(auth.get().context).toEqual({
      open: false,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
    });
  });
});
