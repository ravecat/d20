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
        facebook: { available: false },
        google: { available: false },
        steam: { available: false },
      },
    },
    errors: {},
  },
});

const page = defaultPage();

export function set(nextPage: StoryPage) {
  Object.assign(page, nextPage);
}

export function reset() {
  Object.assign(page, defaultPage());
}

const preventVisit = () => undefined;

export const router = {
  on: () => () => undefined,
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

export type StoryFormSubmission = {
  action: string;
  method: string;
  data: Record<string, unknown>;
};
export type StoryFormResponse = { errors?: Record<string, string> };
let formHandler: ((submission: StoryFormSubmission) => Promise<StoryFormResponse>) | undefined;
export const formRequests: StoryFormSubmission[] = [];

export function setFormHandler(handler?: typeof formHandler) {
  formHandler = handler;
  formRequests.length = 0;
}

export function submitForm(submission: StoryFormSubmission) {
  formRequests.push(submission);
  return formHandler?.(submission);
}
