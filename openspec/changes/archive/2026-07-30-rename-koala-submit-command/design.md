## Context

Koala Rescue Club exposes a staged shape workflow through `select`, `deselect`, `reset`, and `submit_turn_selection`. The final event passes through the generic session channel into game-specific command normalization, legality checks, deterministic resolution, and turn advancement. The event string appears in each of those game layers, the public AsyncAPI document, and focused tests, while the required payload contains only ordered `bonus_actions`.

This change is a public wire-contract rename. The game phase `:submit`, `can_submit_turn` permission, internal `submit_allowed?/2` predicate, payload schema, error atoms, and stored selection representation describe stable domain concepts and do not need renaming.

## Goals / Non-Goals

**Goals:**

- Make `submit` the only public event that commits a stored complete shape selection.
- Preserve command payload normalization and all state-dependent submission behavior.
- Keep the generic session channel game-agnostic.
- Keep implementation, tests, and AsyncAPI aligned on the new event name.
- Keep the dependent client transport aligned with the AsyncAPI event while preserving its internal action API.

**Non-Goals:**

- Renaming the `:submit` phase, submission permissions, rule predicates, or AsyncAPI payload schema ids.
- Changing selection, bonus, volunteer, history, scoring, or turn-transition semantics.
- Providing a compatibility window for `submit_turn_selection`.

## Decisions

### Rename only the public command event

Replace exact `submit_turn_selection` event matches with `submit` in `Command`, `Game`, and `Rules`. Keep the event on the existing generic `Sessions.dispatch/3` and `SessionChannel.handle_in/3` path so no new routing branch is introduced.

Alternative considered: rename every symbol containing "submit". This would create unrelated API churn in phase, permission, and rule vocabulary without improving the wire contract.

### Do not retain an old-name alias

The old event will be absent from the submit-phase dispatch allowlist and command validator. A client still sending it will receive the existing rejected-command behavior and cannot silently depend on an undocumented alias.

Alternative considered: temporarily accept both names. This weakens the requested single-name contract, leaves two public entry points to maintain, and makes removal timing ambiguous.

### Preserve the payload schema and bump the AsyncAPI version

The `submit` message continues to require `bonus_actions` and reference the existing submission payload schema. AsyncAPI channel, operation, and message component ids will use concise submit-oriented identifiers, the observable message `name` becomes `submit`, and the contract version advances from `0.5.0` to `0.6.0` for the breaking event rename.

Alternative considered: rename the payload schema id too. The schema id is not observable wire data and still accurately describes the payload, so changing it would add diff noise without client value.

### Preserve the client action API and rename only its wire event

The dependent client's `submitTurnSelection(payload)` action remains the typed boundary used by the turn store and components. Only its SDK `call` event changes from `submit_turn_selection` to `submit`; `SubmitTurnSelectionPayload` remains unchanged. A focused store test captures the SDK boundary and asserts the exact event and payload.

Alternative considered: rename the client action and processing key to `submit`. That would create broad internal churn without improving the observable protocol, which is defined by the event passed to the SDK call.

### Cover both the new route and old-name rejection

Focused command and game tests will use `submit` for successful and failed submissions. At least one validator or game-boundary assertion will prove `submit_turn_selection` is no longer accepted, and the server integration test will prove `Sessions.dispatch/3` reaches the same turn workflow with `submit`.

## Risks / Trade-offs

- [A deployed iframe client still sends `submit_turn_selection`] -> Update and validate the dependent client transport in the same change and deploy it with the matching backend contract.
- [A broad textual replacement renames internal domain concepts] -> Restrict edits to exact event strings and public AsyncAPI operation/message identifiers.
- [Implementation and AsyncAPI drift] -> Search for the old event across code, tests, and `priv/specs`, then validate the AsyncAPI document and run focused tests.

## Migration Plan

1. Validate and deploy the updated client that sends `submit` together with the matching backend and AsyncAPI contract.
2. Existing active sessions continue unchanged because command payloads and aggregate state are compatible.
3. Roll back by restoring the old event string in backend, AsyncAPI, tests, and client transport together.

## Open Questions

None. The new event name, lack of alias, unchanged payload, and dependent client scope are fixed by this change.
