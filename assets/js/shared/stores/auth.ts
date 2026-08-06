import { createStore } from "@xstate/store";

type AuthPrompt = NonNullable<InertiaProps["auth"]["prompt"]>;

type AuthContext = {
  open: boolean;
  mode: "register" | "login";
  email: string;
  prompt: AuthPrompt | null;
  registrationCompleted: boolean;
  magicLinkCompleted: boolean;
  passwordVisible: boolean;
};

export const auth = createStore<
  AuthContext,
  {
    open: null;
    openPrompt: { prompt: AuthPrompt };
    switchMode: { mode: AuthContext["mode"] };
    updateEmail: { email: string };
    registrationSucceeded: null;
    magicLinkSucceeded: null;
    togglePassword: null;
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
    passwordVisible: false,
  },
  on: {
    open: () => ({
      open: true,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
      passwordVisible: false,
    }),
    openPrompt: (_context, event) => ({
      open: true,
      mode: "login",
      email: event.prompt.email,
      prompt: event.prompt,
      registrationCompleted: false,
      magicLinkCompleted: false,
      passwordVisible: false,
    }),
    switchMode: (context, event) => ({
      ...context,
      mode: event.mode,
      registrationCompleted: false,
      magicLinkCompleted: false,
      passwordVisible: false,
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
    togglePassword: (context) => ({
      ...context,
      passwordVisible: !context.passwordVisible,
    }),
    close: () => ({
      open: false,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
      passwordVisible: false,
    }),
    reset: () => ({
      open: false,
      mode: "register",
      email: "",
      prompt: null,
      registrationCompleted: false,
      magicLinkCompleted: false,
      passwordVisible: false,
    }),
  },
});
