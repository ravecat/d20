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
  it("marks page content as an Inertia scroll region and links developers", () => {
    renderLayout();

    const content = document.body.querySelector("main");
    const developerLink = document.body.querySelector('footer a[href="/developers"]');

    expect(content?.hasAttribute("scroll-region")).toBe(true);
    expect(content?.getAttribute("tabindex")).toBe("-1");
    expect(developerLink?.textContent).toBe("for developers");
    expect(developerLink?.getAttribute("href")).toBe("/developers");
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
