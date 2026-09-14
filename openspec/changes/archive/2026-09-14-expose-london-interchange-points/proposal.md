## Why

London score projections omit the three interchange point subtotals needed by the printed score sheet. Tracking issue: https://github.com/ravecat/d20/issues/285, a scoped correction to the accepted contract in #36.

## What Changes

- Add required `interchange_points` with categories 2, 3, and 4 to every player score.
- Derive the existing aggregate interchange score from those authoritative points.
- Synchronize the AsyncAPI contract and rules, projection, and channel tests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `next-station-london-gameplay`: Expose complete interchange category points in score projections.

## Impact

Touches London Rules and the public score contract, with corresponding tests. The separately owned Svelte client consumes the new field. No dependencies, rule changes, stored state changes, migrations, or command changes. Existing sessions derive the values at projection time. Rollback removes the projection extension together with the dependent client binding.
