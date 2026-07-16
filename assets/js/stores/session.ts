import type { FormDataConvertible } from "@inertiajs/core";
import { session } from "phoenix-session";
import socket from "~/user_socket.js";
import type { Session } from "~types/game";

type StartError = {
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
    start(attrs: Attrs = {}) {
      return call<unknown, StartError>("start", attrs);
    },
  }));
}
