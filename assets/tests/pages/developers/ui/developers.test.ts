import { flushSync, mount, type Component as SvelteComponent, unmount } from "svelte";
import { afterEach, describe, expect, it } from "vitest";
import { DevelopersPage } from "~/pages/developers";

let cleanup: (() => Promise<void>) | undefined;

afterEach(async () => {
  await cleanup?.();
  cleanup = undefined;
  document.body.innerHTML = "";
});

describe("developers page", () => {
  it("introduces client implementation and links every public game specification", () => {
    render(DevelopersPage, {});

    const list = document.querySelector('ul[aria-label="Game specifications"]');
    const entries = [...(list?.querySelectorAll("li") ?? [])];

    expect(document.querySelector("h1")?.textContent).toBe("For developers");
    expect(document.title).toBe("For developers");
    expect(document.body.textContent).toContain("Build a compatible game client");
    expect(document.querySelector("h2")).toBeNull();
    expect(entries).toHaveLength(3);
    expect(entries[0]?.textContent).toContain("Qwinto");
    expect(entries[1]?.textContent).toContain("Koala Rescue Club");
    expect(entries[2]?.textContent).toContain("Next Station London");

    expect(list?.querySelector('a[href="/developers/specs/qwinto"]')?.textContent).toBe(
      "Open reference",
    );
    expect(list?.querySelector('a[href="/developers/specs/qwinto/raw"]')?.textContent).toBe("YAML");
    expect(list?.querySelector('a[href="/developers/specs/koala-rescue-club"]')?.textContent).toBe(
      "Open reference",
    );
    expect(
      list?.querySelector('a[href="/developers/specs/koala-rescue-club/raw"]')?.textContent,
    ).toBe("YAML");
    expect(
      list?.querySelector('a[href="/developers/specs/next-station-london"]')?.textContent,
    ).toBe("Open reference");
    expect(
      list?.querySelector('a[href="/developers/specs/next-station-london/raw"]')?.textContent,
    ).toBe("YAML");
    expect(document.body.textContent).not.toContain("Workspace");
    expect(list?.querySelector('a[href="/developers/specs/workspace"]')).toBeNull();
    expect(list?.querySelector('a[href="/developers/specs/workspace/raw"]')).toBeNull();
    expect(document.body.textContent).not.toContain("available");
    expect(document.body.textContent).not.toContain("AsyncAPI 3.0");
    expect(document.body.textContent).not.toContain("Version 0.1.0");
  });
});

function render(Component: unknown, props: Record<string, unknown>) {
  const target = document.createElement("div");
  document.body.append(target);

  const component = flushSync(() =>
    mount(Component as SvelteComponent<Record<string, unknown>>, { target, props }),
  );

  cleanup = async () => {
    await unmount(component);
    target.remove();
  };
}
