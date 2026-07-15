## Why

The Koala Rescue Club session projection wraps two caller-specific read fields in a `turn` object that has no independent state or invariant. Removing that redundant envelope makes the public contract simpler before further projection refactoring adds more presentation data.

## What Changes

- **BREAKING** Replace `session.turn.options` with top-level `session.options`.
- **BREAKING** Replace `session.turn.selection` with top-level `session.selection`.
- Preserve the existing option map, staged-selection shapes, caller isolation, empty-object behavior, and `null` selection behavior.
- Keep legality and continuation calculations in `Rules`, while making `Projection` responsible for the public option and selection map shapes.
- Remove the standalone `turn` schema from the Koala Rescue Club AsyncAPI document and update focused projection coverage.
- Update the dependent `koala-rescue-club` Svelte session types, projection reads, fixtures, and browser tests in lockstep.
- Treat the change as incomplete until both the backend producer and the client consumer use and validate the flattened contract.
- Do not add duplicate compatibility fields or change game state, rules, commands, or command payloads.

## Capabilities

### New Capabilities

- `koala-rescue-club-session-projection`: Defines the flattened caller-specific Koala Rescue Club session projection contract and the absence of the redundant `turn` envelope.

### Modified Capabilities

None.

## Impact

- Backend producer: `D20.KoalaRescueClub.Projection`, `D20.KoalaRescueClub.Rules`, and focused rules and projection tests.
- Public iframe module contract: `priv/specs/koala-rescue-club.yaml` changes incompatibly and requires coordinated backend and static client deployment.
- Dependent consumer: `/home/max/apps/koala-rescue-club` session types, turn store projection reads, turn controls, fixtures, and browser tests.
- Persistence and migrations: none, because the stored game aggregate and `player.turn_selection` remain unchanged.
- Dependencies: none.
- Rollback: revert the backend projection, AsyncAPI schema, and dependent client changes together.
