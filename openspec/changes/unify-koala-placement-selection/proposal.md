## Why

Koala Rescue Club currently has two mutation paths for the same turn decision: full-shape placements use a private server-owned selection followed by `submit`, while one-cell fallbacks remain client-owned previews committed through `circle_tree` or `circle_koala`. This split complicates reconnect behavior, duplicates client orchestration, and leaves semantically related actions with different atomicity boundaries.

## What Changes

- Use one private server-owned selection for tree and koala marks, whether the player eventually submits one cell or a complete die shape.
- Derive the submitted primary effect from the selected mark and cell count: one cell resolves as the legal fallback, while exactly the adjusted die shape size resolves as the full placement.
- Keep selection edits separate from committed sheet mutations, volunteer spending, bonus resolution, and player submission.
- Make `select`, `deselect`, and `submit` the canonical turn workflow, while retaining `reset` only as an optional bulk-clear convenience.
- Remove redundant client-supplied and aggregate-stored volunteer counts from the selection context; derive the cost from the shared roll and adjusted die value.
- **BREAKING** Remove `circle_tree` and `circle_koala` as public command events.
- **BREAKING** Replace public primary action identifiers with `tree` and `koala` mark choices in turn options, selection payloads, and caller projections.
- Update the Koala Rescue Club AsyncAPI contract and coordinate the separately delivered client migration so it sends every primary cell edit through the staged selection path and confirms every completed draft through `submit`.

## Capabilities

### New Capabilities

- `koala-rescue-club-unified-turn-selection`: Defines the authoritative selection states, mark-based command and projection contract, one-cell and full-shape submission rules, caller visibility, and separate-client coordination.

### Modified Capabilities

None.

## Impact

- Affects `D20.KoalaRescueClub.Command`, `Rules`, `Game`, `Projection`, the Koala AsyncAPI document, and focused command, rules, aggregate, projection, channel, and server tests.
- Breaks clients that dispatch `circle_tree` or `circle_koala`, send `action` or `volunteers_used` when starting a selection, or consume action-keyed turn options.
- Requires a coordinated update in the separate `ravecat/koala-rescue-club` client, especially its public types, SDK command port, centralized client store, turn draft reducer, controls, map targets, fixtures, and browser tests.
- Active in-memory sessions are not compatible across the contract deployment and must be restarted. No database migration is required.
- Tracked by [ravecat/d20#84](https://github.com/ravecat/d20/issues/84).
