import { createSession } from "@rvct/phoenix";
import socket from "../user_socket.js";

type CursorPoint = {
  id: string;
  x: number;
  y: number;
};

type CursorProjection = CursorPoint[];

type CursorProjectionPayload = {
  cursors: CursorProjection;
};

type CursorSessionSpec = {
  value: CursorProjection;
  connect: { ok: CursorProjectionPayload };
  events: {
    projection: CursorProjectionPayload;
  };
};

export const cursors = createSession<CursorSessionSpec>(socket, {
  topic: "cursors",
  value: [],
  connect: {
    ok: (_value, projection) => projection.cursors,
  },
  events: {
    projection: (_value, projection) => projection.cursors,
  },
}).extend(({ push }) => ({
  move(point: { x: number; y: number }) {
    push("move", point);
  },
}));
