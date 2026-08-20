import { flushSync, mount, unmount } from "svelte";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { page, userEvent } from "vitest/browser";
import { Header } from "~/app/ui";
import { auth } from "~/shared/stores";
import inertiaMock from "../../mocks/inertia";

let cleanup: (() => Promise<void>) | undefined;

beforeEach(async () => {
  auth.trigger.reset();
  await page.viewport(1280, 800);
  inertiaMock.setPage({
    url: "/games/qwinto",
    props: {
      auth: {
        authenticated: false,
        local: false,
        prompt: null,
        providers: {
          apple: { available: false },
          discord: { available: true },
          google: { available: true },
        },
      },
      errors: {},
    },
  });
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("app header account dialog", () => {
  it("opens Login by default, switches modes without navigation, and closes on Escape", async () => {
    renderHeader();

    const login = page
      .getByRole("navigation", { name: "Account" })
      .getByRole("button", { name: "Log in", exact: true });
    await login.click();

    const loginDialog = page.getByRole("dialog", { name: "Log in" });
    const dialogElement = loginDialog.element() as HTMLDialogElement;
    const loginEmail = page.getByLabelText("Email address");
    const loginIdentifier = page.getByLabelText("Username or email");
    const sharedIntroduction = page.getByText(
      "Save your game history and achievements. Share game sessions across devices and watch replays of completed games.",
    );

    await expect.element(loginDialog).toBeVisible();
    await expect.element(sharedIntroduction).toBeVisible();
    expect(page.getByRole("button", { name: "Register", exact: true }).elements()).toHaveLength(0);
    expect((loginEmail.element() as HTMLInputElement).placeholder).toBe("Email address");
    expect((loginIdentifier.element() as HTMLInputElement).placeholder).toBe("Username or email");
    expect(
      (page.getByLabelText("Password", { exact: true }).element() as HTMLInputElement).placeholder,
    ).toBe("Password");
    expect(loginEmail.element().hasAttribute("autofocus")).toBe(true);
    expect(loginIdentifier.element().hasAttribute("autofocus")).toBe(false);
    await expect.poll(() => document.activeElement).toBe(loginEmail.element());

    await loginEmail.fill("player@example.com");
    await page.getByRole("button", { name: "Create account", exact: true }).click();

    const registerDialog = page.getByRole("dialog", { name: "Create your free account" });
    const registrationEmail = page.getByLabelText("Email address");

    await expect.element(registerDialog).toBeVisible();
    expect((registrationEmail.element() as HTMLInputElement).value).toBe("player@example.com");
    await expect.poll(() => document.activeElement).toBe(registrationEmail.element());

    await registerDialog.getByRole("button", { name: "Log in", exact: true }).click();

    await expect.element(loginDialog).toBeVisible();
    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe(
      "player@example.com",
    );
    expect((page.getByLabelText("Username or email").element() as HTMLInputElement).value).toBe(
      "player@example.com",
    );

    await userEvent.keyboard("{Escape}");
    await expect.poll(() => dialogElement.open).toBe(false);

    await login.click();

    await expect.element(page.getByRole("dialog", { name: "Log in" })).toBeVisible();
    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe("");
    await expect.element(page.getByLabelText("Password", { exact: true })).toBeVisible();
  });

  it("routes the explicit close action through the native dialog", async () => {
    renderHeader();
    await openLoginMode();

    const dialog = page.getByRole("dialog", { name: "Log in" });
    const dialogElement = dialog.element() as HTMLDialogElement;

    await page.getByLabelText("Email address").fill("discard@example.com");
    await page.getByRole("button", { name: "Close", exact: true }).click();

    await expect.poll(() => dialogElement.open).toBe(false);
    expect(page.getByRole("dialog").elements()).toHaveLength(0);

    await openLoginMode();

    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe("");
  });

  it("delegates backdrop light dismissal to the native modal dialog", async () => {
    renderHeader();

    const login = page
      .getByRole("navigation", { name: "Account" })
      .getByRole("button", { name: "Log in", exact: true });
    await login.click();

    const dialog = page.getByRole("dialog", { name: "Log in" });
    const dialogElement = dialog.element() as HTMLDialogElement;

    expect(dialogElement.getAttribute("closedby")).toBe("any");
    expect(dialogElement.matches(":modal")).toBe(true);

    await login.click({ force: true });

    await expect.poll(() => dialogElement.open).toBe(false);
  });

  it("submits registration through its Inertia form and renders confirmation", async () => {
    renderHeader();
    await openRegistrationMode();

    await page.getByLabelText("Email address").fill("player@example.com");
    await page.getByRole("button", { name: "Create account", exact: true }).click();

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/register",
      method: "post",
      data: {
        response_to: "/games/qwinto",
        return_to: "/games/qwinto",
        user: { email: "player@example.com" },
      },
    });

    inertiaMock.respondWithSuccess();

    const result = page.getByRole("status").filter({ hasText: "Open the confirmation link" });

    await expect.element(result).toBeVisible();
    await expect.element(result).toHaveTextContent("Check your email");
    await expect
      .element(result)
      .toHaveTextContent("Open the confirmation link to finish creating your account and log in.");
    await expect.element(page.getByLabelText("Information")).toBeVisible();
    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);
    expect(page.getByLabelText("Email address").elements()).toHaveLength(0);
    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
    await expect.element(page.getByRole("link", { name: "Sign up with Google" })).toBeVisible();
    assertProviderHidden("Sign up", "Apple");
    assertProviderHidden("Sign up", "Facebook");
    await expect
      .element(
        page
          .getByRole("dialog", { name: "Create your free account" })
          .getByRole("button", { name: "Log in", exact: true }),
      )
      .toBeVisible();

    await userEvent.keyboard("{Escape}");
    await openRegistrationMode();

    expect(page.getByText("Check your email", { exact: true }).elements()).toHaveLength(0);
    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe("");
  });

  it("keeps registration validation and delivery failures inside registration", async () => {
    renderHeader();
    await openRegistrationMode();

    const email = page.getByLabelText("Email address");
    await email.fill("existing@example.com");
    await page.getByRole("button", { name: "Create account", exact: true }).click();

    inertiaMock.respondWithErrors({
      email: "We could not create an account with this email.",
    });

    await expect
      .element(page.getByRole("alert"))
      .toHaveTextContent("We could not create an account with this email.");
    expect(email.element().getAttribute("aria-invalid")).toBe("true");

    await page.getByRole("button", { name: "Create account", exact: true }).click();

    inertiaMock.respondWithErrors({
      delivery: "Your account was created, but we could not send the confirmation email.",
    });

    await expect
      .element(page.getByRole("alert").filter({ hasText: "could not send" }))
      .toHaveTextContent("Your account was created, but we could not send the confirmation email.");
    await expect.element(page.getByLabelText("Error")).toBeVisible();
    await expect
      .element(page.getByRole("button", { name: "Log in to request another link" }))
      .toBeVisible();
  });

  it("submits a neutral magic-link request without hiding other login methods", async () => {
    renderHeader();
    await openLoginMode();

    const emailInputs = page.getByLabelText("Email address").elements() as HTMLInputElement[];
    await userEvent.fill(emailInputs[0]!, "unknown@example.com");
    await page.getByRole("button", { name: "Email me a login link" }).click();

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-in",
      method: "post",
      data: {
        response_to: "/games/qwinto",
        return_to: "/games/qwinto",
        user: { email: "unknown@example.com" },
      },
    });

    inertiaMock.respondWithSuccess();

    const result = page.getByRole("status").filter({ hasText: "login link will arrive" });

    await expect
      .element(result)
      .toHaveTextContent("If your email is in our system, a login link will arrive shortly.");
    await expect.element(page.getByLabelText("Information")).toBeVisible();
    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);
    await expect.element(page.getByLabelText("Password", { exact: true })).toBeVisible();
    await expect
      .element(
        page
          .getByRole("dialog", { name: "Log in" })
          .getByRole("button", { name: "Log in", exact: true }),
      )
      .toBeVisible();
  });

  it("shows the local mailbox only in successful email notices", async () => {
    inertiaMock.setPage({
      props: {
        auth: {
          authenticated: false,
          local: true,
          prompt: null,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: true },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    const mailbox = page.getByRole("link", { name: "local mailbox" });

    expect(mailbox.elements()).toHaveLength(0);

    await page.getByLabelText("Email address").fill("player@example.com");
    await page.getByRole("button", { name: "Create account", exact: true }).click();
    inertiaMock.respondWithSuccess();

    const registrationResult = page
      .getByRole("status")
      .filter({ hasText: "Open the confirmation link" });

    await expect.element(mailbox).toBeVisible();
    await expect.element(registrationResult).toHaveTextContent("Open the local mailbox.");
    await expect.element(page.getByLabelText("Information")).toBeVisible();
    expect(mailbox.element().getAttribute("href")).toBe("/dev/mailbox");

    await switchToLoginMode();

    expect(mailbox.elements()).toHaveLength(0);

    await page.getByLabelText("Email address").fill("player@example.com");
    await page.getByRole("button", { name: "Email me a login link" }).click();
    inertiaMock.respondWithSuccess();

    const magicLinkResult = page.getByRole("status").filter({ hasText: "login link will arrive" });

    await expect.element(mailbox).toBeVisible();
    await expect.element(magicLinkResult).toHaveTextContent("Open the local mailbox.");
    await expect.element(page.getByLabelText("Information")).toBeVisible();
    expect(mailbox.element().getAttribute("href")).toBe("/dev/mailbox");
  });

  it("hides the local mailbox link when it is unavailable", async () => {
    renderHeader();
    await openRegistrationMode();

    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);

    await switchToLoginMode();

    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);
  });

  it("isolates password errors and sends remember-me only when selected", async () => {
    renderHeader();
    await openLoginMode();

    const identifier = page.getByLabelText("Username or email");
    await identifier.fill("table_master");
    const password = page.getByLabelText("Password", { exact: true });
    await password.fill("not-the-password");
    await page.getByLabelText("Keep me signed in").click();
    await page.getByRole("button", { name: "Show password" }).click();

    expect((password.element() as HTMLInputElement).type).toBe("text");

    await page
      .getByRole("region", { name: "Password login" })
      .getByRole("button", { name: "Log in", exact: true })
      .click();

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-in",
      method: "post",
      data: {
        response_to: "/games/qwinto",
        return_to: "/games/qwinto",
        user: {
          identifier: "table_master",
          password: "not-the-password",
          remember_me: "true",
        },
      },
    });

    inertiaMock.respondWithErrors({
      credentials: "Invalid username, email, or password",
    });

    await expect
      .element(page.getByRole("alert"))
      .toHaveTextContent("Invalid username, email, or password");
    expect(page.getByText("Invalid username, email, or password").elements()).toHaveLength(1);
    expect(identifier.element().getAttribute("aria-invalid")).toBe("true");
    await expect.element(page.getByRole("button", { name: "Email me a login link" })).toBeVisible();
  });

  it("resets local password visibility after leaving Login mode", async () => {
    renderHeader();
    await openLoginMode();

    const password = page.getByLabelText("Password", { exact: true });
    await page.getByRole("button", { name: "Show password" }).click();

    expect((password.element() as HTMLInputElement).type).toBe("text");
    await page.getByRole("button", { name: "Create account", exact: true }).click();
    await switchToLoginMode();

    expect(
      (page.getByLabelText("Password", { exact: true }).element() as HTMLInputElement).type,
    ).toBe("password");
    await expect
      .element(page.getByRole("button", { name: "Show password" }))
      .toHaveAttribute("aria-pressed", "false");
  });

  it("shows Google and Discord links while Apple is unavailable", async () => {
    renderHeader();
    await openRegistrationMode();

    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
    await expect.element(page.getByRole("link", { name: "Sign up with Google" })).toBeVisible();
    await expect.element(page.getByRole("link", { name: "Sign up with Discord" })).toBeVisible();
    assertProviderHidden("Sign up", "Apple");
    assertProviderHidden("Sign up", "Facebook");

    await switchToLoginMode();

    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(2);
    await expect.element(page.getByRole("link", { name: "Sign in with Google" })).toBeVisible();
    await expect.element(page.getByRole("link", { name: "Sign in with Discord" })).toBeVisible();
    assertProviderHidden("Sign in", "Apple");
    assertProviderHidden("Sign in", "Facebook");
  });

  it("shows Apple, Discord, and Google links independently", async () => {
    inertiaMock.setPage({
      url: "/games/qwinto?session=table-1",
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: null,
          providers: {
            apple: { available: true },
            discord: { available: true },
            google: { available: true },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    const registrationAppleLink = page.getByRole("link", { name: "Sign up with Apple" });
    expect(registrationAppleLink.element().getAttribute("href")).toBe(
      "/auth/apple?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1",
    );
    await expect.element(page.getByRole("link", { name: "Sign up with Google" })).toBeVisible();
    expect(
      page.getByRole("link", { name: "Sign up with Discord" }).element().getAttribute("href"),
    ).toBe("/auth/discord?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1");
    assertProviderHidden("Sign up", "Facebook");

    await switchToLoginMode();

    const loginAppleLink = page.getByRole("link", { name: "Sign in with Apple" });
    expect(loginAppleLink.element().getAttribute("href")).toBe(
      "/auth/apple?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1",
    );
    await expect.element(page.getByRole("link", { name: "Sign in with Google" })).toBeVisible();
    expect(
      page.getByRole("link", { name: "Sign in with Discord" }).element().getAttribute("href"),
    ).toBe("/auth/discord?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1");
    assertProviderHidden("Sign in", "Facebook");
  });

  it("hides Google when its credentials are unavailable", async () => {
    inertiaMock.setPage({
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: null,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: false },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    assertProviderHidden("Sign up", "Google");

    await switchToLoginMode();

    assertProviderHidden("Sign in", "Google");
    await expect.element(page.getByRole("link", { name: "Sign in with Discord" })).toBeVisible();
  });

  it("hides Discord when its credentials are unavailable", async () => {
    inertiaMock.setPage({
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: null,
          providers: {
            apple: { available: true },
            discord: { available: false },
            google: { available: true },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    assertProviderHidden("Sign up", "Discord");

    await switchToLoginMode();

    assertProviderHidden("Sign in", "Discord");
    await expect.element(page.getByRole("link", { name: "Sign in with Apple" })).toBeVisible();
    await expect.element(page.getByRole("link", { name: "Sign in with Google" })).toBeVisible();
  });

  it("omits the provider group and its separator when every provider is unavailable", async () => {
    inertiaMock.setPage({
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: null,
          providers: {
            apple: { available: false },
            discord: { available: false },
            google: { available: false },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    expect(page.getByLabelText("Other registration methods").elements()).toHaveLength(0);
    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(0);

    await switchToLoginMode();

    expect(page.getByLabelText("Other login methods").elements()).toHaveLength(0);
    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
  });

  it("preserves the local return path in normal provider links", async () => {
    inertiaMock.setPage({
      url: "/games/qwinto?session=table-1",
      props: {
        auth: {
          authenticated: false,
          local: false,
          prompt: null,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: true },
          },
        },
        errors: {},
      },
    });
    renderHeader();
    await openRegistrationMode();

    const registrationLink = page.getByRole("link", { name: "Sign up with Google" });
    expect(registrationLink.element().getAttribute("href")).toBe(
      "/auth/google?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1",
    );
    expect(
      page.getByRole("link", { name: "Sign up with Discord" }).element().getAttribute("href"),
    ).toBe("/auth/discord?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1");
    assertProviderHidden("Sign up", "Apple");
    assertProviderHidden("Sign up", "Facebook");

    await switchToLoginMode();

    const loginLink = page.getByRole("link", { name: "Sign in with Google" });
    expect(loginLink.element().getAttribute("href")).toBe(
      "/auth/google?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1",
    );
    expect(
      page.getByRole("link", { name: "Sign in with Discord" }).element().getAttribute("href"),
    ).toBe("/auth/discord?return_to=%2Fgames%2Fqwinto%3Fsession%3Dtable-1");
    assertProviderHidden("Sign in", "Apple");
    assertProviderHidden("Sign in", "Facebook");
  });

  it("keeps every login method and registration switch reachable at a narrow viewport", async () => {
    await page.viewport(280, 640);
    renderHeader();
    await openLoginMode();

    const loginDialog = page.getByRole("dialog", { name: "Log in" });
    const modeSwitch = loginDialog.getByRole("button", { name: "Create account", exact: true });

    await expect.element(loginDialog).toBeVisible();
    await expect.element(page.getByRole("heading", { name: "Log in" })).toBeVisible();
    await expect.element(page.getByLabelText("Password", { exact: true })).toBeVisible();
    await expect.element(page.getByRole("link", { name: "Sign in with Google" })).toBeVisible();
    await expect.element(page.getByRole("link", { name: "Sign in with Discord" })).toBeVisible();
    assertProviderHidden("Sign in", "Apple");
    assertProviderHidden("Sign in", "Facebook");
    await expect.element(modeSwitch).toBeVisible();

    await modeSwitch.click();

    const registrationDialog = page.getByRole("dialog", { name: "Create your free account" });

    await expect.element(registrationDialog).toBeVisible();
    await expect
      .element(page.getByRole("heading", { name: "Create your free account" }))
      .toBeVisible();
    await expect.element(page.getByLabelText("Email address")).toBeVisible();
    await expect.element(page.getByRole("button", { name: "Close", exact: true })).toBeVisible();
  });

  it("replaces Log in with Inertia account actions for authenticated users", async () => {
    inertiaMock.setPage({
      props: {
        auth: {
          authenticated: true,
          local: false,
          prompt: null,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: true },
          },
        },
        errors: {},
      },
    });
    renderHeader();

    expect(page.getByRole("button", { name: "Log in", exact: true }).elements()).toHaveLength(0);
    expect(page.getByRole("button", { name: "Register", exact: true }).elements()).toHaveLength(0);
    expect(page.getByRole("link", { name: "Settings" }).element().getAttribute("href")).toBe(
      "/users/settings",
    );

    await page.getByRole("button", { name: "Log out" }).click();

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-out",
      method: "delete",
      data: {},
    });
  });

  it("opens a server-requested login once with its message and return destination", async () => {
    inertiaMock.setPage({
      url: "/games/qwinto",
      props: {
        auth: {
          authenticated: false,
          local: false,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: true },
          },
          prompt: {
            email: "",
            kind: "warning",
            message:
              "That email already has a D20 account. Log in with an existing method, then link Discord in Account Settings.",
            reauthenticate: false,
            returnTo: "/users/settings",
          },
        },
        errors: {},
      },
    });

    renderHeader();

    await expect.element(page.getByRole("dialog", { name: "Log in" })).toBeVisible();
    await expect
      .element(page.getByRole("status").filter({ hasText: "That email already has" }))
      .toHaveTextContent(
        "That email already has a D20 account. Log in with an existing method, then link Discord in Account Settings.",
      );
    await expect.element(page.getByLabelText("Warning")).toBeVisible();

    const submit = page
      .getByRole("button", {
        name: "Email me a login link",
      })
      .element() as HTMLButtonElement;
    const form = submit.form as HTMLFormElement;
    const data = new FormData(form);

    expect(data.get("response_to")).toBe("/games/qwinto");
    expect(data.get("return_to")).toBe("/users/settings");

    await userEvent.keyboard("{Escape}");

    await expect
      .poll(() => page.getByRole("dialog", { name: "Log in" }).elements())
      .toHaveLength(0);
  });

  it("opens sudo reauthentication for an authenticated user with a locked email", async () => {
    inertiaMock.setPage({
      url: "/",
      props: {
        auth: {
          authenticated: true,
          local: false,
          providers: {
            apple: { available: false },
            discord: { available: true },
            google: { available: true },
          },
          prompt: {
            email: "player@example.com",
            kind: "warning",
            message: "You must re-authenticate to access this page.",
            reauthenticate: true,
            returnTo: "/users/settings",
          },
        },
        errors: {},
      },
    });

    renderHeader();

    await expect.element(page.getByRole("dialog", { name: "Confirm it is you" })).toBeVisible();
    await expect
      .element(page.getByRole("status").filter({ hasText: "You must re-authenticate" }))
      .toBeVisible();

    const email = page.getByLabelText("Email address").element() as HTMLInputElement;
    const identifier = page.getByLabelText("Username or email").element() as HTMLInputElement;

    expect(email.value).toBe("player@example.com");
    expect(identifier.value).toBe("player@example.com");
    expect(email.readOnly).toBe(true);
    expect(identifier.readOnly).toBe(true);
    expect(page.getByLabelText("Keep me signed in").elements()).toHaveLength(0);
    expect(page.getByLabelText("Other login methods").elements()).toHaveLength(0);
    expect(page.getByRole("button", { name: "Create account" }).elements()).toHaveLength(0);
  });

  it("opens Login from the overlay header", async () => {
    renderHeader({ overlay: true });

    await openLoginMode();

    await expect.element(page.getByRole("dialog", { name: "Log in" })).toBeVisible();
  });
});

async function openLoginMode() {
  await page
    .getByRole("navigation", { name: "Account" })
    .getByRole("button", { name: "Log in", exact: true })
    .click();
}

async function openRegistrationMode() {
  await openLoginMode();
  await page
    .getByRole("dialog", { name: "Log in" })
    .getByRole("button", { name: "Create account", exact: true })
    .click();
}

async function switchToLoginMode() {
  await page
    .getByRole("dialog", { name: "Create your free account" })
    .getByRole("button", { name: "Log in", exact: true })
    .click();
}

function assertProviderHidden(prefix: "Sign up" | "Sign in", provider: string) {
  expect(page.getByText(`${prefix} with ${provider}`, { exact: true }).elements()).toHaveLength(0);
}

function renderHeader(props: { overlay?: boolean } = {}) {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() => mount(Header, { target, props }));

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}
