## Context

Koala shape selection currently uses `player.turn_selection` as a server-side draft. Every cell click dispatches a mutating game command, updates the aggregate, and broadcasts a new session even though the draft is useful only to the acting client. The regular caller projection then reads that stored draft and adds derived continuation cells, completion, and bonus options.

The sibling Svelte client already has a local turn store and a draft sheet for bonus interaction. The public channel contract is documented in `priv/specs/koala-rescue-club.yaml`, so the backend and client must change together. The client worktree also contains unrelated in-progress bonus work that must remain intact.

## Goals / Non-Goals

**Goals:**

- Keep `Game` limited to shared committed facts such as player sheets, statuses, badges, rounds, rolls, and scores.
- Keep an unfinished shape draft in the acting client's local turn state.
- Calculate `options` and `selection` in `Projection` from current game facts and rule primitives.
- Preserve server-authoritative validation for every projected draft and final submission.
- Apply the full final shape selection and bonus actions atomically against the current game.
- Avoid broadcasts and shared-state writes for draft-only interaction.

**Non-Goals:**

- Persisting or recovering an unfinished draft across reconnects, refreshes, or deployment.
- Moving committed sheet changes or player submission status out of `Game`.
- Reimplementing placement legality in the client.
- Changing single-cell primary actions or the existing bonus resolution model beyond payload integration.
- Introducing compatibility aliases for the removed events or session `selection` field.

## Decisions

### The client owns the complete unfinished draft

The Svelte turn store will own `action`, `die_value`, `volunteers_used`, and `selected_cells`. Adding or removing a shape cell creates the next complete draft and sends it to the server. Reset is local because clearing a non-authoritative draft requires no server action.

Keeping only a delta such as the last clicked cell was rejected because it would require the server to retain prior draft state. Computing continuation cells entirely in the client was rejected because it would duplicate shape and field legality.

### A stateless projection request returns selection details

The channel event `project_turn_selection` will accept the full draft and reply with the caller-specific `TurnSelection` map. The request will read the current session snapshot, validate and normalize the payload, and call the Koala projection without dispatching a game command or broadcasting a session update.

`D20Web.Projection` will route the request to the game-specific projection so the generic channel does not assemble Koala data. The normal session projection will retain `options` but remove `selection`, because no server-owned value exists to populate it.

Returning the derived selection in the request reply was chosen over sending a separate pushed event because request-reply correlation prevents stale UI updates and matches the client's existing channel call abstraction.

### Projection assembles read models from rule primitives

`D20.KoalaRescueClub.Projection` will own the complete option and selection types and map construction. It will calculate costs and required shape sizes from `Ruleset`, and use public `Rules` primitives for legal shape placements, legal single-cell targets, action simulation, and unlocked bonuses.

`Rules` will no longer expose `turn_options` or `turn_selection` read-model functions or their projection-specific types. It will retain legality and state-transition functions needed both by projection calculation and authoritative submission. This keeps the dependency direction `Projection -> Rules -> Ruleset` and avoids making game mutation depend on rendering code.

### Submission carries and validates the full draft atomically

`submit_turn_selection` will require `action`, `die_value`, `volunteers_used`, `selected_cells`, and `bonus_actions`. `Command` will normalize the wire payload. `Rules.resolve_turn/2` will validate the current phase, player status, volunteer cost, exact legal shape, occupied cells, and bonus sequence before returning the updated committed player.

The server will not trust an earlier projection response because the game may have changed before submission. Failed validation leaves `Game` unchanged and returns the existing error reply shape.

### Draft events and game fields are removed without compatibility copies

`select_turn_cell`, `deselect_turn_cell`, and `reset_turn_selection` will be removed from the public contract and client transport. `turn_selection` will be removed from `Game.player`, constructors, turn resets, and transition code. The client will no longer expect `selection` in a joined or pushed session projection.

Keeping old mutating events temporarily was rejected because it would preserve the architectural problem and two competing draft owners.

## Risks / Trade-offs

- [An unfinished draft is lost on reconnect] -> Treat it as disposable UI state and initialize a fresh local draft from the current `options` projection.
- [A projected draft becomes stale before submit] -> Revalidate the full payload atomically during `submit_turn_selection`; never treat projection as a reservation.
- [Backend and client contracts disagree during rollout] -> Validate and deploy the AsyncAPI, backend, and client together, and roll them back together.
- [Projection and submission legality drift] -> Make both paths use the same public rule primitives and cover equivalent valid and invalid shapes in focused tests.
- [Unrelated client bonus work is overwritten] -> Patch only the existing transport and turn-state seams, inspect the dirty diff before and after, and retain current bonus behavior tests.

## Migration Plan

1. Add stateless projection routing and tests while moving read-model calculation out of `Rules`.
2. Change submission validation to accept the full draft, then remove stored draft fields and mutating draft commands.
3. Update the AsyncAPI operations, messages, session schema, and examples and validate the document.
4. Update the Svelte transport, types, local turn state, fixtures, and browser tests without resetting unrelated changes.
5. Run focused backend tests, broader Koala and channel tests, OpenSpec validation, and the client check, test, and build commands.
6. Deploy backend and static client in one release window.

Rollback requires reverting and redeploying both repositories together. Active unfinished drafts may be lost in either direction and need no data migration.

## Open Questions

None. Loss of unfinished client draft on reconnect is an accepted consequence of making it non-authoritative.
