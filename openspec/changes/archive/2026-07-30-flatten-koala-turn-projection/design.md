## Context

`D20.KoalaRescueClub.Projection.render/2` currently renders caller-specific turn data as `turn: %{options: ..., selection: ...}`. The `turn` object has no lifecycle or invariant of its own: `options` is derived from the current game and caller on every render, while `selection` combines the caller's stored draft with derived legal continuation data.

The shape is a public iframe module contract documented in `priv/specs/koala-rescue-club.yaml` and consumed by the sibling Svelte application at `/home/max/apps/koala-rescue-club`. The backend and client therefore need a coordinated breaking migration. Existing game state, rules, commands, and command payloads are not part of this change.

## Goals / Non-Goals

**Goals:**

- Expose caller-specific turn options as top-level `options` on the Koala session projection.
- Expose the caller's staged selection or `null` as top-level `selection`.
- Keep legal-turn calculations in `Rules` while moving wire-map construction into `Projection`.
- Remove the redundant `turn` object from the projection and AsyncAPI schema.
- Preserve every existing value shape and caller-specific behavior inside `options` and `selection`.
- Update backend coverage and the dependent Svelte consumer as one contract change.

**Non-Goals:**

- Changing `D20.KoalaRescueClub.Game` or the legality calculated by `Rules.turn_options/2` and `Rules.turn_selection/2`.
- Renaming or changing selection and submission commands.
- Restoring the older `turn_options` and `turn_selection` field names.
- Renaming the client's local `turn` UI store, which is not the wire envelope.
- Rewriting the completed `unify-koala-turn-options` OpenSpec history.
- Adding other projection refactors to this change.

## Decisions

### Flatten and render `options` and `selection` in Projection

The renderer will place `options` and `selection` directly beside `permissions` and `game` in the session projection. `Rules.turn_options/2` will return die values with domain-native integer keys, and `Rules.turn_selection/2` will return the calculated selection facts. Private projection functions will explicitly build the public maps and convert die-value keys to strings for the JSON contract.

This preserves the rules as the authority for costs, legal actions, cells, completion, and bonuses without making the rules module own transport representation. Restoring top-level fields named `turn_options` and `turn_selection` was rejected because those names repeat the domain context and would revive a contract that the current client no longer uses.

### Remove the envelope without compatibility aliases

The backend will emit only `options` and `selection`. It will not emit a nested `turn` copy or the former `turn_options` and `turn_selection` fields.

Keeping both shapes would weaken the purpose of the refactor, leave two public contracts to test, and create uncertainty about removal timing. The trade-off is that backend and static client releases must be coordinated.

### Preserve projection ownership and game state boundaries

The internal `player.turn_selection` remains stored in the game aggregate because it is authoritative draft state. Only the caller receives its rendered selection details, and other players continue to receive `selection: null`. Turn options continue to be derived for the caller rather than persisted.

This prevents a transport refactor from changing gameplay, reconnect behavior, or selection privacy.

### Flatten the AsyncAPI session schema

The AsyncAPI `session` schema will require `options` and `selection` directly. The standalone `turn` schema will be deleted, while `turnOptions`, `turnOption`, `turnSelection`, and their nested schemas remain unchanged.

This makes the contract document reject the removed envelope instead of merely documenting the new fields alongside it.

### Migrate only session-projection reads in the client

The Svelte client will remove its `Turn` wire type and add `options` and `selection` to `Session`. Reads rooted in session values will move from `current.turn.*` to `current.*`. The exported local `turn` store and component references such as `turn.options` remain unchanged when they refer to that store.

This avoids a broad rename that would mix a wire-contract change with unrelated client-state terminology.

## Risks / Trade-offs

- [Backend and client versions can disagree during deployment] -> Build and validate both sides against the same contract, then deploy them in one coordinated release window. Roll back both sides together if either fails.
- [Generic top-level names may be less descriptive in a future multi-interaction session] -> Keep this change aligned with the requested projection shape; introduce a new explicit namespace only if a future concrete collision appears.
- [A mechanical client replacement can alter the local `turn` store API] -> Change only accesses rooted in session projection values and rely on TypeScript plus browser coverage to catch missed or over-broad edits.
- [Historical OpenSpec changes still describe the superseded envelope] -> Preserve them as completed historical records and make this new capability the specification for the flattened projection.

## Migration Plan

1. Update the backend rules/projection boundary and focused tests to emit and assert top-level `options` and `selection` only.
2. Update and validate the Koala AsyncAPI session schema, deleting the standalone `turn` schema.
3. Update the dependent Svelte session type, projection reads, fixtures, and browser tests while preserving unrelated dirty worktree changes.
4. Run targeted backend tests and AsyncAPI validation, then client formatting, lint, type checks, browser tests, and production build.
5. Release backend and client in a coordinated window because neither contract shape is backward compatible.

Rollback requires reverting and redeploying both repositories together. No data rollback or migration is needed.

## Open Questions

None for this scoped change. Additional projection-refactor items belong in follow-up changes unless they are explicitly added before implementation begins.
