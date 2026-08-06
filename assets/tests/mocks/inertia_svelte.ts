import Form from "./inertia_form.svelte";
import inertiaMock from "./inertia";

export { Form };
export const inertia = inertiaMock.inertia;
export const page = inertiaMock.page;
export const router = inertiaMock.router;
export const useForm = inertiaMock.useForm;
export const usePage = inertiaMock.usePage;
