import { render, screen } from "@testing-library/svelte";
import { describe, expect, it } from "vitest";
import { AboutPage } from "~/pages/about";

describe("About D20", () => {
  it("links players and collaborators to the existing public destinations", () => {
    render(AboutPage);

    expect(document.title).toBe("About D20");
    expect(screen.getAllByRole("heading", { level: 1 })).toHaveLength(1);
    expect(screen.getByRole("heading", { name: "About D20" })).toBeTruthy();
    for (const [name, href] of [
      ["Share your ideas", "/contact"],
      ["Talk about your game", "/rights-holders"],
      ["Join the project", "/contact"],
      ["For developers", "/developers"],
    ]) {
      expect(screen.getByRole("link", { name }).getAttribute("href")).toBe(href);
    }
    expect(screen.getAllByRole("link").some((link) => link.getAttribute("href") === "/games")).toBe(
      false,
    );
  });
});
