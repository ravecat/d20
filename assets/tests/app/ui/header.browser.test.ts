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

  document.documentElement.style.setProperty("--color-base-100", "rgb(250 250 250)");
  document.documentElement.style.setProperty("--color-base-200", "rgb(245 245 245)");
  document.documentElement.style.setProperty("--color-base-content", "rgb(20 20 24)");
  document.documentElement.style.setProperty("--color-primary", "rgb(210 90 30)");
  document.documentElement.style.setProperty("--color-primary-content", "rgb(255 255 255)");
  document.documentElement.style.setProperty("--color-success", "rgb(20 130 90)");
  document.documentElement.style.setProperty("--color-error", "rgb(190 30 45)");
  document.documentElement.style.setProperty("--radius-field", "4px");
  document.documentElement.style.setProperty("--radius-box", "8px");
  document.documentElement.style.setProperty("--border", "1px");
});

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
  document.documentElement.removeAttribute("style");
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
    expect(
      getComputedStyle(page.getByText("Email address", { exact: true }).element()).clipPath,
    ).toBe("inset(50%)");
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

  it("uses one dialog inset and content-driven desktop sizes", async () => {
    await page.viewport(1280, 1000);
    renderHeader();
    await page.getByRole("button", { name: "Register" }).click();

    const dialog = page.getByRole("dialog", { name: "Create your free account" });
    const dialogElement = dialog.element() as HTMLDialogElement;
    const heading = page.getByRole("heading", { name: "Create your free account" });
    const description = page.getByText("Save your game history and achievements.", {
      exact: false,
    });
    const registrationEmail = page.getByLabelText("Email address");
    const registrationBounds = dialogElement.getBoundingClientRect();
    const registrationContent = dialogElement.querySelector<HTMLElement>(".auth-panel__content")!;
    const panel = heading.element().closest("section") as HTMLElement;
    const dialogStyle = getComputedStyle(dialogElement);
    const contentInlineStart =
      registrationBounds.left +
      Number.parseFloat(dialogStyle.borderLeftWidth) +
      Number.parseFloat(dialogStyle.paddingLeft);
    const contentInlineEnd =
      registrationBounds.right -
      Number.parseFloat(dialogStyle.borderRightWidth) -
      Number.parseFloat(dialogStyle.paddingRight);
    const registrationEmailBounds = registrationEmail.element().getBoundingClientRect();

    expect(registrationContent.scrollHeight).toBeLessThanOrEqual(registrationContent.clientHeight);
    expect(dialogStyle.paddingLeft).toBe("24px");
    expect(dialogStyle.backgroundColor).toBe("rgb(250, 250, 250)");
    expect(getComputedStyle(panel).paddingLeft).toBe("0px");
    expect(heading.element().getBoundingClientRect().left).toBeCloseTo(contentInlineStart, 0);
    expect(description.element().getBoundingClientRect().left).toBeCloseTo(contentInlineStart, 0);
    expect(registrationEmailBounds.left).toBeCloseTo(contentInlineStart, 0);
    expect(registrationEmailBounds.right).toBeCloseTo(contentInlineEnd, 0);
    expect(getComputedStyle(registrationEmail.element()).outlineOffset).toBe("-3px");
    expect(panel.style.blockSize).toBe("");
    await dialog.click({ position: { x: 8, y: 8 } });
    expect(dialogElement.open).toBe(true);

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    const loginContent = dialogElement.querySelector<HTMLElement>(".auth-panel__content")!;

    await expect
      .poll(() => loginContent.scrollHeight - loginContent.clientHeight)
      .toBeLessThanOrEqual(0);

    const loginBounds = dialogElement.getBoundingClientRect();

    expect(loginBounds.width).toBeCloseTo(registrationBounds.width, 0);
    expect(loginBounds.height).toBeGreaterThan(registrationBounds.height);
    expect(panel.style.blockSize).toBe("");

    await page.getByRole("button", { name: "Create account", exact: true }).click();

    await expect
      .poll(() => dialogElement.getBoundingClientRect().height)
      .toBeCloseTo(registrationBounds.height, 0);
    await page.getByLabelText("Email address").fill("player@example.com");
    await page.getByRole("button", { name: "Create account", exact: true }).click();
    inertiaMock.respondWithSuccess();

    const result = page.getByRole("status").filter({ hasText: "Check your email" });

    await expect.element(result).toBeVisible();

    const successBounds = dialogElement.getBoundingClientRect();

    expect(successBounds.width).toBeCloseTo(registrationBounds.width, 0);
    expect(Math.abs(successBounds.height - registrationBounds.height)).toBeLessThanOrEqual(48);
    expect(result.element().getBoundingClientRect().left).toBeCloseTo(contentInlineStart, 0);
    expect(page.getByText("or", { exact: true }).elements()).toHaveLength(1);
    assertProvidersDisabled("Register");
    expect(panel.style.blockSize).toBe("");
  });

  it("keeps an inset mobile surface and every login method reachable", async () => {
    await page.viewport(280, 640);
    renderHeader();
    await page.getByRole("button", { name: "Register", exact: true }).click();

    const registrationDialog = page.getByRole("dialog", { name: "Create your free account" });
    const registrationBounds = registrationDialog.element().getBoundingClientRect();
    const registrationStyle = getComputedStyle(registrationDialog.element());
    const headingBounds = page
      .getByRole("heading", { name: "Create your free account" })
      .element()
      .getBoundingClientRect();
    const closeBounds = page
      .getByRole("button", { name: "Close", exact: true })
      .element()
      .getBoundingClientRect();

    expect(registrationBounds.left).toBeCloseTo(8, 0);
    expect(registrationBounds.top).toBeCloseTo(8, 0);
    expect(registrationBounds.right).toBeCloseTo(window.innerWidth - 8, 0);
    expect(registrationBounds.bottom).toBeCloseTo(window.innerHeight - 8, 0);
    expect(registrationStyle.borderLeftWidth).toBe("1px");
    expect(registrationStyle.borderRadius).toBe("8px");
    expect(registrationStyle.boxShadow).not.toBe("none");
    expect(registrationStyle.paddingTop).toBe("16px");
    expect(registrationStyle.paddingRight).toBe("16px");
    expect(registrationStyle.paddingBottom).toBe("16px");
    expect(registrationStyle.paddingLeft).toBe("16px");
    expect(headingBounds.height).toBeGreaterThan(closeBounds.height);
    expect(closeBounds.top).toBeCloseTo(headingBounds.top, 0);

    await page.getByRole("button", { name: "Log in", exact: true }).click();

    const dialog = page.getByRole("dialog", { name: "Log in" });
    const bounds = dialog.element().getBoundingClientRect();
    const modeSwitch = page.getByRole("button", { name: "Create account", exact: true });

    expect(bounds.left).toBeCloseTo(8, 0);
    expect(bounds.top).toBeCloseTo(8, 0);
    expect(bounds.right).toBeCloseTo(window.innerWidth - 8, 0);
    expect(bounds.bottom).toBeCloseTo(window.innerHeight - 8, 0);
    expect(
      getComputedStyle(dialog.element().querySelector(".auth-panel__content")!).overflowY,
    ).toBe("auto");
    const content = dialog.element().querySelector<HTMLElement>(".auth-panel__content")!;
    expect(content.scrollHeight).toBeGreaterThan(content.clientHeight);
    modeSwitch.element().scrollIntoView({ block: "nearest" });
    await expect.element(modeSwitch).toBeVisible();
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

  it("keeps Register interactive in the overlay header", () => {
    renderHeader({ overlay: true });

    expect(
      getComputedStyle(page.getByRole("button", { name: "Register" }).element()).pointerEvents,
    ).toBe("auto");
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
