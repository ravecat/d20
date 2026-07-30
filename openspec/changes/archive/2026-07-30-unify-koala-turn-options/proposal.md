## Why

Koala Rescue Club currently splits caller-specific turn state across top-level projection fields and makes the client derive some legal actions from the projected sheet. This duplicates game rules in the client and prevents the server from being the single authority for which controls and cells are available.

## What Changes

- **BREAKING** Replace top-level `turn_options` and `turn_selection` projection fields with a single caller-specific `turn` object containing `options` and `selection`.
- **BREAKING** Replace the turn-options array with a map keyed by die values `"1"` through `"6"` during the submit phase.
- **BREAKING** Replace each option's `volunteers_used` field with `volunteer_cost`, remove redundant `die_value` and `required_cells` fields, and represent available actions as a map.
- Derive availability and legal target cells for `plant_trees`, `rehome_koalas`, `circle_tree`, and `circle_koala` on the server.
- Keep existing command payloads unchanged while making the dependent client consume server-projected action availability.
- Update the Koala Rescue Club AsyncAPI contract, backend tests, and dependent Svelte client in lockstep.

## Capabilities

### New Capabilities

- `koala-rescue-club-turn-options`: Defines the caller-specific turn projection, die-value option map, server-derived action availability, and legal target cells.

### Modified Capabilities

None.

## Impact

- Affected backend modules: Koala Rescue Club rules and projection rendering.
- Affected public contract: `priv/specs/koala-rescue-club.yaml` and the session projection consumed by the game iframe.
- Affected dependent system: `/home/max/apps/koala-rescue-club`, including session types, turn state, controls, and browser tests.
- No database migration or persisted event change is required. Backend and client must be deployed together because the projection change is not backward compatible.
- Rollback requires reverting both the backend projection and the dependent client contract together.
