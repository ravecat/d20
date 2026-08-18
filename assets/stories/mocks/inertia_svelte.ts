export { default as Form } from "./inertia_form.svelte";

type StoryPage = {
  url: string;
  props: {
    auth: InertiaProps["auth"];
    errors: Record<string, string>;
  };
};

const defaultPage = (): StoryPage => ({
  url: "/",
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

const page = defaultPage();

export function setStoryPage(nextPage: StoryPage) {
  Object.assign(page, nextPage);
}

export function resetStoryPage() {
  Object.assign(page, defaultPage());
}

const preventVisit = () => undefined;

export const router = {
  get: preventVisit,
  post: preventVisit,
};

export const usePage = () => page;

export function inertia(node: HTMLElement) {
  const preventNavigation = (event: MouseEvent) => event.preventDefault();
  node.addEventListener("click", preventNavigation);

  return {
    destroy: () => node.removeEventListener("click", preventNavigation),
  };
}
