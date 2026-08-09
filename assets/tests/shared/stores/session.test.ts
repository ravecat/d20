import { beforeEach, describe, expect, it, vi } from "vitest";
import { createSession } from "~/shared/stores/session";

const mocks = vi.hoisted(() => ({
  call: vi.fn(),
  controller: {
    subscribe: vi.fn(),
    detach: vi.fn(),
  },
  session: vi.fn(),
  socket: {},
}));

vi.mock("phoenix-session", () => ({
  session: mocks.session,
}));

vi.mock("~/shared/api", () => ({
  socket: mocks.socket,
}));

beforeEach(() => {
  mocks.call.mockReset();
  mocks.session.mockReset();
  mocks.session.mockReturnValue({
    ...mocks.controller,
    extend(factory: (helpers: { call: typeof mocks.call }) => object) {
      return { ...mocks.controller, ...factory({ call: mocks.call }) };
    },
  });
});

describe("Session store", () => {
  it("exposes the session start command", () => {
    const startCall = {};
    mocks.call.mockReturnValueOnce(startCall);

    const controller = createSession("session:session-a");

    expect(controller.start()).toBe(startCall);
    expect(mocks.call).toHaveBeenCalledWith("start", {});
  });
});
