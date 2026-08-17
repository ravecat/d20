import type {
  ErrorValue,
  FormDataConvertible,
  FormDataErrors,
  Page,
  PageProps,
  Router,
} from "@inertiajs/core";
import type { InertiaForm, InertiaFormProps } from "@inertiajs/svelte";
import { vi } from "vitest";

type MockFunction = ReturnType<typeof vi.fn>;
type InertiaSvelte = typeof import("@inertiajs/svelte");
type InertiaFormFields = Record<string, FormDataConvertible>;
type InertiaActionMock = InertiaSvelte["inertia"] & MockFunction;
type UseFormMock = InertiaSvelte["useForm"] & MockFunction;
type UsePageMock = InertiaSvelte["usePage"] & MockFunction;
export type FormSubmission = {
  action: string;
  method: string;
  data: Record<string, FormDataConvertible | FormDataConvertible[]>;
  errorBag?: string;
};
type FormResponder = {
  error: (errors: Record<string, string>) => void;
  success: () => void;
};
type RouterMockKey =
  | "delete"
  | "get"
  | "on"
  | "patch"
  | "post"
  | "prefetch"
  | "put"
  | "reload"
  | "remember"
  | "restore"
  | "visit";
type RouterMock = {
  [Key in RouterMockKey]: Router[Key] & MockFunction;
};
type MethodKeys<T> = {
  [Key in keyof T]: T[Key] extends (...args: infer _Args) => unknown ? Key : never;
}[keyof T];
type MethodMocks<T> = {
  [Key in MethodKeys<T>]: T[Key] & MockFunction;
};

export type InertiaFormMockState<TForm extends object = object> = InertiaForm<TForm>;

export type InertiaFormMock<TForm extends object = object> = InertiaForm<TForm> & {
  getState: () => InertiaForm<TForm>;
  setState: (state: Partial<InertiaForm<TForm>>) => void;
};

type InertiaFormMockOptions<TForm extends object = object> = {
  fields?: TForm;
  state?: Partial<InertiaForm<TForm>>;
};

const defaultPage = (): Page<PageProps> => ({
  clearHistory: false,
  url: "/",
  component: "Test",
  encryptHistory: false,
  flash: {},
  props: {
    auth: {
      authenticated: false,
      local: false,
      prompt: null,
      providers: {
        discord: { available: true },
        google: { available: true },
      },
    },
    errors: {},
  },
  rescuedProps: [],
  rememberedState: {},
  version: null,
});

const page = defaultPage() as (typeof import("@inertiajs/svelte"))["page"];
const preparedForms: InertiaFormMock[] = [];
const createdForms: InertiaFormMock[] = [];
const formResponders = new Set<FormResponder>();
let pendingFormResponder: FormResponder | undefined;
const formSubmit = vi.fn((_submission: FormSubmission) => undefined);

const router = {
  visit: vi.fn(),
  get: vi.fn(),
  post: vi.fn(),
  put: vi.fn(),
  patch: vi.fn(),
  delete: vi.fn(),
  prefetch: vi.fn(),
  reload: vi.fn(),
  remember: vi.fn(),
  restore: vi.fn(() => null),
  on: vi.fn(() => () => undefined),
} as RouterMock;

const inertia = vi.fn((_node: HTMLElement, _params?: unknown) => ({
  update: vi.fn(),
  destroy: vi.fn(),
})) as InertiaActionMock;

const useForm = vi.fn((...args: unknown[]) => {
  const form: InertiaFormMock =
    preparedForms.shift() ?? createForm<object>(fieldsFromUseFormArgs(args));
  createdForms.push(form);

  return form;
}) as UseFormMock;

const usePage = vi.fn(() => page) as UsePageMock;

const inertiaMock = {
  inertia,
  useForm,
  page,
  usePage,
  router,
  formSubmit,
  registerForm(responder: FormResponder) {
    formResponders.add(responder);

    return () => {
      formResponders.delete(responder);

      if (pendingFormResponder === responder) pendingFormResponder = undefined;
    };
  },
  submitForm(responder: FormResponder, submission: FormSubmission) {
    if (!formResponders.has(responder)) throw new Error("Cannot submit an unregistered form");

    pendingFormResponder = responder;
    formSubmit(submission);
  },
  respondWithErrors(errors: Record<string, string>) {
    takePendingFormResponder().error(errors);
  },
  respondWithSuccess() {
    takePendingFormResponder().success();
  },
  prepareForm<TForm extends object = object>(options: InertiaFormMockOptions<TForm> = {}) {
    const form = createForm<TForm>((options.fields ?? {}) as TForm, options);
    preparedForms.push(form as unknown as InertiaFormMock);

    return form;
  },
  latestForm() {
    return createdForms.at(-1) ?? preparedForms.at(-1);
  },
  setPage(page: Partial<Page<PageProps>>) {
    Object.assign(this.page, page);
  },
  reset() {
    preparedForms.length = 0;
    createdForms.length = 0;
    formResponders.clear();
    pendingFormResponder = undefined;
    Object.assign(this.page, defaultPage());
    this.inertia.mockClear();
    this.useForm.mockClear();
    this.usePage.mockClear();
    this.formSubmit.mockClear();

    for (const mock of Object.values(this.router)) {
      mock.mockClear();
    }
  },
};

