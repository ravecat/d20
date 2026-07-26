import type { FormDataConvertible } from "@inertiajs/core";
import { session } from "phoenix-session";
import { socket } from "~/shared/api";
import type { Session } from "~/shared/types";

type CommandError = {
  reason?: string;
};

type Attrs = Record<string, FormDataConvertible>;

export function createSession(topic: string) {
  return session<Session>(socket, {
    topic,
    connect: {
      ok: (_value, state: Session) => state,
    },
    events: {
      projection: (_value, state: Session) => state,
    },
  }).extend(({ call }) => ({
    join() {
      return call<unknown, CommandError>("join", {});
    },
    start(attrs: Attrs = {}) {
      return call<unknown, CommandError>("start", attrs);
    },
  }));
}

export type SessionStore = ReturnType<typeof createSession>;
export type SessionState = Parameters<Parameters<SessionStore["subscribe"]>[0]>[0];
