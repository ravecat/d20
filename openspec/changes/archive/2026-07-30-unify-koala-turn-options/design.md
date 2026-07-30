## Context

Koala Rescue Club renders a caller-specific `turn_options` array and a separate `turn_selection` value. Shape actions already receive server-derived legal cells, while the dependent Svelte client still derives `circle_tree` and `circle_koala` availability from the projected sheet. The split makes the wire contract redundant and lets client and server rules drift.

Turn options are derived data. They depend on the shared roll and phase plus the caller's pending status, volunteers, accessible areas, trees, and koalas. The projection is rendered independently for each session actor, so the same game state can legitimately produce different options for different players.

The current staged shape-selection protocol remains authoritative for multi-cell actions. This change reorganizes its caller-specific projection and extends the same server-owned availability model to the two atomic single-cell actions. No persisted aggregate state or command event format needs to change.

## Goals / Non-Goals

**Goals:**

- Make the server the sole authority for availability and legal cells of all four primary actions.
- Give the client one stable `turn` projection containing derived options and the current staged selection.
- Remove redundant option fields and client-side primary-action rule derivation.
- Keep caller-specific options recomputed from current authoritative game state on every projection render.
- Document and validate the breaking iframe contract in AsyncAPI and both repositories' tests.

**Non-Goals:**

- Do not persist turn options or add them to the game aggregate.
- Do not change existing Koala command payloads, action names, game rules, scoring, or turn progression.
- Do not migrate `circle_tree` or `circle_koala` to staged multi-step selection.
- Do not prescribe whether the client visually hides or disables an unavailable control.
- Do not introduce a generic permissions system for cell-level game rules.

## Decisions

1. Replace the two top-level fields with one caller-specific `turn` object.

   The projection exposes `turn.options` and `turn.selection`. `selection` retains the existing staged-selection data and owner-only behavior. The old `turn_options` and `turn_selection` fields are removed instead of being duplicated during a transition.

   Alternative considered: keep both old and new fields temporarily. This would reduce deployment coupling but would prolong two public contracts and would not simplify the projection. The backend and dependent iframe are controlled together, so a coordinated breaking update is smaller.

2. Key options by die value and keep all six keys during the submit phase.

   `turn.options` is a JSON object keyed by `"1"` through `"6"`. Each entry contains `volunteer_cost` and an `actions` object. The key replaces the redundant `die_value` field. `required_cells` is removed because legal cells and staged selection already carry the information the production client needs.

   All six options are projected after a roll while the caller can submit. This keeps the client control layout stable. An adjusted value the caller cannot afford still exposes its computed `volunteer_cost`, but its `actions` object is empty. Outside the caller's submit phase, `options` is an empty object because no meaningful volunteer cost can be derived without an active roll.

   Alternative considered: retain only affordable entries as in the current array. That forces the client to reconstruct the six-value domain and makes missing values carry both layout and permission meaning.

3. Use action-map membership as the availability flag.

   Each option's `actions` object may contain `plant_trees`, `rehome_koalas`, `circle_tree`, and `circle_koala`. A present action contains its sorted `available_cells`; an absent action is unavailable. No separate `enabled`, `visible`, or permission boolean is added.

   The action is absent when the volunteer cost is unaffordable or no legal target exists. Shape cells are the existing union of legal initial placements. Tree cells are accessible cells without a circled tree. Koala cells are accessible cells with a circled tree and without a circled koala.

   Alternative considered: project a fixed four-action object with booleans. That duplicates availability state, permits contradictory boolean and cell combinations, and makes clients handle entries that cannot be acted on.

4. Recompute options from authoritative state during projection rendering.

   `Rules.turn_options/2` remains a pure derivation over the current game and actor ID. It reads the roll, phase, caller status, available volunteers, rulesheet, accessible areas, and committed sheet. It does not cache options in player or game state. Every accepted command already causes caller-specific projections to be rendered again, so relevant state changes naturally refresh the map.

   Alternative considered: store options in the aggregate and update them after commands. This adds invalidation paths for state that is inexpensive to calculate and risks stale permissions.

5. Preserve command compatibility within the Koala protocol.

   The projection uses the presentation name `volunteer_cost`, while existing command payloads continue to send `volunteers_used`. The client copies the projected cost into that command field. Keeping command events unchanged limits this breaking change to read-model consumers and avoids unrelated reducer changes.

   Alternative considered: rename the command field at the same time. It is semantically cleaner but expands the change without affecting server authority or client simplification.

6. Treat control rendering as client presentation, not server state.

   The Svelte turn store reads action membership and available cells directly from `session.turn.options`. It may still combine that with local transient state such as request processing, the currently selected die, or an in-progress staged selection. The server decides what is legal, while the client decides how an unavailable option looks.

## Risks / Trade-offs

- [The breaking projection can disconnect an old iframe client] -> Deploy the backend and dependent client together and rollback both together.
- [All six entries slightly increase projection size] -> The bounded map is small and removes duplicated fields and local rule code.
- [Action absence does not explain why it is unavailable] -> Keep the contract minimal; add reason codes only if the product later needs to explain failures.
- [Projection and command validation could diverge] -> Reuse the same rulesheet and sheet predicates and retain command-side validation as the final authority.
- [Editing an already dirty dependent repository can overwrite unrelated work] -> Limit edits to the existing turn contract paths and preserve surrounding user changes.

## Migration Plan

1. Add the new option-map derivation and projection envelope with focused backend tests.
2. Update and validate the AsyncAPI session schema for the new wire shape.
3. Update the dependent client's types, turn store, controls, and browser tests to consume `turn.options` and `turn.selection`.
4. Run targeted backend and client tests, then repository-native format, type, and check commands appropriate to the affected areas.
5. Deploy backend and iframe client as one release boundary.

Rollback requires reverting both contracts together. There is no database migration, persisted-event conversion, or data rollback.

## Open Questions

None.
