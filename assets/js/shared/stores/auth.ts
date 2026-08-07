import { createStore } from "@xstate/store";

type AuthPrompt = NonNullable<InertiaProps["auth"]["prompt"]>;

type AuthContext = {
  open: boolean;
  mode: "register" | "login";
  email: string;
  prompt: AuthPrompt | null;
  registrationCompleted: boolean;
  magicLinkCompleted: boolean;
};

export const auth = createStore<
  AuthContext,
  {
    open: { prompt?: AuthPrompt };
    switchMode: { mode: AuthContext["mode"] };
    updateEmail: { email: string };
    registrationSucceeded: null;
    magicLinkSucceeded: null;
    close: null;
    reset: null;
  }
>({
  context: {
    open: false,
    mode: "register",
    email: "",
    prompt: null,
    registrationCompleted: false,
    magicLinkCompleted: false,
  },
  on: {
    open: (_context, event) => ({
      open: true,
      mode: event.prompt ? "login" : "register",
      email: event.prompt?.email ?? "",
      prompt: event.prompt ?? null,
      registrationCompleted: false,
      magicLinkCompleted: false,
    }),
    switchMode: (context, event) => ({
      ...context,
      mode: event.mode,
      registrationCompleted: false,
      magicLinkCompleted: false,
    }),
    updateEmail: (context, event) => ({
      ...context,
      email: event.email,
    }),
    registrationSucceeded: (context) => ({
      ...context,
      registrationCompleted: true,
    }),
    magicLinkSucceeded: (context) => ({
      ...context,
      magicLinkCompleted: true,
    }),
    close: () => ({
      open: false,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
    }),
    reset: () => ({
      open: false,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
    }),
  },
});
