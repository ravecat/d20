## Why

Koala Rescue Club's stored-selection commit event is named `submit_turn_selection`, while the surrounding staged workflow already uses concise `select`, `deselect`, and `reset` events. Renaming the event to `submit` gives clients one clear, compact command without changing submission behavior or payload shape.

## What Changes

- **BREAKING** Rename the Koala Rescue Club WebSocket command `submit_turn_selection` to `submit`.
- Preserve the existing required `bonus_actions` payload, atomic stored-selection commit, validation errors, turn recording, and phase transition behavior.
- Remove support for the old event name instead of retaining a compatibility alias.
- Update the public AsyncAPI contract and focused backend and channel tests for the new event name.
- Update the dependent Koala Rescue Club client transport to send `submit` while preserving its typed submission action and payload.

## Capabilities

### New Capabilities

- `koala-rescue-club-submit-command`: Defines the public `submit` event that commits a caller's stored complete selection and ordered bonus decisions.

### Modified Capabilities

None.

## Impact

- Backend command routing and resolution: `D20.KoalaRescueClub.Command`, `Game`, and `Rules`.
- Public iframe contract: `priv/specs/koala-rescue-club.yaml` changes incompatibly and requires clients to send `submit`.
- Focused command, game, server, and session-channel tests use the new event name and verify the old name is rejected.
- Dependent client: `/home/max/apps/koala-rescue-club` sends `submit` through its existing `submitTurnSelection` action and covers the wire event at the SDK boundary.
- No database migration, persisted-state migration, dependency change, or in-memory session restart is required because the payload and aggregate state are unchanged.
- Rollback requires restoring the old backend event name and AsyncAPI contract together with the client transport name.
