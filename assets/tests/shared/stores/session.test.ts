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
  it("exposes separate game join and session start commands", () => {
    const joinCall = {};
    const startCall = {};
    mocks.call.mockReturnValueOnce(joinCall).mockReturnValueOnce(startCall);

    const controller = createSession("session:session-a");

    expect(controller.join()).toBe(joinCall);
    expect(controller.start({ sheet: "dharug" })).toBe(startCall);
    expect(mocks.call).toHaveBeenNthCalledWith(1, "join", {});
    expect(mocks.call).toHaveBeenNthCalledWith(2, "start", { sheet: "dharug" });
  });
});
