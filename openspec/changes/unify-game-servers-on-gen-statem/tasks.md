## 1. Runtime Characterization

- [x] 1.1 Extend `test/d20/sessions_test.exs` to characterize the default server's registry value, shared lifecycle state names, get results, accepted and rejected dispatch behavior, publication order, and temporary restart semantics.
- [x] 1.2 Add focused default-server tests for Presence join and leave enrichment, accepted and rejected membership updates, and idle expiration before changing the production fallback.
- [x] 1.3 Update `test/d20/game_test.exs` to characterize generated default-server selection and explicit custom-server selection.
- [x] 1.4 Replace GenServer custom-server fixtures with `:gen_statem` fixtures and assert that default and custom implementations remain indistinguishable through `D20.Sessions`.

## 2. Unified Game Server Runtime

- [x] 2.1 Make `D20.Game.Server` the concrete default runtime with direct initialization and event handling based on the shared session phase.
- [x] 2.2 Port Presence subscription, profile enrichment, join and leave dispatch, and rejected Presence behavior to the default `:gen_statem` implementation.
- [x] 2.3 Port the named idle timeout to the default implementation and verify supported activity resets it without changing shared session state names.
- [x] 2.4 Simplify `D20.Game.Server` to a `:gen_statem`-only adapter with `server_ref/0` and `start_ret/0` types, temporary child specs, registry naming, client calls, and an overridable callback mode.
- [x] 2.5 Make `use D20.Game.Server` accept no options and remove GenServer adapter examples, generated callbacks, and types.

## 3. Engine Selection and Session Facade

- [x] 3.1 Change `use D20.Game` to generate `server/0` with `D20.Game.Server` by default, preserve the explicit `:server` option, and make `D20.Game.server/1` delegate to the generated callback.
- [x] 3.2 Switch `D20.Sessions` default lookup and startup behavior to the new default game server while preserving registry keys and custom implementation values.
- [x] 3.3 Replace the GenServer-specific stop path with `:gen_statem.stop/3` and preserve idempotent handling of already stopped processes.
- [x] 3.4 Migrate `D20.KoalaRescueClub.Server` and repository custom-server fixtures to direct standard `:gen_statem` callbacks without changing Koala state names, roll deadlines, or timeout behavior.

## 4. Legacy Removal and Documentation

- [x] 4.1 Remove `D20.Sessions.Server` after the new default implementation passes parity tests and remove obsolete aliases, fallback clauses, and GenServer-specific tests.
- [x] 4.2 Update module documentation and types to describe `D20.Game.Server` as the default runtime and customization macro, the generated engine callback, and the ownership boundary between sessions, servers, and engines.
- [x] 4.3 Search the repository for remaining `D20.Sessions.Server`, `otp: :gen_server`, and game-server `GenServer.server/0` or `GenServer.on_start/0` references and remove or migrate them.

## 5. Validation

- [x] 5.1 Run `mix format` on touched Elixir and ExUnit files and verify `mix format.check` and `git diff --check` pass.
- [x] 5.2 Run `mix test test/d20/game_test.exs test/d20/sessions_test.exs` for server selection, default runtime, custom runtime, registry, dispatch, Presence, idle, and stop behavior.
- [x] 5.3 Run `mix test test/d20/koala_rescue_club test/d20_web/channels/session_channel_test.exs` to validate custom state-machine and channel integration behavior.
- [x] 5.4 Run `openspec validate unify-game-servers-on-gen-statem --strict` and `just check` before completion, recording any unrelated pre-existing blocker with its command output.

## 6. Extension Contract Clarity

- [x] 6.1 Remove generated and default game-specific hooks so `D20.Game.Server` and custom servers share only the declared process API and standard `:gen_statem` contract.
- [x] 6.2 Add an export-surface regression test and rerun targeted, OpenSpec, formatting, and repository-wide validation.

## 7. Standard Callback Extension

- [x] 7.1 Replace the internal `handle_event/5`, optional game hooks, and public transition helper with overridable standard `init/1` and `handle_event/4` defaults.
- [x] 7.2 Make Koala override only its phase-specific standard callbacks and delegate unmatched events with `super`.
- [x] 7.3 Verify inherited Presence membership behavior, Koala roll scheduling, formatting, OpenSpec, and the repository-wide check.
- [x] 7.4 Inline the default transition result construction in dispatch and Presence handling, then rerun focused validation.
