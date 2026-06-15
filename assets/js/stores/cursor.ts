import { session } from "phoenix-session";
import socket from "~/user_socket";

type Cursor = {
  id: string;
  x: number;
  y: number;
};

type CursorsPayload = {
  cursors: Cursor[];
};

export const cursors = session<Cursor[]>(socket, {
  topic: "cursors",
  value: [],
  connect: {
    ok: (_value, projection: CursorsPayload) => projection.cursors,
  },
  events: {
    projection: (_value, projection: CursorsPayload) => projection.cursors,
  },
}).extend(({ cast }) => ({
  move(point: { x: number; y: number }) {
    cast("move", point);
  },
}));
