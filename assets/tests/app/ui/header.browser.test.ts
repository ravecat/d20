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
      auth: { authenticated: false, local: false, prompt: null },
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
  it("switches modes without navigation, preserves email, and closes on Escape", async () => {
    renderHeader();

    const register = page.getByRole("button", { name: "Register", exact: true });
    await register.click();

    const registerDialog = page.getByRole("dialog", { name: "Create your free account" });
    const dialogElement = registerDialog.element() as HTMLDialogElement;
    const registrationEmail = page.getByLabelText("Email address");

    await expect.element(registerDialog).toBeVisible();
    expect((registrationEmail.element() as HTMLInputElement).placeholder).toBe("Email address");
    expect(registrationEmail.element().hasAttribute("autofocus")).toBe(true);
    await expect.poll(() => document.activeElement).toBe(registrationEmail.element());

    await registrationEmail.fill("player@example.com");
    await page.getByRole("button", { name: "Log in", exact: true }).click();

    const loginDialog = page.getByRole("dialog", { name: "Log in" });
    const loginEmails = page.getByLabelText("Email address").elements() as HTMLInputElement[];

    await expect.element(loginDialog).toBeVisible();
    expect(loginEmails).toHaveLength(2);
    expect(page.getByRole("heading", { name: "Magic Link" }).elements()).toHaveLength(0);
    expect(page.getByRole("heading", { name: "Email and password" }).elements()).toHaveLength(0);
    expect(loginEmails.every((input) => input.placeholder === "Email address")).toBe(true);
    expect(
      (page.getByLabelText("Password", { exact: true }).element() as HTMLInputElement).placeholder,
    ).toBe("Password");
    expect(loginEmails[0]?.value).toBe("player@example.com");
    expect(loginEmails[1]?.value).toBe("player@example.com");
    expect(loginEmails[0]?.hasAttribute("autofocus")).toBe(true);
    expect(loginEmails[1]?.hasAttribute("autofocus")).toBe(false);
    await expect.poll(() => document.activeElement).toBe(loginEmails[0]);
    expect(
      page.getByRole("button", { name: "Create account", exact: true }).elements(),
    ).toHaveLength(1);

    await page.getByRole("button", { name: "Create account", exact: true }).click();

    const switchedRegistrationEmail = page.getByLabelText("Email address");

    await expect
      .element(page.getByRole("dialog", { name: "Create your free account" }))
      .toBeVisible();
    expect((switchedRegistrationEmail.element() as HTMLInputElement).value).toBe(
      "player@example.com",
    );
    await expect.poll(() => document.activeElement).toBe(switchedRegistrationEmail.element());

    await userEvent.keyboard("{Escape}");
    await expect.poll(() => dialogElement.open).toBe(false);

    await register.click();

    const reopenedEmail = page.getByLabelText("Email address");

    await expect
      .element(page.getByRole("dialog", { name: "Create your free account" }))
      .toBeVisible();
    expect((reopenedEmail.element() as HTMLInputElement).value).toBe("");
    expect(page.getByLabelText("Password", { exact: true }).elements()).toHaveLength(0);
  });

  it("routes the explicit close action through the native dialog", async () => {
    renderHeader();

    const register = page.getByRole("button", { name: "Register", exact: true });
    await register.click();

    const dialog = page.getByRole("dialog", { name: "Create your free account" });
    const dialogElement = dialog.element() as HTMLDialogElement;

    await page.getByLabelText("Email address").fill("discard@example.com");
    await page.getByRole("button", { name: "Close", exact: true }).click();

    await expect.poll(() => dialogElement.open).toBe(false);
    expect(page.getByRole("dialog").elements()).toHaveLength(0);

    await register.click();

    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe("");
  });

  it("delegates backdrop light dismissal to the native modal dialog", async () => {
    renderHeader();

    const register = page.getByRole("button", { name: "Register", exact: true });
    await register.click();

    const dialog = page.getByRole("dialog", { name: "Create your free account" });
    const dialogElement = dialog.element() as HTMLDialogElement;

    expect(dialogElement.getAttribute("closedby")).toBe("any");
    expect(dialogElement.matches(":modal")).toBe(true);

    await register.click({ force: true });

    await expect.poll(() => dialogElement.open).toBe(false);
  });

  it("submits registration through its Inertia form and renders confirmation", async () => {
    renderHeader();
    const register = page.getByRole("button", { name: "Register", exact: true });
    await register.click();

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

    await expect.element(page.getByText("Check your email", { exact: true })).toBeVisible();
    await expect
      .element(
        page.getByText("Open the confirmation link to finish creating your account and log in."),
      )
      .toBeVisible();
    expect(page.getByLabelText("Email address").elements()).toHaveLength(0);
    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
    assertProvidersDisabled("Register");
    await expect.element(page.getByRole("button", { name: "Log in", exact: true })).toBeVisible();

    await userEvent.keyboard("{Escape}");
    await register.click();

    expect(page.getByText("Check your email", { exact: true }).elements()).toHaveLength(0);
    expect((page.getByLabelText("Email address").element() as HTMLInputElement).value).toBe("");
  });

  it("keeps registration validation and delivery failures inside registration", async () => {
    renderHeader();
    await page.getByRole("button", { name: "Register" }).click();

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
      .element(
        page.getByText("Your account was created, but we could not send the confirmation email."),
      )
      .toBeVisible();
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

    await expect
      .element(page.getByText("If your email is in our system, a login link will arrive shortly."))
      .toBeVisible();
    await expect.element(page.getByLabelText("Password", { exact: true })).toBeVisible();
    await expect.element(page.getByRole("button", { name: "Log in", exact: true })).toBeVisible();
  });

  it("shows the local mailbox link when the server marks it available", async () => {
    inertiaMock.setPage({
      props: {
        auth: { authenticated: false, local: true, prompt: null },
        errors: {},
      },
    });
    renderHeader();
    await page.getByRole("button", { name: "Register", exact: true }).click();

    const mailbox = page.getByRole("link", { name: "local mailbox" });

    await expect.element(mailbox).toBeVisible();
    expect(mailbox.element().getAttribute("href")).toBe("/dev/mailbox");

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    await expect.element(mailbox).toBeVisible();
  });

  it("hides the local mailbox link when it is unavailable", async () => {
    renderHeader();
    await page.getByRole("button", { name: "Register", exact: true }).click();

    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    expect(page.getByRole("link", { name: "local mailbox" }).elements()).toHaveLength(0);
  });

  it("isolates password errors and sends remember-me only when selected", async () => {
    renderHeader();
    await openLoginMode();

    const emailInputs = page.getByLabelText("Email address").elements() as HTMLInputElement[];
    await userEvent.fill(emailInputs[1]!, "player@example.com");
    const password = page.getByLabelText("Password", { exact: true });
    await password.fill("not-the-password");
    await page.getByLabelText("Keep me signed in").click();
    await page.getByRole("button", { name: "Show password" }).click();

    expect((password.element() as HTMLInputElement).type).toBe("text");

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    expect(inertiaMock.formSubmit).toHaveBeenLastCalledWith({
      action: "/users/log-in",
      method: "post",
      data: {
        response_to: "/games/qwinto",
        return_to: "/games/qwinto",
        user: {
          email: "player@example.com",
          password: "not-the-password",
          remember_me: "true",
        },
      },
    });

    inertiaMock.respondWithErrors({
      credentials: "Invalid email or password",
    });

    await expect.element(page.getByRole("alert")).toHaveTextContent("Invalid email or password");
    expect(page.getByText("Invalid email or password").elements()).toHaveLength(1);
    await expect.element(page.getByRole("button", { name: "Email me a login link" })).toBeVisible();
  });

  it("resets local password visibility after leaving Login mode", async () => {
    renderHeader();
    await openLoginMode();

    const password = page.getByLabelText("Password", { exact: true });
    await page.getByRole("button", { name: "Show password" }).click();

    expect((password.element() as HTMLInputElement).type).toBe("text");
    await page.getByRole("button", { name: "Create account", exact: true }).click();
    await page.getByRole("button", { name: "Log in", exact: true }).click();

    expect(
      (page.getByLabelText("Password", { exact: true }).element() as HTMLInputElement).type,
    ).toBe("password");
    await expect
      .element(page.getByRole("button", { name: "Show password" }))
      .toHaveAttribute("aria-pressed", "false");
  });

  it("shows mode-specific provider choices without allowing provider actions", async () => {
    renderHeader();
    await page.getByRole("button", { name: "Register" }).click();

    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
    assertProvidersDisabled("Register");

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(2);
    assertProvidersDisabled("Log in");
  });

  it("keeps every login method reachable at a narrow viewport", async () => {
    await page.viewport(280, 640);
    renderHeader();
    await page.getByRole("button", { name: "Register", exact: true }).click();

    const registrationDialog = page.getByRole("dialog", { name: "Create your free account" });
    const registrationHeading = page.getByRole("heading", { name: "Create your free account" });

    await expect.element(registrationDialog).toBeVisible();
    await expect.element(registrationHeading).toBeVisible();
    await expect.element(page.getByLabelText("Email address")).toBeVisible();
    await expect.element(page.getByRole("button", { name: "Close", exact: true })).toBeVisible();

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    const dialog = page.getByRole("dialog", { name: "Log in" });
    const modeSwitch = page.getByRole("button", { name: "Create account", exact: true });

    await expect.element(dialog).toBeVisible();
    await expect.element(page.getByRole("heading", { name: "Log in" })).toBeVisible();
    await expect.element(page.getByLabelText("Password", { exact: true })).toBeVisible();
    assertProvidersDisabled("Log in");
    await expect.element(modeSwitch).toBeVisible();

    await modeSwitch.click();
    await expect.element(registrationDialog).toBeVisible();
  });

  it("replaces Register with Inertia account actions for authenticated users", async () => {
    inertiaMock.setPage({
      props: {
        auth: { authenticated: true, local: false, prompt: null },
        errors: {},
      },
    });
    renderHeader();

    expect(page.getByRole("button", { name: "Register" }).elements()).toHaveLength(0);
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
          prompt: {
            email: "",
            message: "You must log in to access this page.",
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
      .element(page.getByRole("status").filter({ hasText: "You must log in" }))
      .toBeVisible();

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
          prompt: {
            email: "player@example.com",
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

    const emails = page.getByLabelText("Email address").elements() as HTMLInputElement[];

    expect(emails).toHaveLength(2);
    expect(emails.every((input) => input.value === "player@example.com")).toBe(true);
    expect(emails.every((input) => input.readOnly)).toBe(true);
    expect(page.getByLabelText("Keep me signed in").elements()).toHaveLength(0);
    expect(page.getByLabelText("Other login methods").elements()).toHaveLength(0);
    expect(page.getByRole("button", { name: "Create account" }).elements()).toHaveLength(0);
  });

  it("opens registration from the overlay header", async () => {
    renderHeader({ overlay: true });

    await page.getByRole("button", { name: "Register" }).click();

    await expect
      .element(page.getByRole("dialog", { name: "Create your free account" }))
      .toBeVisible();
  });
});

async function openLoginMode() {
  await page.getByRole("button", { name: "Register" }).click();
  await page.getByRole("button", { name: "Log in", exact: true }).click();
}

function assertProvidersDisabled(prefix: "Register" | "Log in") {
  for (const provider of ["Google", "Facebook", "Apple", "Discord"]) {
    const button = page.getByRole("button", {
      name: `${prefix} with ${provider} Coming soon`,
    });

    expect((button.element() as HTMLButtonElement).disabled).toBe(true);
  }
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
