import { session } from "@rvct/phoenix";
import socket from "~/user_socket.js";
import type { Session } from "~types/game";

type SessionChannelSpec = {
  value: Session;
  connect: {
    ok: Session;
    error: { reason?: string };
  };
  events: {
    projection: Session;
  };
  actions: {
    start: {
      error: { reason?: string };
    };
  };
};

export type SessionStore = ReturnType<typeof createSession>;

export function createSession(id: string) {
  return session<SessionChannelSpec>(socket, {
    topic: `session:${id}`,
    connect: {
      ok: (_value, state) => state,
    },
    events: {
      projection: (_value, state) => state,
    },
  }).extend(({ push }) => ({
    start() {
      return push("start", {});
    },
  }));
}
