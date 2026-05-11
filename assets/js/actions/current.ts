import { page } from "@inertiajs/svelte";
import type { Action } from "svelte/action";

const pathFromUrl = (url: string) => url.split(/[?#]/)[0] || "/";

const isCurrentPath = (currentPath: string, href: string) =>
  href === "/" ? currentPath === "/" : currentPath === href || currentPath.startsWith(`${href}/`);

export const current: Action<HTMLElement, string> = (node, href) => {
  let currentPath = "/";
  let currentHref = href;

  const updateCurrent = () => {
    if (isCurrentPath(currentPath, currentHref)) {
      node.setAttribute("aria-current", "page");
      return;
    }

    node.removeAttribute("aria-current");
  };

  const unsubscribe = page.subscribe(($page) => {
    currentPath = pathFromUrl($page?.url ?? "/");
    updateCurrent();
  });

  return {
    update(href) {
      currentHref = href;
      updateCurrent();
    },
    destroy() {
      unsubscribe();
    },
  };
};
