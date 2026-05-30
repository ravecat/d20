import { session } from "@rvct/phoenix";
import { Socket } from "phoenix";
import type { Session } from "~types/game";
import type { ModuleConnection } from "~types/module";

type StartError = {
  reason?: string;
};

export function createSession(connection: ModuleConnection) {
  const socket = new Socket(connection.endpoint, { authToken: connection.token });
  socket.connect();

  const store = session<Session>(socket, {
    topic: connection.topic,
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

  return Object.assign(store, {
    disconnect() {
      socket.disconnect();
    },
  });
}
