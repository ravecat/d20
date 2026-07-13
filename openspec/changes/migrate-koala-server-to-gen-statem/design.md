## Context

`D20.KoalaRescueClub.Server` is currently a GenServer that owns a live `%D20.Sessions.Session{}` and schedules automatic rolls with `Process.send_after/3`. Its state adds a `roll_token` to the shared `{slug, engine, session}` data so that a late message from an older timer can be ignored. This is safe but manually recreates behavior that `:gen_statem` provides through state-bound timeouts.

Koala Rescue Club already exposes explicit `:setup`, `:ready`, `:roll`, `:submit`, and `:finished` phases. `D20.Game.Server` already provides a `:gen_statem` adapter with the shared `start_link/1`, `get/1`, and `dispatch/2` client API, registry naming, temporary child specification, and `handle_event_function` callback mode. The migration must preserve the existing `D20.Sessions` contract, Presence flow, projections, and volatile process lifecycle.

## Goals / Non-Goals

**Goals:**

- Represent the Koala server phase directly as the `:gen_statem` state name.
- Keep `{slug, engine, session}` as state data without Koala-specific timer correlation data.
- Replace manual roll messages with a roll-state timeout that is cancelled when the state changes.
- Keep idle expiration independent from the roll-state timeout.
- Preserve shared `get/1`, `dispatch/2`, Presence, publication, registry, and restart behavior.
- Establish a focused example of a game selecting the OTP primitive that matches its runtime behavior.

**Non-Goals:**

- Do not require every game server to use `:gen_statem`; the default session server remains a GenServer.
- Do not refactor shared Presence, broadcast, timeout, or state-access logic in this change.
- Do not change Channel topics, Presence semantics, membership semantics, public session APIs, game rules, projections, or permissions.
- Do not add persistence or recovery for volatile live sessions.
- Do not change the automatic roll duration or allow clients to own the roll.

## Decisions

1. Use the Koala game phase as the `:gen_statem` state name.

   After every accepted session dispatch, the server derives the next state name from the updated `%D20.KoalaRescueClub.Game{phase: phase}`. The state data remains `{slug, engine, session}`, so generic session metadata and the authoritative aggregate stay together without duplicating game data in the state name.

   Alternative considered: use a single `:running` state and inspect `session.game.phase` inside every event. That would technically use `:gen_statem` but would not gain state-bound timeout cancellation or make transitions explicit.

2. Schedule automatic rolls with `state_timeout` only when entering `:roll`.

   A transition from a non-roll state into `:roll` computes `roll_due_at`, stores it in the session projection state, and returns one `{state_timeout, delay, :roll}` action. Remaining in the same `:roll` state for reads or membership events keeps the existing timeout and does not reschedule it. Leaving `:roll` cancels the state timeout automatically.

   Alternative considered: keep `Process.send_after/3` and `roll_token` after migrating the callback shape. That would preserve the manual timer lifecycle and remove the primary reason to choose `:gen_statem`.

3. Keep idle expiration as a separate named generic timeout.

   The roll deadline belongs to `:roll`, while idle expiration belongs to the whole process. The server therefore uses a named idle timeout that is reset after supported calls, Presence events, and automatic transitions without replacing or cancelling the roll-state timeout.

   Alternative considered: use the event timeout for idle expiration. Event timeouts are cancelled by incoming events and would make the interaction with state timeout actions less explicit; a named timeout keeps the two concerns independently addressable.

4. Keep the shared server API and route calls through `handle_event/4`.

   `D20.Game.Server` continues to hide whether callers use `GenServer.call/2` or `:gen_statem.call/2`. Koala handles synchronous `:get` and `{:dispatch, command}` calls as `{:call, from}` events and replies with `:gen_statem` reply actions. Presence notifications and timer events are handled as info or timeout events without changing the public API.

   Client-originated Koala `roll` events are excluded at `D20Web.SessionChannel`, the untrusted transport boundary, so the game server does not need a special client-roll callback. The timeout handler remains the only runtime path that creates the server-owned roll command. Direct calls to `D20.Sessions.dispatch/3` are trusted backend calls and are outside the channel policy.

   Alternative considered: expose state-machine-specific functions from the Koala server. That would leak the selected OTP primitive into `D20.Sessions` and break the stable game-server contract.

   Alternative considered: reject client rolls inside the Koala server. That duplicates a transport restriction in the domain process and makes a trusted backend API distinguish commands by an origin that is not represented in `D20.Command`.

5. Preserve the existing authoritative update and publication order.

   For accepted commands, the server first obtains the updated session from `Session.dispatch/3`, prepares any roll deadline required by the next phase, stores the final session, then replies and publishes that same value. Rejected commands preserve state and do not publish. Automatic roll failure stops the process with the existing `{:automatic_roll_failed, reason}` semantics.

   Alternative considered: schedule and publish from state-enter callbacks. Keeping preparation in the transition that accepted the command makes the replied, stored, and published session identical and avoids an intermediate roll state without `roll_due_at`.

## Risks / Trade-offs

- State name and `session.game.phase` can drift -> Derive the next state from every accepted updated session and assert the invariant in focused tests.
- Same-state activity can accidentally duplicate or reset the roll timeout -> Schedule only on a non-roll to roll transition and test reads, Presence events, and rejected calls during `:roll`.
- Idle and roll timeouts can interfere -> Use distinct timeout types and test that resetting idle activity does not move `roll_due_at` or produce duplicate rolls.
- Callback return shapes are more complex than GenServer tuples -> Centralize transition, reply, publication, and timeout action construction in small private helpers.
- Existing tests may depend on GenServer-specific messages or state shape -> Test only public session behavior and observable broadcasts, adding direct state-machine assertions only for adapter invariants.
- The generic session channel can expose a server-owned Koala command -> Reject Koala `roll` events at the channel boundary and cover the transport policy with a channel test.

## Migration Plan

1. Add or adjust focused tests that characterize current automatic roll, rejection, publication, Presence, and idle behavior.
2. Switch Koala to `use D20.Game.Server, otp: :gen_statem` and implement phase-aligned initialization and event handling.
3. Replace manual timer scheduling with roll-state timeout actions and remove `roll_token` and stale-message clauses.
4. Add the independent named idle timeout and verify shared lifecycle behavior.
5. Run targeted Koala server and session tests, then the broader repository checks required by the affected runtime scope.

Rollback is a code revert to the existing GenServer implementation. All affected session state is volatile, so no persisted state conversion or dual-runtime compatibility period is required.

## Open Questions

- None. The existing automatic roll delay, session lifecycle, and public server API remain authoritative constraints for the migration.
