## 1. Runtime Characterization

- [x] 1.1 Extend `test/d20/koala_rescue_club/server_test.exs` to assert the shared `get/1`, registry, automatic roll publication, and later-turn scheduling behavior that the migration must preserve.
- [x] 1.2 Add focused state-machine tests for phase-aligned state names, unchanged state after rejected commands, and identical replied, stored, and published sessions after accepted commands.
- [x] 1.3 Add timeout interaction tests proving that reads and Presence events during `:roll` neither duplicate nor move the roll deadline and that supported activity resets idle expiration independently.
- [x] 1.4 Add a channel test proving that Koala client `roll` events are rejected before session dispatch while Qwinto client rolls remain supported.

## 2. Koala State-Machine Migration

- [x] 2.1 Switch `D20.KoalaRescueClub.Server` to `use D20.Game.Server, otp: :gen_statem` and initialize the state name from the current Koala game phase while preserving Presence subscription failure semantics.
- [x] 2.2 Implement shared `:get` and command dispatch calls with `handle_event/4`, phase-derived transitions, reply actions, authoritative state storage, publication, and existing error behavior.
- [x] 2.3 Replace `Process.send_after/3`, `roll_token`, and stale-message handling with a single roll-state timeout created only when entering `:roll` and cancelled by leaving that state.
- [x] 2.4 Preserve `roll_due_at`, server-owned roll dispatch, later-turn scheduling, and `{:automatic_roll_failed, reason}` termination semantics.
- [x] 2.5 Port Presence join and leave handling to info events without changing profile enrichment, membership dispatch, publication, or rejected-event behavior.
- [x] 2.6 Implement a named idle timeout that is reset by supported calls, Presence events, and automatic transitions without replacing the roll-state timeout.
- [x] 2.7 Remove the Koala server's client-roll callback and reject Koala `roll` events at `D20Web.SessionChannel` with the existing `automatic_roll` response.

## 3. Shared Adapter Compatibility

- [x] 3.1 Verify the existing `D20.Game.Server` `:gen_statem` adapter provides the required child specification, registry name, `start_link/1`, `get/1`, `dispatch/2`, and callback mode; make only compatibility fixes required by the Koala migration.
- [x] 3.2 Update targeted shared session tests to confirm `D20.Sessions.create/4`, `get/1`, `dispatch/3`, `lookup/1`, and `stop/1` remain OTP-primitive agnostic for the Koala server.

## 4. Validation

- [x] 4.1 Run `mix format` on the touched Elixir and ExUnit files and verify `mix format.check` passes for the resulting change or record any unrelated pre-existing blocker.
- [x] 4.2 Run `mix test test/d20/koala_rescue_club/server_test.exs test/d20/sessions_test.exs`.
- [x] 4.3 Run `mix test test/d20/koala_rescue_club` to validate game rules, projections, and runtime integration together.
- [x] 4.4 Run `just check` before completion and record any unrelated pre-existing blocker with the failing command output.
