## Context

The current implementation has two lifecycle boundaries mixed together:

- Creating a game session from `/games/:slug` through `POST /games/:slug/sessions`.
- Starting an already-created waiting session through the channel `start` event.

Koala Rescue Club currently needs a selected sheet before meaningful game state can be initialized. Passing `sheet` through `start` means the session exists before the selected game setup is known. That forces either placeholder state or late reinitialization of player sheets. The recent `attrs` registry field also puts game-specific setup knowledge in application configuration instead of the game engine.

## Goals / Non-Goals

**Goals:**

- Treat session creation attrs as part of game initialization.
- Let each game own the schema, validation, defaults, and UI description for its creation attrs.
- Keep the registry focused on stable operational bindings: slug, engine, BGG id, and sandbox.
- Keep `start` as a session lifecycle transition with no game creation payload.
- Preserve existing shareable session URLs and iframe module connection behavior.
- Support games with no creation attrs without forcing boilerplate UI.

**Non-Goals:**

- Do not add a generic full-featured form builder.
- Do not add database persistence for session creation attrs.
- Do not change module iframe payloads or embedded game command protocols beyond `start` becoming payload-free.
- Do not make registry responsible for game-specific validation rules.

## Decisions

1. Game engines own creation attrs.

   Add a game boundary for creation attrs instead of keeping attrs in `D20.Games.Registry`.

   A game can expose a serializable attrs description for the frontend and validate raw submitted attrs during initialization. The concrete implementation can be an embedded schema, Ecto changeset, or a small game-specific module, but it belongs beside the game engine.

   For Koala Rescue Club this should likely be a creation attrs schema with a required `sheet` field and values from `D20.KoalaRescueClub.Ruleset.sheets/0`.

   Alternative considered: keep `attrs` in registry as a map. That is simpler for rendering but duplicates game rules in config and makes clients trust config-driven choices that the game still has to validate separately.

2. `D20.Game` provides helper functions for optional attrs contracts.

   Keep existing engines compatible by preserving `init/0`. Add optional engine callbacks such as:

   - `creation_attrs/0` for a serializable client description.
   - `init/1` for initialization from validated or raw creation attrs.

   A `D20.Game.init(engine, attrs)` helper can choose `init/1` when the engine implements it, call `init/0` for empty attrs, and reject non-empty attrs for engines that do not support creation attrs.

   Alternative considered: make `init/1` mandatory immediately. That is cleaner long-term, but it creates mechanical churn across every placeholder engine before the new behavior is useful.

3. Session creation passes attrs into game initialization.

   Change the session creation path from:

   ```elixir
   D20.Sessions.create(slug, engine, owner_id)
   ```

   to:

   ```elixir
   D20.Sessions.create(slug, engine, owner_id, attrs)
   ```

   The session process should only start after `Session.new(engine, owner_id, attrs)` succeeds. Invalid creation attrs must not leave a partially created process.

   Alternative considered: create the session first and dispatch an internal setup command. That keeps `Session.new/2` simple, but it still models setup as an event after session creation and makes rollback on invalid attrs harder.

4. `start` becomes payload-free setup transition.

   The channel `start` event should send an empty attrs map. Game engines that need setup choices must already have them in their initialized state.

   For Koala Rescue Club, selected `sheet` should be set during `init/1`. Player joins before start should allocate sheets for that selected map. Starting the game should mark players ready, enter the roll phase, and advance to turn 1 without reading `sheet` from the command.

   Alternative considered: keep accepting attrs on `start` for backward compatibility. Existing sessions are in-memory and short-lived, so preserving the old command shape is not worth keeping two valid lifecycle models.

5. Frontend attrs form belongs on the no-session Play state.

   `/games/:slug` without `session` should render controls from the engine-provided attrs description. Submitting Play posts those values to `POST /games/:slug/sessions`.

   `/games/:slug?session=:id` should not show or submit creation attrs. Its Start button only calls the session channel `start` event.

   Alternative considered: keep the attrs controls inside `SessionPanel`. That is exactly the current bug: it asks for game creation input after the session already exists.

## Risks / Trade-offs

- [Risk] Ecto changesets validate attrs but do not automatically describe UI controls. -> Use a small serializable attrs description generated by the game from the same constants as validation, not from registry config.
- [Risk] Unknown or malicious attrs could be silently ignored by games without setup attrs. -> The `D20.Game.init/2` helper should reject non-empty attrs unless an engine implements `init/1`.
- [Risk] Koala player sheet initialization changes from start-time to join-time. -> Add tests for selected sheet at creation, joining before start, and payload-free start.
- [Risk] Existing frontend tests expect attrs in `SessionPanel`. -> Move coverage to game detail page creation form tests and keep `SessionPanel` tests focused on waiting/in-progress session behavior.
- [Risk] Placeholder engines may not implement the optional callbacks. -> Optional callbacks preserve compatibility for games that use empty attrs.

## Migration Plan

1. Remove `attrs` from registry entries and config.
2. Add game-owned creation attrs description and initialization support.
3. Update `D20.Sessions.create` and `D20.Sessions.Session.new` to accept creation attrs.
4. Update `D20Web.PageController` to pass request params from `POST /games/:slug/sessions` into session creation.
5. Update `/games/:slug` props so attrs are resolved from the engine, not registry config.
6. Move the attrs form from `SessionPanel` to the no-session Play state on `game.svelte`.
7. Update Koala to select `sheet` during init and start without reading command attrs.
8. Update tests and run targeted backend/frontend validation.

Rollback is limited to in-memory runtime behavior: restore registry-owned attrs, pass attrs on channel `start`, and revert the Koala start command validation if the new creation boundary regresses.

## Open Questions

- Should the serializable attrs description include only UI hints, or also validation hints such as required fields and allowed values?
- Should default values be applied by the engine during validation even when the client omits them, or should required attrs always be explicitly submitted by the Play form?
- Should invalid creation attrs redirect back to `/games/:slug` with Inertia errors, or return a validation-specific status that the page can render inline?
