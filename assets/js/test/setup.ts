import { afterEach, vi } from "vitest";
import inertiaMock from "./mocks/inertia";

vi.mock("@inertiajs/svelte", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@inertiajs/svelte")>();
  const { default: inertiaMock } = await import("./mocks/inertia");

  return {
    ...actual,
    inertia: inertiaMock.inertia,
    page: inertiaMock.page,
    router: inertiaMock.router,
    useForm: inertiaMock.useForm,
    usePage: inertiaMock.usePage,
  };
});

afterEach(() => {
  inertiaMock.reset();
});
