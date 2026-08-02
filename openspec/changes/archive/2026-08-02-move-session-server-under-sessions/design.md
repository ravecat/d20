## Context

`D20.Game.Server` is the shared OTP runtime for a live Session. It owns registration, Session state, Presence handling, attachment Registry mutations, publication, dispatch, and idle shutdown. Game engines only select that runtime through `D20.Game.server/1`; they do not own it.

The module currently also exposes `attach/2` and `detach/2` as behaviour callbacks, generated custom-server delegates, public wrappers, and overridable functions. Those entry points duplicate the public `D20.Sessions` context, which already resolves the registered Session and sends the same calls directly to its process.

## Goals / Non-Goals

**Goals:**

- Place the shared Session runtime under the `D20.Sessions` namespace and filesystem directory.
- Keep `D20.Sessions` as the only caller-facing attachment and detachment boundary.
- Preserve default and custom Session runtime behavior, error shapes, registration, supervision, and publication order.
- Make stale references fail at compile time so the repository has one canonical runtime module name.

**Non-Goals:**

- Change the `D20.Game` engine contract or the way an engine selects a custom server.
- Change attachment ownership, Registry keys or values, Presence semantics, Session projections, or Workspace discovery.
- Add a compatibility module under `D20.Game.Server`.
- Change public channel, persistence, or iframe contracts.

## Decisions

### Move the shared runtime to `D20.Sessions.Server`

The implementation moves from `lib/d20/game/server.ex` to `lib/d20/sessions/server.ex`, and all current code, tests, specifications, and architecture guidance use `D20.Sessions.Server`. `D20.Game.server/1` remains the engine-to-runtime selection seam, but its default becomes `D20.Sessions.Server`.

This name reflects ownership: the server hosts the generic Session lifecycle and calls a game engine as a pure reducer. Custom runtime modules continue to use the shared implementation with `use D20.Sessions.Server`.

### Remove attachment client functions from the server contract

`attach/2` and `detach/2` are removed from the behaviour callbacks, generated delegates, public server wrappers, and overridable functions. `D20.Sessions.attach/1` and `D20.Sessions.detach/2` remain the public API and send `{:attach, actor_id}` or `{:detach, actor_id}` to the registered Session process.

The corresponding `handle_event/4` clauses remain in `D20.Sessions.Server`. This preserves the important ownership rule: the Session process itself mutates its Registry entries and therefore owns them.

### Rename without a compatibility alias

No forwarding `D20.Game.Server` module is retained. The repository does not require source compatibility for custom servers outside the current codebase, and retaining both names would preserve the misleading ownership boundary. Compilation and exhaustive reference searches provide migration coverage.

### Preserve the remaining runtime interface

The server behaviour and generated delegates keep `start_link/1`, `get/1`, `dispatch/3`, and `preview/3`. Removing those is outside this change because they remain part of the configured server contract used by `D20.Sessions`.

## Risks / Trade-offs

- External source code that still uses `D20.Game.Server` will no longer compile. This is intentional and is mitigated by updating every repository-local implementation and documenting the compile-time migration.
- A missed module reference could surface only in a less frequently compiled test or game namespace. Mitigation: search the maintained source, tests, current specifications, and guidance, then run the complete repository check.
- Moving a runtime module changes the BEAM module identity during deployment. The application must be rebuilt and normally restarted; live upgrade compatibility is not provided by this change.

## Migration Plan

1. Move and rename the shared runtime module.
2. Update the default engine selection and every custom server using the shared runtime.
3. Remove the redundant attachment callbacks and delegates while retaining their event handlers.
4. Update focused contract tests, current specifications, and architecture guidance.
5. Format, run targeted tests, run the full repository check, and validate OpenSpec strictly.

Rollback restores the old module name and references. No database, Registry data, or persisted Session migration is required.

## Open Questions

None.
