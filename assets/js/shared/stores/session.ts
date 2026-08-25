import { session } from "phoenix-session";
import { socket } from "~/shared/api";
import type { Session } from "~/shared/types/game";

type CommandError = {
  reason?: string;
};

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
    start() {
      return call<unknown, CommandError>("start", {});
    },
  }));
}

export type SessionStore = ReturnType<typeof createSession>;
export type SessionState = Parameters<Parameters<SessionStore["subscribe"]>[0]>[0];
