import { writable, type Readable } from "svelte/store";
import type { Workspace, WorkspaceState } from "~/widgets/workspace/model/workspace";

type StorySessionState<T> = {
  value: T | undefined;
  status: WorkspaceState["status"];
  error: WorkspaceState["error"];
  processing: Record<string, never>;
  errors: Record<string, never>;
  timeouts: Record<string, never>;
};

type StoryCall = <Response = unknown, Error = unknown>(
  event: string,
  payload: unknown,
) => Promise<Response | { error: Error } | undefined>;

type StorySessionController<T> = Readable<StorySessionState<T>> & {
  extend<Extension extends object>(
    factory: (helpers: { call: StoryCall }) => Extension,
  ): StorySessionController<T> & Extension;
};

const state = writable<StorySessionState<unknown>>({
  value: undefined,
  status: "loading",
  error: null,
  processing: {},
  errors: {},
  timeouts: {},
});
const call: StoryCall = async () => undefined;

export function set(value: Workspace) {
  state.set({
    value,
    status: "ready",
    error: null,
    processing: {},
    errors: {},
    timeouts: {},
  });
}

export function setStatus(status: WorkspaceState["status"]) {
  state.update((current) => ({ ...current, status }));
}

export function clear() {
  state.set({
    value: undefined,
    status: "loading",
    error: null,
    processing: {},
    errors: {},
    timeouts: {},
  });
}

export function session<T>(): StorySessionController<T> {
  const controller: StorySessionController<T> = {
    subscribe: state.subscribe as Readable<StorySessionState<T>>["subscribe"],
    extend<Extension extends object>(factory: (helpers: { call: StoryCall }) => Extension) {
      return { ...controller, ...factory({ call }) };
    },
  };

  return controller;
}
