## Why

Koala Rescue Club currently requires a client to construct and submit an entire die shape at once, including choosing its rotation or reflection outside the server. That contract makes an eventual sheet UI responsible for geometry rules and cannot guide a player away from a partial selection that can no longer form a legal placement.

## What Changes

- Replace whole-shape submission with a server-owned, per-player turn selection that starts with the first cell click after the shared roll and records one selected cell at a time.
- Include the initial clickable cells for every legal shape action in `turn_options`, so highlights are available immediately after the roll without a separate start command.
- Recalculate and project the legal next cells after every selection or deselection by filtering the legal placements that can still contain the partial selection.
- Keep partial selections out of the committed player sheet and spend no volunteers until a complete selection is submitted successfully.
- Let clients render cells as checkbox-like controls without implementing rotation or reflection controls. Shape transforms remain an internal server rule used to enumerate and validate legal placements.
- Preserve simultaneous play by isolating each player's draft selection and exposing it only in that caller's projection.
- Preserve atomic turn resolution: the server commits the complete primary action, volunteer spending, and submitted bonus decisions together.
- **BREAKING** Replace `plant_trees` and `rehome_koalas` payloads containing `target_cells` with contextual single-cell selection, cell deselection, reset, and final submission commands.
- Keep map geometry, scoring, session lifecycle, routes, registry bindings, persistence behavior, and automatic rolling unchanged.

## Capabilities

### New Capabilities

- `koala-rescue-club-turn-selection`: Defines server-guided incremental primary-action selection, caller-specific legal-cell projections, and atomic completion of a selected turn.

### Modified Capabilities

- None. There are no synchronized capabilities under `openspec/specs`; this change supersedes the whole-shape submission behavior introduced by the still-unarchived `implement-koala-rescue-club-rules` change.

## Impact

- Affected backend modules: `D20.KoalaRescueClub.Command`, `Game`, `Rules`, `Ruleset`, `Projection`, and their focused tests.
- Affected public game contract: Koala-specific channel commands and projection fields used by the Koala iframe client. The generic session envelope and channel transport remain unchanged.
- The projection will replace canonical client-facing shape offsets with server-derived selection state and available cells. Static shape data remains internal for placement enumeration.
- The paired Koala iframe client consumes the new initial and continuation cell projections and no longer computes or rotates whole placements locally.
- No dependency or database migration is required. In-memory drafts disappear with their session process, like the rest of the game state.
- Rollback is a code revert. Any connected client must use the same version of the Koala command and projection contract because the staged protocol is intentionally incompatible with whole-shape submission.
