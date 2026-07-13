## Context

`D20.Sessions` currently starts either `D20.Sessions.Server`, a default GenServer, or a custom module selected through `D20.Game.server/1`. `D20.Game.Server` then supports both GenServer and `:gen_statem` adapters, while `D20.KoalaRescueClub.Server` already demonstrates that a phase-aligned state machine can preserve the shared session API. This leaves two OTP callback models, GenServer-specific public types and stop calls, and a default runtime module under the sessions namespace even though its responsibility is to host a game.

The public session context, registry key, Presence messages, PubSub payload, session aggregate, game-engine callbacks, and volatile lifecycle are compatibility constraints. Existing live sessions do not require persisted-state migration.

## Goals / Non-Goals

**Goals:**

- Make `D20.Game.Server` the only runtime contract for live game-session owners.
- Use `:gen_statem` for both default and custom game servers.
- Provide a default implementation for engines without an explicit server.
- Preserve the existing `D20.Sessions` public API and observable runtime behavior.
- Keep engines and `D20.Sessions.Session` independent from OTP callbacks and timer state.
- Remove `D20.Sessions.Server` and GenServer-specific adapter branches after parity is proven.

**Non-Goals:**

- Do not force all games to implement custom server modules.
- Do not move game-specific timer rules into engine reducers.
- Do not introduce persistence or recovery for live session state.
- Do not change Presence tracking, channel topics, projections, permissions, iframe contracts, routes, or schemas.
- Do not remove GenServer from unrelated application subsystems.
- Do not redesign the custom-server extension surface beyond what is required to make it `:gen_statem`-only.

## Decisions

1. Use `D20.Game.Server` as the contract, default process, and customization macro.

   `D20.Game.Server` provides the stable `start_link/1`, `get/1`, and `dispatch/2` interface and runs directly as the fallback process. `use D20.Game.Server` injects that process API plus overridable default `init/1` and `handle_event/4` callbacks. Custom servers override only the standard callbacks they need and delegate unmatched cases with `super`, so the runtime does not expose a second, implicit hook protocol.

   Alternative considered: place the concrete fallback in `D20.Game.Server.Default`. That separates module roles but introduces a second runtime module and prevents the macro from being the single source of default server behavior.

2. Support only `:gen_statem` in the game-server adapter.

   `use D20.Game.Server` declares `@behaviour :gen_statem`, supplies the client API, temporary child specification, callback mode, and default lifecycle callbacks. The adapter uses `handle_event_function` by default and does not enable state-enter calls unless a custom server explicitly overrides the callback mode. Initialization and event handling remain ordinary overridable `:gen_statem` callbacks. GenServer-specific branches, examples, and types are removed; the contract uses exported `:gen_statem.server_ref/0` and `:gen_statem.start_ret/0` types.

   Alternative considered: keep both adapters for simple games. That retains the duplicated runtime model and forces `D20.Sessions` and tests to preserve primitive-specific compatibility indefinitely.

3. Model the default server state name with `Session.phase` and keep the existing data tuple.

   The default server uses `:waiting_for_players`, `:in_progress`, or `:finished` as its state name and `{slug, engine, session}` as state data. Accepted dispatches derive the next name from the authoritative updated session. Custom servers remain free to use a more specific state name, as Koala does with its game phase.

   Alternative considered: use a single `:running` state. It would technically use `:gen_statem` but discard the common lifecycle states already present in every session.

4. Preserve default runtime behavior by porting callback semantics, not by changing the domain flow.

   The default implementation translates `init/1`, get and dispatch calls, Presence info messages, broadcast order, rejected-command handling, and named idle expiration into `handle_event/4` return values. Successful updates are stored before subsequent events and the replied and published sessions remain identical. Idle expiration remains a named generic timeout reset by the same supported activity as today.

   Alternative considered: redesign idle expiration or Presence ownership during the primitive migration. Those changes have distinct semantics and would make parity failures harder to isolate.

5. Give every game engine an explicit server callback.

   `use D20.Game` always defines `server/0`, defaulting to `D20.Game.Server` unless the caller supplies `server: Module`. `D20.Game.server/1` delegates to that callback, and required engine validation includes it with the other engine callbacks.

   Alternative considered: generate `server/0` only for custom servers and resolve the default at runtime. That makes server selection implicit and requires a separate export check in every resolution path.

6. Keep `D20.Sessions` as the facade and remove primitive-specific operations.

   Session creation still resolves the server module and starts it under the existing DynamicSupervisor. Registry values continue to identify the implementation module. Lookup and calls remain polymorphic, while stop uses `:gen_statem.stop/3`. The legacy registry fallback resolves to the new default during the migration and can be removed with `D20.Sessions.Server` once tests no longer construct legacy values.

   Alternative considered: call `D20.Game.Server` directly from the session context. That would bypass explicit custom servers and make the facade responsible for game-specific runtime choices.

7. Keep custom runtime behavior in custom server modules.

   Koala overrides `init/1` to select its game phase, handles its state-changing events and roll `state_timeout`, and delegates shared initialization, get, idle expiration, and unmatched events with `super`. The engine remains a deterministic command reducer. This keeps the extension contract on standard `:gen_statem` callbacks instead of introducing game-specific hooks into the default server.

   Alternative considered: use one universal process module and add timer hooks to every engine. That would eliminate custom server modules but couple domain reducers to OTP event and timeout contracts.

## Risks / Trade-offs

- Default callback parity can drift from the existing GenServer behavior -> Characterize get, dispatch, Presence, publication, idle, registration, and stop behavior before replacing the module.
- State name and `Session.phase` can drift -> Derive the state name after every accepted authoritative update and assert the invariant through `:sys.get_state/1` in focused adapter tests.
- Removing the GenServer adapter breaks internal test servers and downstream custom modules -> Treat the adapter removal as an explicit breaking change, migrate repository implementations together, and expose only the option-free macro contract.
- State-changing callbacks duplicate some transition plumbing in custom servers -> Keep custom logic local, delegate unmatched events with `super`, and protect observable parity with default and Koala integration tests.
- An override can accidentally omit shared behavior -> Require an explicit catch-all `super` clause in partial `handle_event/4` overrides and test inherited Presence and idle behavior.
- Required `server/0` generation can affect engine validation -> Supply it through `use D20.Game` and test both the generated default and explicit custom option.
- A primitive migration can accidentally change reply or publication order -> Assert that returned, stored, and published sessions are identical for accepted commands and that rejected commands do not publish.
- Live old and new process modules cannot be converted in place -> Rely on volatile session lifecycle and code rollback rather than dual-runtime state conversion.

## Migration Plan

1. Add parity tests for the default server and server-selection fallback while the existing GenServer remains authoritative.
2. Port the default runtime callbacks into `D20.Game.Server` and run them in focused tests without changing production fallback.
3. Make `D20.Game.Server` `:gen_statem`-only and migrate custom repository test servers and Koala to the simplified adapter.
4. Switch `D20.Game.server/1`, `D20.Sessions` lookup, stop, and default startup paths to the new implementation.
5. Remove `D20.Sessions.Server`, the GenServer adapter branch, legacy types, and obsolete tests after parity and broader integration tests pass.
6. Run targeted game, session, Koala, channel, and Presence tests, then the repository-wide check.

Rollback is a code revert to the dual-runtime implementation. Session state is volatile, so rollback does not require data conversion; currently running sessions may be terminated during deployment or rollback.

## Open Questions

- None. Default servers use the shared session phase, custom servers retain game-specific state names, and game engines remain OTP-independent.
