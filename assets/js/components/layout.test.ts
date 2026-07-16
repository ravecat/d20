import { flushSync, mount, unmount } from "svelte";
import { afterEach, describe, expect, it } from "vitest";
import Layout from "~components/layout.svelte";

let cleanup: (() => Promise<void>) | undefined;

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("Layout", () => {
  it("keeps page content in an Inertia scroll region between the header and footer", () => {
    renderLayout();

    const layout = document.body.querySelector(".layout");
    const content = layout?.querySelector("main");
    const developerLink = layout?.querySelector('footer a[href="/developers"]');

    if (!(layout instanceof HTMLElement)) {
      throw new Error("Expected the app shell to render.");
    }

    expect([...layout.children].map((element) => element.tagName)).toEqual([
      "HEADER",
      "MAIN",
      "FOOTER",
    ]);
    expect(content?.hasAttribute("scroll-region")).toBe(true);
    expect(content?.getAttribute("tabindex")).toBe("-1");
    expect(developerLink?.textContent).toBe("for developers");
    expect(developerLink?.getAttribute("href")).toBe("/developers");
  });

  it("compacts the brand while the page content is scrolled", () => {
    renderLayout();

    const content = document.body.querySelector("main");
    const header = document.body.querySelector("header");

    if (!(content instanceof HTMLElement) || !(header instanceof HTMLElement)) {
      throw new Error("Expected the app shell to render its header and main content.");
    }

    content.scrollTop = 25;
    content.dispatchEvent(new Event("scroll"));
    flushSync();

    expect(header.classList).toContain("header--compact");

    content.scrollTop = 0;
    content.dispatchEvent(new Event("scroll"));
    flushSync();

    expect(header.classList).not.toContain("header--compact");
  });
});

function renderLayout() {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() => mount(Layout, { target }));

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}
