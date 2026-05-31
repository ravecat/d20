import { session } from "@rvct/phoenix";
import socket from "~/user_socket.js";
import type { Session } from "~types/game";

type StartError = {
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
      return call<unknown, StartError>("start", {});
    },
  }));
}
