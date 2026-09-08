import { beforeEach, describe, expect, it, vi } from "vitest";
import { page, userEvent } from "vitest/browser";
import { render } from "vitest-browser-svelte";
import Footer from "~/app/ui/footer.svelte";
import inertiaMock from "../../mocks/inertia";
import "../../../css/app.css";

beforeEach(async () => {
  await page.viewport(1280, 720);
});

describe("shared footer", () => {
  it.each([320, 446, 220])("keeps the legal strip readable at %i CSS pixels", async (width) => {
    await page.viewport(width, 900);
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
    try {
      await render(Footer);
      await Promise.all(Array.from(document.fonts, (font) => font.load()));
      const footer = page.getByRole("contentinfo");
      await expect.element(footer.getByRole("link", { name: "Privacy" })).toBeVisible();
      await expect.element(footer.getByRole("link", { name: "Terms" })).toBeVisible();
      await expect(footer).toMatchScreenshot(`legal-row-${width}.png`);
    } finally {
      vi.useRealTimers();
    }
  });

  it("exposes the exact grouped links on desktop without disclosure controls", async () => {
    await render(Footer);

    const footer = page.getByRole("contentinfo");
    await expect.element(footer).not.toHaveTextContent("Board games in your browser.");
    expect(footer.getByRole("link", { name: "D20", exact: true }).elements()).toHaveLength(0);
    await expect.element(footer).toHaveTextContent(`© ${new Date().getFullYear()} D20`);
    for (const [name, href] of [
      ["About", "/about"],
      ["For publishers and rightholders", "/rights-holders"],
      ["For developers", "/developers"],
      ["How to play", "/help"],
      ["FAQ", "/help#faq"],
      ["Contact / support", "/contact"],
      ["Privacy", "/privacy"],
      ["Terms", "/terms"],
    ]) {
      const link = footer.getByRole("link", { name, exact: true });
      await expect.element(link).toBeVisible();
      await expect.element(link).toHaveAttribute("href", href);
      expect(link.elements()).toHaveLength(1);
    }
    expect(footer.getByRole("link").elements()).toHaveLength(8);
    expect(footer.getByRole("group").elements()).toHaveLength(0);
    await expect.element(footer.getByRole("heading", { name: "Explore" })).toBeVisible();
    await expect.element(footer.getByRole("heading", { name: "Help" })).toBeVisible();
  });

  it.each([320, 390, 767, 768])(
    "starts closed at %i CSS pixels and toggles groups independently",
    async (width) => {
      await page.viewport(width, 900);
      await render(Footer);

      const explore = page.getByRole("group", { name: "Explore" });
      const help = page.getByRole("group", { name: "Help" });
      await expect
        .element(page.getByRole("group", { name: "Explore" }))
        .not.toHaveAttribute("open");
      await expect.element(page.getByRole("group", { name: "Help" })).not.toHaveAttribute("open");
      expect(page.getByRole("link", { name: "FAQ" }).elements()).toHaveLength(0);
      await expect.element(page.getByRole("link", { name: "Privacy" })).toBeVisible();
      await expect.element(page.getByRole("link", { name: "Terms" })).toBeVisible();

      await explore.getByRole("heading", { name: "Explore" }).click();
      await help.getByRole("heading", { name: "Help" }).click();
      await expect.element(page.getByRole("group", { name: "Explore" })).toHaveAttribute("open");
      await expect.element(page.getByRole("group", { name: "Help" })).toHaveAttribute("open");
      await expect.element(page.getByRole("link", { name: "FAQ" })).toBeVisible();
      await expect.element(page.getByRole("link", { name: "About", exact: true })).toBeVisible();
      await expect
        .element(page.getByRole("link", { name: "For publishers and rightholders" }))
        .toHaveAttribute("href", "/rights-holders");

      await explore.getByRole("heading", { name: "Explore" }).click();
      expect(page.getByRole("link", { name: "About", exact: true }).elements()).toHaveLength(0);
      await expect.element(page.getByRole("link", { name: "FAQ" })).toBeVisible();
    },
  );

  it("retains native disclosure state across the 768/769 boundary", async () => {
    await page.viewport(390, 844);
    await render(Footer);
    await page.getByRole("group", { name: "Help" }).getByRole("heading", { name: "Help" }).click();
    await page.viewport(768, 1024);
    await expect.element(page.getByRole("group", { name: "Help" })).toHaveAttribute("open");
    await page.viewport(769, 1024);
    expect(page.getByRole("group").elements()).toHaveLength(0);
    expect(page.getByRole("link").elements()).toHaveLength(8);
    await expect.element(page.getByRole("link", { name: "About", exact: true })).toBeVisible();
    await page.viewport(768, 1024);
    await expect.element(page.getByRole("group", { name: "Help" })).toHaveAttribute("open");
    await expect.element(page.getByRole("group", { name: "Explore" })).not.toHaveAttribute("open");
    expect(page.getByRole("link").elements()).toHaveLength(5);
    expect(page.getByRole("link", { name: "FAQ" }).elements()).toHaveLength(1);
  });

  it("uses native keyboard activation and skips collapsed links without requests", async () => {
    await page.viewport(320, 900);
    const visit = vi.spyOn(inertiaMock.router, "visit");
    const fetch = vi.spyOn(window, "fetch");
    await render(Footer);
    const explore = page.getByRole("group", { name: "Explore" });
    explore.element().querySelector("summary")!.focus();
    await userEvent.keyboard("{Enter}");
    await expect.element(page.getByRole("group", { name: "Explore" })).toHaveAttribute("open");
    await userEvent.keyboard(" ");
    await expect.element(page.getByRole("group", { name: "Explore" })).not.toHaveAttribute("open");
    await userEvent.tab();
    await expect
      .element(page.getByRole("group", { name: "Help" }).element().querySelector("summary")!)
      .toHaveFocus();
    await userEvent.tab();
    await expect.element(page.getByRole("link", { name: "Privacy" })).toHaveFocus();
    expect(visit).not.toHaveBeenCalled();
    expect(fetch).not.toHaveBeenCalled();
    visit.mockRestore();
    fetch.mockRestore();
  });
});

describe("shell width alignment", () => {
  it.each(["narrow", "wide"] as const)(
    "keeps the same grouped content in the %s shell on mobile",
    async (variant) => {
      await page.viewport(320, 900);
      await render(Footer, { variant });
      expect(page.getByRole("group").elements()).toHaveLength(2);
      expect(page.getByRole("link").elements()).toHaveLength(2);
      for (const name of ["Privacy", "Terms"]) {
        await expect.element(page.getByRole("link", { name })).toBeVisible();
      }
      await page
        .getByRole("group", { name: "Explore" })
        .getByRole("heading", { name: "Explore" })
        .click();
      await page
        .getByRole("group", { name: "Help" })
        .getByRole("heading", { name: "Help" })
        .click();
      expect(page.getByRole("link").elements()).toHaveLength(8);
      await expect.element(page.getByRole("link", { name: "For developers" })).toBeVisible();
    },
  );
});
