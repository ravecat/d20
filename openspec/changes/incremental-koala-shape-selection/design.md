## Context

`D20.KoalaRescueClub.Rules.turn_options/2` currently projects each reachable die value with canonical shape offsets. A client must transform those offsets, choose every target cell, and send the complete `target_cells` list in one `plant_trees` or `rehome_koalas` command. `Rules.resolve_turn/2` then validates the full shape and commits the primary action, volunteer spending, and bonuses atomically.

The sheet UI needs a guided interaction instead. After the shared roll, a player chooses the adjusted die value and primary action, then checks cells one at a time. Initial cells must already be present in the roll projection, and the first click must create the draft without a separate start request. The server must then return only cells that can still extend the current partial selection into a legal placement. Koala Rescue Club turns are simultaneous, so each player's unfinished work must survive projection refreshes without becoming part of the committed sheet or exposing private intent to other players.

The map is small and all game state is already in-memory inside one serialized session process. There is no persistence or multi-process write coordination to add.

## Goals / Non-Goals

**Goals:**

- Make the server authoritative for legal shape growth and final shape validation.
- Let a client implement shape entry as select and deselect controls without rotation or reflection UI.
- Preserve atomic turn resolution, volunteer accounting, bonus ordering, and simultaneous turn advancement.
- Make partial selection resilient to projection refreshes and reconnects during the life of the session process.
- Keep the staged protocol deterministic and idempotent under duplicate select or deselect requests.

**Non-Goals:**

- Do not redesign unrelated Koala iframe layout or map rendering.
- Do not change map geometry, shape definitions, scoring, badges, automatic rolling, or the generic session transport.
- Do not persist drafts beyond the in-memory session lifetime.
- Do not migrate the one-cell `circle_tree` and `circle_koala` fallback commands to the staged protocol.
- Do not expose an explicit transform identifier or rotation control to clients.

## Decisions

1. Store a compact turn selection on the pending player.

   Add an optional per-player selection containing `action`, `die_value`, `volunteers_used`, and ordered `selected_cells`. Only `plant_trees` and `rehome_koalas` use this state. The selection is authoritative for reconnects but is not a committed sheet mutation.

   `turn_options` exposes initial available cells for each action. `select_turn_cell` carries `action`, adjusted `die_value`, `volunteers_used`, and one `target_cell`; on the first click it creates the draft, and when that context changes it replaces only the previous draft. `deselect_turn_cell` carries one `target_cell`. `reset_turn_selection` removes the draft. `submit_turn_selection` carries ordered `bonus_actions` but does not repeat the die choice or complete cell set. There is no separate command for creating an empty draft because the first cell click owns that transition.

   Volunteer slots remain available until `submit_turn_selection` succeeds. Creating, replacing, editing, or resetting a draft therefore has no resource side effects.

   Alternative considered: keep the draft only in the browser. That loses the selection on reconnect, requires the client to reproduce server geometry, and makes legal next-cell projection impossible without resending the whole partial selection.

2. Derive candidate placements from the existing shape transforms.

   Add a ruleset helper that enumerates every distinct translation of every allowed rotation and reflection of the selected die shape. A candidate is retained only when all cells exist, belong to one accessible area, and satisfy the current action prerequisites. Tree candidates exclude cells with circled trees. Koala candidates require circled trees and exclude cells with circled koalas.

   For selected set `S`, compatible candidates are all legal placements `P` where `S` is a subset of `P`. The available next cells are the sorted union of `P - S` across compatible candidates. A draft is complete when its selected-cell set is exactly one compatible candidate and its size equals the selected die shape size.

   The draft stores no candidate cache. Commands and projections recompute candidates from the selected map, current committed sheet, and selected cells through the same rules function. The sheets are small, while avoiding duplicated derived state prevents stale options and keeps command validation aligned with projection.

   Alternative considered: grow only from the last selected cell using adjacency rules. That can incorrectly reject valid non-linear shapes, depends on selection order, and still needs transform-specific branching.

3. Keep transforms server-side instead of removing transform validation.

   Incremental selection removes rotation and reflection from the client interaction, not from the game rules. The server must still enumerate all allowed transformed placements and revalidate the completed set before commit. Otherwise a forged command sequence could commit a shape that no allowed transform represents.

   Existing shape offsets remain internal reviewable ruleset data. `turn_options` exposes the reachable die value, volunteer cost, shape size, and each legal shape action's initial available cells, but not canonical offsets that a client must rotate.

   Alternative considered: trust that a sequence of previously projected cells forms a legal final shape. This is unsafe because projections can become stale, commands can be forged, and permissive next-cell calculations can otherwise compose an invalid set.

