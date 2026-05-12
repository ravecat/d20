import { session } from "@rvct/phoenix";
import socket from "~/user_socket.js";
import type { GameSession } from "~types/game";

type SessionChannelSpec = {
  value: GameSession;
  connect: {
    ok: GameSession;
    error: { reason?: string };
  };
  events: {
    projection: GameSession;
  };
};

export type GameSessionStore = ReturnType<typeof createGameSession>;

export function createGameSession(id: string) {
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