export default inertiaMock;

function takePendingFormResponder() {
  if (!pendingFormResponder) throw new Error("No submitted form is awaiting a response");

  const responder = pendingFormResponder;
  pendingFormResponder = undefined;

  return responder;
}

function createForm<TForm extends object = InertiaFormFields>(
  fields: TForm = {} as TForm,
  options: InertiaFormMockOptions<TForm> = {},
): InertiaFormMock<TForm> {
  const fieldKeys = new Set(Object.keys(fields));
  const defaults = { ...fields };

  const setState = (state: Partial<InertiaForm<TForm>>) => {
    Object.assign(form, normalizeFormState({ ...form, ...state }));
  };

  const returnCurrent = () => form;
  const setStore = vi.fn((keyOrData: string | Partial<TForm>, value?: unknown) => {
    if (typeof keyOrData === "string") {
      fieldKeys.add(keyOrData);
      setState({ [keyOrData]: value } as Partial<InertiaForm<TForm>>);
      return;
    }

    for (const key of Object.keys(keyOrData)) {
      fieldKeys.add(key);
    }

    setState(keyOrData as Partial<InertiaForm<TForm>>);
  });
  const data = vi.fn(
    () =>
      Array.from(fieldKeys).reduce<Partial<TForm>>((values, key) => {
        values[key as keyof TForm] = form[key as keyof TForm] as TForm[keyof TForm];
        return values;
      }, {}) as TForm,
  );
  const reset = vi.fn((...keys: string[]) => {
    const nextFields =
      keys.length === 0
        ? defaults
        : keys.reduce<Partial<TForm>>((values, key) => {
            if (key in defaults) {
              values[key as keyof TForm] = defaults[key as keyof TForm];
            }

            return values;
          }, {});

    setStore(nextFields);
    return returnCurrent();
  });
  const clearErrors = vi.fn((...keys: string[]) => {
    const errors =
      keys.length === 0
        ? {}
        : (Object.fromEntries(
            Object.entries(form.errors).filter(([key]) => !keys.includes(key)),
          ) as FormDataErrors<TForm>);

    setState({ errors } as Partial<InertiaForm<TForm>>);
    return returnCurrent();
  });
  const setError = vi.fn((fieldOrErrors: string | FormDataErrors<TForm>, value?: ErrorValue) => {
    const errors =
      typeof fieldOrErrors === "string" ? { [fieldOrErrors]: value ?? "" } : fieldOrErrors;

    setState({ errors: { ...form.errors, ...errors } } as Partial<InertiaForm<TForm>>);
    return returnCurrent();
  });
  const resetAndClearErrors = vi.fn((...keys: string[]) => {
    reset(...keys);
    clearErrors(...keys);
    return returnCurrent();
  });
  const withPrecognition = vi.fn(() => form);
  const methods = {
    setStore,
    data,
    transform: vi.fn(returnCurrent),
    defaults: vi.fn(returnCurrent),
    reset,
    clearErrors,
    resetAndClearErrors,
    setError,
    submit: vi.fn(returnCurrent),
    get: vi.fn(returnCurrent),
    post: vi.fn(returnCurrent),
    put: vi.fn(returnCurrent),
    patch: vi.fn(returnCurrent),
    delete: vi.fn(returnCurrent),
    cancel: vi.fn(returnCurrent),
    dontRemember: vi.fn(() => form),
    optimistic: vi.fn(() => form),
    withPrecognition,
  } as unknown as MethodMocks<InertiaFormProps<TForm>>;
  const { fields: _fields, state: stateOptions = {} } = options;

  const form: InertiaFormMock<TForm> = {
    ...normalizeFormState({
      ...fields,
      isDirty: false,
      errors: {},
      hasErrors: false,
      progress: null,
      wasSuccessful: false,
      recentlySuccessful: false,
      processing: false,
      ...methods,
      ...stateOptions,
    } as InertiaForm<TForm>),
    getState: () => form,
    setState,
  } as InertiaFormMock<TForm>;

  return form;
}

function normalizeFormState<TForm extends object>(state: InertiaForm<TForm>): InertiaForm<TForm> {
  return {
    ...state,
    hasErrors: Object.keys(state.errors).length > 0,
  };
}

function fieldsFromUseFormArgs(args: unknown[]): InertiaFormFields {
  const candidate = args.at(-1);
  const fields = typeof candidate === "function" ? candidate() : candidate;

  return isFormFields(fields) ? fields : {};
}

function isFormFields(value: unknown): value is InertiaFormFields {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
