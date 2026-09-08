import { beforeEach, describe, expect, it, vi } from "vitest";
import { page, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import { auth } from "~/shared/stores";
import Footer from "~/app/ui/footer.svelte";
import inertiaMock from "../../mocks/inertia";
import "../../../css/app.css";

beforeEach(async () => {
  inertiaMock.reset();
  auth.trigger.reset();
  await page.viewport(1280, 720);
});

describe("shared footer", () => {
  it("omits guest entry actions for signed-in players", async () => {
    inertiaMock.setPage({
      props: {
        auth: { ...inertiaMock.page.props.auth, authenticated: true },
        errors: {},
      },
    });
    await render(Footer);
    const footer = page.getByRole("contentinfo");
    expect(footer.getByRole("button", { includeHidden: true }).elements()).toHaveLength(0);
    await expect.element(footer).not.toHaveTextContent("Have an account?");
    expect(footer.getByRole("link").elements()).toHaveLength(7);
  });

  it.each([320, 446, 220])("keeps all navigation readable at %i CSS pixels", async (width) => {
    await page.viewport(width, 900);
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    try {
      await render(Footer);
      await Promise.all(Array.from(document.fonts, (font) => font.load()));
      await expect(page.getByRole("contentinfo")).toMatchScreenshot(`footer-${width}.png`);
    } finally {
      vi.useRealTimers();
    }
  });

  it.each([320, 768, 769, 1280])(
    "exposes every destination once without disclosures at %i CSS pixels",
    async (width) => {
      await page.viewport(width, 900);
      await render(Footer);

      const footer = page.getByRole("contentinfo");
      await expect.element(footer).toHaveTextContent(`d20 © ${new Date().getFullYear()}`);
      for (const [name, href] of [
        ["Terms", "/terms"],
        ["About", "/about"],
        ["For publishers and rightholders", "/rights-holders"],
        ["For developers", "/developers"],
        ["How to play", "/help"],
        ["FAQ", "/help#faq"],
        ["Contact / support", "/contact"],
      ]) {
        const link = footer.getByRole("link", { name, exact: true, includeHidden: true });
        expect(link.elements()).toHaveLength(1);
        await expect.element(link).toBeVisible();
        await expect.element(link).toHaveAttribute("href", href);
      }
      expect(footer.getByRole("link", { includeHidden: true }).elements()).toHaveLength(7);
      expect(footer.getByRole("group", { includeHidden: true }).elements()).toHaveLength(0);
      expect(footer.getByRole("list", { includeHidden: true }).elements()).toHaveLength(0);
      for (const name of ["Explore", "Help"]) {
        await expect
          .element(footer.getByRole("navigation", { name }).getByRole("heading", { name }))
          .toBeVisible();
      }
    },
  );

  it("keeps the same link focused across breakpoint and orientation changes", async () => {
    await page.viewport(390, 844);
    await render(Footer);
    const faq = page.getByRole("link", { name: "FAQ", exact: true }).element();
    faq.focus();

    for (const [width, height] of [
      [768, 1024],
      [769, 1024],
      [844, 390],
      [390, 844],
    ]) {
      await page.viewport(width, height);
      await expect.element(faq).toHaveFocus();
      await expect.element(faq).toBeVisible();
      expect(page.getByRole("link").elements()).toHaveLength(7);
    }
  });

  it.each(["narrow", "wide"] as const)(
    "tabs through all links in reading order without requests in the %s shell",
    async (variant) => {
      await page.viewport(320, 900);
      const visit = vi.spyOn(inertiaMock.router, "visit");
      const fetch = vi.spyOn(window, "fetch");
      try {
        await render(Footer, { variant });
        page.getByRole("button", { name: "Sign up", exact: true }).element().focus();
        await userEvent.tab();
        await expect
          .element(page.getByRole("button", { name: "Sign in", exact: true }))
          .toHaveFocus();
        for (const name of [
          "Terms",
          "About",
          "For publishers and rightholders",
          "For developers",
          "How to play",
          "FAQ",
          "Contact / support",
        ]) {
          await userEvent.tab();
          await expect.element(page.getByRole("link", { name, exact: true })).toHaveFocus();
        }
        expect(visit).not.toHaveBeenCalled();
        expect(fetch).not.toHaveBeenCalled();
      } finally {
        visit.mockRestore();
        fetch.mockRestore();
      }
    },
  );
});