4. Use explicit idempotent edit commands rather than a toggle command.

   Selecting an already selected legal cell and deselecting an absent cell return the unchanged selection successfully. A selection that belongs to no compatible candidate is rejected without mutation. Explicit select and deselect intent is safe to retry, while a toggle can invert state twice when the transport retries or the user has multiple connected views.

   The selected cells are normalized to deterministic map coordinate order in projections and comparisons even if the aggregate preserves insertion order for editing.

   Alternative considered: one `toggle_turn_cell` command. It is convenient for a checkbox handler but is not idempotent and makes duplicate delivery observable.

5. Commit the staged turn atomically after a complete selection.

   A complete draft does not immediately mutate the player sheet. Projection simulates the primary action against a copy of the sheet and exposes any bonus decisions unlocked by that result. The player then sends `submit_turn_selection` with ordered bonus actions or explicit skips, following the existing bonus contract.

   Submission revalidates the roll, player status, volunteer cost, legal complete candidate, primary prerequisites, and bonus actions against the current authoritative state. Only after every check succeeds does the reducer spend volunteers, apply the selected cells, resolve bonuses, clear the draft, and mark the player submitted. Any error leaves both the committed sheet and complete draft unchanged so the player can correct the bonus choices or reset the selection.

   Alternative considered: commit automatically when the final cell is selected. That cannot preserve the current atomic relationship with bonuses unlocked by the primary action and makes recovery from an invalid bonus decision more complex.

6. Project draft state only to its owner.

   Add a caller-specific `turn_selection` field beside `turn_options`. It is `nil` when the caller has no active selection and otherwise includes action, die value, volunteer cost, required cell count, selected cells, available next cells, completion state, and bonus options when complete.

   Do not add the draft to `render_player/2`, so other players receive only committed sheet state and the existing pending or submitted status. Every accepted edit still uses the normal session broadcast, and each recipient receives a separately rendered caller projection.

   Alternative considered: expose every draft under `game.players`. It is simpler to render but leaks simultaneous players' intended moves and turns transient UI state into public game history.

7. Reject the obsolete whole-shape commands after migration.

   `plant_trees` and `rehome_koalas` remain action identifiers inside `select_turn_cell`, but they are no longer accepted as direct command events with `target_cells`. Rejecting the old payload avoids two competing mutation paths and ensures all shape actions receive the same guided validation. The existing single-cell fallback events remain accepted because they do not require shape construction.

   Alternative considered: support both contracts temporarily. There is no current Koala-specific frontend in the repository, so compatibility adds branching and test burden without a deployed consumer benefit.

## Risks / Trade-offs

- [Enumerating all transformed placements on every edit adds reducer work] -> Deduplicate transformed offsets, keep enumeration local to one small sheet, add focused performance assertions only if measured command latency becomes material.
- [Projection and command validation could disagree] -> Route both through one pure selection-options function and test that every projected available cell is accepted from the same state.
- [A partial selection could leak through generic game serialization] -> Keep external Koala rendering explicit and add projection tests proving another caller cannot observe the draft.
- [A complete draft can become stale before submission] -> Recompute and revalidate every condition during submission, then reject without partial mutation.
- [Replacing direct shape commands breaks an external prototype client] -> Treat the command and projection update as one deployable contract change and document the staged event payloads in tests.
- [Removing client-facing offsets may reduce debugging visibility] -> Keep canonical shapes and transforms available through internal `Ruleset` functions and unit tests, but do not make UI correctness depend on them.

## Migration Plan

1. Add candidate-placement and selection-option helpers with ruleset tests while retaining current dispatch behavior.
2. Extend player state, command validation, and reducer transitions for select, deselect, reset, and submit selection commands.
3. Add caller-specific selection projection and replace shape offsets in `turn_options` with shape size and each legal action's initial cells.
4. Remove direct whole-shape command acceptance and update Koala game, projection, and session tests to the staged protocol.
5. Update the paired iframe client to render projected cells, send one cell per command, and remove local shape transforms.
6. Run focused Koala tests, affected session and projection tests, client browser tests, formatting, type checks for changed projection contracts, and each repository's check command when practical.

Rollback requires reverting the backend contract and its tests together. There is no persisted state or schema migration. Active in-memory sessions should be restarted when moving between staged and whole-shape protocol versions because their player state shapes differ.

## Open Questions

- Should a later change migrate `circle_tree` and `circle_koala` to the same staged interaction for a uniform UI, or keep their simpler atomic payload permanently?
