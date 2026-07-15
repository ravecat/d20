## Why

Koala Rescue Club currently routes one game-specific, read-only selection request through the generic session channel and assembles rule-dependent interaction state inside projection code. Making the unfinished selection part of the game workflow restores the common command path, keeps authoritative selection state in the session process, and lets regular caller-specific projections derive the UI response.

## What Changes

- **BREAKING** Replace `project_turn_selection` with the game events `select`, `deselect`, and `reset`, all dispatched through the existing generic session command path.
- Store each pending player's private unfinished selection in the Koala game aggregate while leaving the committed player sheet unchanged until submission.
- Make `select` and `deselect` validate and update only legal intermediate selections, and make `reset` clear the stored selection.
- **BREAKING** Make `submit_turn_selection` resolve the stored complete selection plus submitted bonus decisions instead of accepting the complete selection draft again.
- Restore caller-specific `selection` data to regular join and broadcast projections, deriving available cells, completion, and bonus options from the stored selection and current rules.
- Remove the Koala-specific `project_turn_selection` callback from the generic session channel and remove event rendering from `D20Web.Projection`.
- **BREAKING** Simplify each player's confirmed `turns` history to an ordered list of accepted adjusted die values from 1 through 6, removing stored turn numbers, primary actions, and the `turn_result` type.
- Move the static round, active-turn, and die-value types to `Ruleset`; make `Game`, `Rules`, and `Projection` reference those ruleset-owned types instead of repeating literal ranges.
- Update the public AsyncAPI contract and dependent Koala Svelte client for the restored staged-selection workflow and simplified turn history.

## Capabilities

### New Capabilities

- `koala-rescue-club-server-owned-turn-workflow`: Defines server-owned staged selections, selection events, caller-specific derived selection projections, atomic submission, generic channel routing, and value-only confirmed turn history.

### Modified Capabilities

None.

## Impact

- Backend game workflow: `D20.KoalaRescueClub.Command`, `Game`, `Rules`, `Ruleset`, `Projection`, and focused tests.
- Generic web shell: `D20Web.SessionChannel` and `D20Web.Projection` lose the Koala-specific request path and return to generic dispatch and regular projection behavior.
- Public iframe contract: `priv/specs/koala-rescue-club.yaml` changes incompatibly and requires a coordinated client update.
- Dependent client: `/home/max/apps/koala-rescue-club` must send selection events, consume selection from regular projections, and type `turns` as die values.
- Runtime compatibility: no database migration is required, but active in-memory Koala sessions use an incompatible player-state shape and must be restarted during deployment.
- Dependencies: none.
- Rollback: backend, AsyncAPI, and dependent client changes must be reverted and redeployed together; unfinished selections may be discarded in either direction.
