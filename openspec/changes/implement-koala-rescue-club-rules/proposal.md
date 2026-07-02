## Why

Koala Rescue Club is registered as a playable game, but its engine currently returns `:not_implemented`, so sessions cannot start even though some static ruleset helpers already exist. The rules PDF gives enough confidence for game flow, dice, volunteers, bonuses, scoring phases, and map-level differences, but not enough machine-readable sheet geometry to safely validate placements, skybridges, row and column bonuses, hospitals, and badges without first encoding the maps.

## What Changes

- Replace the Koala Rescue Club engine placeholder with a real session-compatible game aggregate and reducer.
- Add machine-readable Koala Rescue Club map data for supported maps before placement validation is implemented.
- Add command validation for joining, starting with a selected map, rolling the shared die, and submitting each player's turn resolution.
- Validate known rules for 30 simultaneous turns, 2 scoring rounds, die-shape placement, volunteer die adjustment, fallback single-circle actions, bonus actions, hospital scoring, badge awards, final scoring, and tie breakers.
- Add projection and permission modules for Koala Rescue Club so clients receive caller-specific session state.
- Keep existing game registry, routing, iframe sandbox, and generic session contracts unchanged.
- Avoid implementing speculative geometry or badge predicates until the encoded map data can be reviewed against the supplied map sheets.

## Capabilities

### New Capabilities

- `koala-rescue-club-map-data`: Defines the machine-readable map data required to validate Koala Rescue Club sheets.
- `koala-rescue-club-gameplay`: Defines Koala Rescue Club session lifecycle, turn resolution, validation, scoring, projection, and permissions.

### Modified Capabilities

- None.

## Impact

- Affected backend modules: `D20.KoalaRescueClub.Game`, `D20.KoalaRescueClub.Ruleset`, new Koala Rescue Club command/rules/projection/permission modules, and `D20Web.Projection`.
- Affected tests: new Koala Rescue Club reducer, rules, permission, projection, and session tests; existing ruleset tests should remain valid.
- No database migration is required.
- No public route, game registry, iframe module, or generic session protocol change is intended.
- Runtime compatibility risk: Koala Rescue Club sessions are currently non-functional; this change makes them startable, so errors will move from `:not_implemented` to rule-specific validation reasons.
- Rollback impact: the registry can still point at the placeholder behavior or the change can be reverted without persistence migration.
