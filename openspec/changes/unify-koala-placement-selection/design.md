## Context

Koala Rescue Club currently treats full-shape and one-cell primary placements as different protocols. `plant_trees` and `rehome_koalas` are selection action identifiers used by `select`, `deselect`, `reset`, and `submit`; `circle_tree` and `circle_koala` are direct commands that carry the complete turn payload. The separate Svelte client consequently keeps one-cell primary cells and their preview locally while reconciling full-shape cells from the caller-specific server selection.

The reviewed rules describe one decision with two dimensions: the player marks trees or koalas, and the accepted placement contains either one fallback cell or the complete adjusted die shape. Every supported die shape contains at least two cells, so the server can derive the placement form from the selected cell count without storing a separate action or placement mode.

D20 remains authoritative for the private primary selection, legal continuations, volunteer cost, final validation, committed sheet, bonuses, submission status, and turn advancement. The separate client may keep an ephemeral ordered bonus preview, but it must not own primary selected cells.

## Goals / Non-Goals

**Goals:**

- Model every tree or koala primary placement through one private server-owned selection.
- Make `select`, `deselect`, and `submit` the canonical edit and commit path.
- Derive one-cell fallback versus full-shape placement from the selected cell count.
- Remove the four legacy primary action identifiers from public command and projection fields.
- Store only authoritative selection facts and derive volunteer cost, completion, resolution form, legal continuations, and bonus options.
- Preserve caller privacy, reconnect recovery, atomic final resolution, simultaneous player turns, and existing rule outcomes.
- Define the complete state, transition, command, predicate, and visibility model before implementation.
- Identify the exact migration boundary for the separately delivered Koala Rescue Club client.

**Non-Goals:**

- Change shape geometry, legal tree or koala targets, volunteer rules, bonus rules, scoring, badges, automatic rolls, player membership, or game completion.
- Persist sessions or selections beyond the existing in-memory process lifetime.
- Stage ordered bonus choices as separate server commands.
- Remove `reset`; it remains an optional bulk-clear command outside the canonical cell-by-cell path.
- Redesign the separate client's map artwork, target calibration, panning, standalone mode, or general state-store architecture.

## Decisions

### Store a mark-based canonical selection

The pending player's authoritative selection becomes:

```elixir
%{
  mark: :tree | :koala,
  value: 1..6,
  cells: [cell]
}
```

`Ruleset` owns the bounded `mark` domain. `Game` stores only the chosen mark, adjusted die value, and ordered unique cells. The volunteer count is derived from the shared roll and adjusted value through `Ruleset.volunteers_needed/2`; it remains projected as guidance but is not accepted from the client or stored in the selection.

The first `select` for a context carries `mark`, `die_value`, and `target_cell`. Later `select` calls carry only `target_cell`. A full-context `select` atomically starts or replaces the current selection. A target-only `select` requires an existing selection.

Keeping all four action strings inside the selection was rejected because it preserves a transport distinction that the selected mark and cell count already determine. Storing `volunteers_used` was rejected because it is reproducible from authoritative state and immutable rules.

### Derive the placement form from cardinality

For a selection with adjusted shape size `required_cells`:

- one selected cell is a submit-ready `single` fallback;
- two through `required_cells - 1` cells are an incomplete shape prefix;
- exactly `required_cells` cells are a submit-ready `shape`;
- more than `required_cells` cells are rejected.

A one-cell selection may be both submit-ready and extendable. Its `available_cells` contains only cells that continue at least one legal full-shape placement containing the selected cell. A legal one-cell target that belongs to no legal full shape remains submit-ready with no continuations.

The minimum shape size of two is a static invariant covered by `Ruleset` tests. Adding an explicit `single | shape` mode was rejected because it would store redundant intent and make the player choose before the selected facts require that distinction.

### Project mark choices and derived selection guidance

Each reachable adjusted die option changes from:

```text
actions.plant_trees
actions.rehome_koalas
actions.circle_tree
actions.circle_koala
```

to:

```text
marks.tree
marks.koala
```

Each mark option exposes legal initial cells. Because every legal full-shape cell is also a legal one-cell target for the same mark, the initial set can use the legal fallback targets. After the first selection the server projects only compatible shape continuations.

The caller-specific selection exposes:

```text
mark
die_value
volunteers_used
required_cells
selected_cells
available_cells
submit_ready
resolution: single | shape | null
bonus_options
```

`volunteers_used`, `required_cells`, `available_cells`, `submit_ready`, `resolution`, and `bonus_options` are derived read-model fields. `available_cells` may be non-empty while `submit_ready` is true for an extendable one-cell selection. Bonus options are present only for the currently submit-ready primary result.

Retaining action-keyed options was rejected because it would force the client to preserve the obsolete four-way model even after command unification.

### Commit every primary result through submit

`submit` revalidates the complete selection against the current committed sheet and shared roll, derives the volunteer cost and primary resolution, applies the primary marks, applies the ordered `bonus_actions`, resolves omitted bonuses, records the adjusted die value, clears the selection, and marks the player submitted in one atomic transition.

An invalid or intermediate selection returns a stable error and leaves both the committed sheet and selection unchanged. Selection edits never spend volunteers, change the sheet, resolve bonuses, record turn history, or change player status.

`circle_tree` and `circle_koala` are removed from `Command`, `Game`, `Rules`, and AsyncAPI as command events. Supporting both old and new mutation paths was rejected because it would preserve competing commit boundaries and make client migration errors silent.

### Keep reset as a bulk edit, not a commit path

`deselect` removes one selected cell. Removing the last cell clears the selection entirely. `reset` clears the selection in one command and remains useful for the existing Reset control and multi-cell drafts. Neither command affects committed facts.

Removing `reset` was rejected because reproducing a bulk clear with sequential network calls would introduce avoidable broadcasts and partial intermediate drafts. Its presence does not change the canonical `select -> deselect -> submit` ownership or commit boundary.

### Reconcile the separate client only from server primary selection

The separate `ravecat/koala-rescue-club` client currently has an implemented but uncommitted `centralize-client-state-machine` change. Its current state model deliberately stores one-cell primary selection locally and switches final calls between `submit`, `circle_tree`, and `circle_koala`.

The coordinated client migration must:

- replace public `PrimaryAction` and action-keyed option types with `tree | koala` mark types and mark-keyed options;
- remove `SingleTurnPayload`, `circleTree`, and `circleKoala` from the SDK command port and processing/error maps;
- send every primary target activation through `select` or `deselect`;
- reconcile one-cell and shape cells from the authoritative `selection`;
- remove `selectedSingleAction`, local primary `selectedCells`, `selectSinglePrimary`, and the final command switch;
- make Confirm always call `submit`;
- retain only local ordered bonus preview and other presentation state;
- replace the three-way Plant, Rehome, and combined-single control with mark choices while preserving native semantics, map target accessibility, both sheet calibrations, and retry behavior;
- update server-shaped fixtures and focused store and component browser tests.

The D20 repository does not edit the separate client. Its implementation requires a linked client issue and repo-local OpenSpec change before source edits.

### Preserve one-way runtime flow

Every accepted interaction continues through:

```text
client stimulus
-> SessionChannel
-> Sessions.dispatch
-> Game.dispatch
-> Command and Rules
-> committed aggregate
-> caller-specific Projection
-> client reconciliation and render
```

Projection never constructs commands or changes the aggregate. The custom game server continues to own only automatic roll scheduling.

## Authoritative State Model

### State dimensions

| Dimension | Domain | Authoritative source | Changes through | Stored or derived |
| --- | --- | --- | --- | --- |
| Outer session phase | `waiting_for_players`, `in_progress`, `finished` | `D20.Sessions.Session` | join, leave, start, game completion | Stored |
| Game phase | `setup`, `ready`, `roll`, `submit`, `finished` | `Game.phase` | join, leave, start, automatic roll, all-player submission | Stored |
| Player status | `ready`, `pending`, `submitted` | `Game.players[id].status` | start, roll, accepted submit, next turn | Stored |
| Shared roll | `nil` or `1..6` | `Game.roll` | automatic roll, next turn | Stored |
| Primary selection | `nil` or `{mark, value, cells}` | Pending player record | select, deselect, reset, accepted submit, next turn | Stored |
| Selection class | empty, single extendable, single final, shape partial, shape ready | `Rules` | Derived from selection, rulesheet, and committed sheet | Derived |
| Volunteer cost | non-negative integer | `Ruleset.volunteers_needed/2` | Shared roll or adjusted value changes | Derived |
| Legal continuations and bonus options | bounded collections | `Rules` | Selection or committed sheet changes | Derived |
| Ordered bonus preview | zero or more bonus actions | Separate client | local bonus interaction until submit | Client-only |

### Reachable composite states

| State ID | Dimension values and authoritative facts | Invariants | Entry sources | Allowed stimuli | Terminal |
| --- | --- | --- | --- | --- | --- |
| `G_SETUP` | Waiting session, game `setup`, no active roll | Player count is below the start range | Creation, last setup player leaves | join, left | No |
| `G_READY` | Waiting session, game `ready`, joined players ready | Player count is startable, selections are nil | join or left refresh | join, left, owner start | No |
| `G_ROLL` | In-progress session, game `roll`, players ready, roll nil | Selection is nil for every player | start or completed non-final turn | actorless roll, in-progress join or left no-op | No |
| `G_SUBMIT` | In-progress session, game `submit`, roll present | At least one player is pending; every player is in one participant substate below | automatic roll or another player's accepted submit | pending-player selection commands, in-progress join or left no-op | No |
| `G_FINISHED` | Finished session and game, scores present | Every player submitted the final turn; selections are nil | Last final-turn submit | none accepted | Yes |
| `P_EMPTY` | Pending player, selection nil | No private primary cells exist | roll, reset, last-cell deselect | full-context select | No |
| `P_SINGLE_EXTENDABLE` | Pending player, one selected cell, at least one legal shape continuation | `submit_ready = true`, `resolution = single` | valid first select or deselect from a larger draft | select continuation, deselect, reset, submit, context replacement | No |
| `P_SINGLE_FINAL` | Pending player, one selected cell, no legal shape continuation | `submit_ready = true`, `resolution = single` | valid first select | deselect, reset, submit, context replacement | No |
| `P_SHAPE_PARTIAL` | Pending player, selected count from two through shape size minus one | All cells are a subset of at least one legal full placement; `submit_ready = false` | valid continuation or deselect | select continuation, deselect, reset, context replacement | No |
| `P_SHAPE_READY` | Pending player, selected count equals shape size | Cells equal one legal full placement; `submit_ready = true`, `resolution = shape` | valid continuation | deselect, reset, submit, context replacement | No |
| `P_SUBMITTED` | Submitted player, selection nil | Committed sheet includes exactly one accepted primary result and its bonuses for the turn | accepted submit | in-progress join or left no-op | No |

`G_SUBMIT` composes one participant substate per frozen game player. The all-submitted combination is not externally stored: the last accepted submit synchronously advances to `G_ROLL` or `G_FINISHED`.

### Unreachable combinations

| Combination | Justification |
| --- | --- |
| Waiting session with game `roll`, `submit`, or `finished` | Outer start and completion transitions update the nested game lifecycle atomically |
| In-progress session with game `setup` or `ready` | Owner start moves the game to `roll` before the in-progress state is published |
| Submitted player with a non-nil selection | Accepted submit clears the selection in the same transition |
| Ready player with a non-nil selection | Start, next-turn setup, and status resets clear selections |
| Selection with zero cells | Last-cell deselect and reset normalize it to nil |
| Selection with more cells than the adjusted shape size | Selection analysis rejects the triggering select |
| Multi-cell selection not contained in a legal full shape | Every accepted continuation preserves the compatible-placement invariant |
| One-cell shape resolution | Every supported shape has at least two cells, so one cell always classifies as fallback |
| Finished game with pending or submitted-turn selection | Final resolution clears selections and publishes terminal scores atomically |

## Transition Table

| Source state ID | Stimulus | Required predicates | Atomic effects | Resulting state ID | Stable errors |
| --- | --- | --- | --- | --- | --- |
| `G_SETUP`, `G_READY` | join | Valid actor and player count | Add idempotent player and refresh phase | `G_SETUP` or `G_READY` | `invalid_identity`, `invalid_player_count` |
| `G_SETUP`, `G_READY` | left | Existing or absent actor id | Remove player and refresh phase | `G_SETUP` or `G_READY` | None |
| `G_READY` | start | Session owner, valid actor, startable roster | Freeze mode, set turn 1, clear selections | `G_ROLL` | `invalid_identity`, `invalid_player_count`, `invalid_phase` |
| `G_ROLL` | actorless roll | Missing actor, missing existing roll | Sample and store one roll, set players pending | `G_SUBMIT` with every player `P_EMPTY` | `invalid_identity`, `roll_already_exists`, `invalid_phase` |
| `P_EMPTY` | full-context select | Pending actor, reachable die value, legal mark target | Store canonical one-cell selection | `P_SINGLE_EXTENDABLE` or `P_SINGLE_FINAL` | `missing_roll`, `invalid_die_value`, `insufficient_volunteers`, `invalid_target` |
| Any pending selection state | full-context select | Valid replacement context and target | Replace prior selection atomically | `P_SINGLE_EXTENDABLE` or `P_SINGLE_FINAL` | Same as first select |
| `P_SINGLE_EXTENDABLE`, `P_SHAPE_PARTIAL` | target-only select | Target continues at least one compatible legal shape | Append one unique cell | `P_SHAPE_PARTIAL` or `P_SHAPE_READY` | `missing_turn_selection`, `invalid_target` |
| Any pending selection state | select existing cell | Cell is already selected | Preserve the selection | Same source | None |
| Any pending selection state | deselect selected cell | Existing selection | Remove cell; normalize zero cells to nil | `P_EMPTY`, `P_SINGLE_EXTENDABLE`, `P_SINGLE_FINAL`, or `P_SHAPE_PARTIAL` | `missing_turn_selection` |
| Any pending selection state | deselect absent cell | Existing selection | Preserve the selection | Same source | None |
| Any pending state | reset | Pending actor | Clear selection only | `P_EMPTY` | Identity, phase, or player-status errors |
| `P_SINGLE_EXTENDABLE`, `P_SINGLE_FINAL` | submit | Revalidated legal fallback and valid ordered bonuses | Derive cost, mark one cell, apply bonuses, record value, clear selection, mark submitted | `P_SUBMITTED`, `G_ROLL`, or `G_FINISHED` | Current target, volunteer, bonus, or stale-state error |
| `P_SHAPE_READY` | submit | Revalidated legal full shape and valid ordered bonuses | Derive cost, mark full shape, apply bonuses, record value, clear selection, mark submitted | `P_SUBMITTED`, `G_ROLL`, or `G_FINISHED` | Current shape, volunteer, bonus, or stale-state error |
| `P_EMPTY`, `P_SHAPE_PARTIAL` | submit | Selection is missing or not submit-ready | No effect | Same source | `missing_turn_selection`, `incomplete_turn_selection` |
| Any state | `circle_tree` or `circle_koala` | None | No effect | Same source | Unsupported command |
| `G_FINISHED` | any command | None | No effect | `G_FINISHED` | `finished` |

Every rejected transition preserves the complete source aggregate and produces no session publication.

## Command Table

| Event | Actor class | Payload | Allowed source states | State-changing | Stable errors |
| --- | --- | --- | --- | --- | --- |
| `join` | Authenticated actor | Empty | `G_SETUP`, `G_READY` | Yes | Identity and player-count errors |
| `left` | Authenticated actor | Empty | `G_SETUP`, `G_READY`; no-op during play | Sometimes | Phase-independent no-op during play |
| `start` | Authenticated owner | Empty | `G_READY` | Yes | Identity, readiness, and outer authorization errors |
| `roll` | Actorless server | Empty | `G_ROLL` | Yes | Identity, phase, duplicate-roll errors |
| `select` | Pending player | First or replacement: `{mark, die_value, target_cell}`; continuation: `{target_cell}` | `P_EMPTY` or any pending selection state | Yes when selection changes | Malformed payload, invalid mark, missing context, die, volunteer, target, phase, or status errors |
| `deselect` | Pending player | `{target_cell}` | Any pending selection state | Yes when selected cell exists | Malformed payload, missing selection, target, phase, or status errors |
| `reset` | Pending player | Empty | Any pending state | Yes when selection exists | Non-empty payload, phase, or status errors |
| `submit` | Pending player | `{bonus_actions}` | `P_SINGLE_EXTENDABLE`, `P_SINGLE_FINAL`, `P_SHAPE_READY` | Yes | Malformed bonus payload, missing or incomplete selection, stale primary, volunteer, or bonus errors |

`plant_trees`, `rehome_koalas`, `circle_tree`, and `circle_koala` are not command events in the resulting protocol.

## Predicate Catalog

| Predicate | Inputs | Result | Owner | Consumers | Failure precedence |
| --- | --- | --- | --- | --- | --- |
| `submit_allowed?` | Game, actor id | Boolean | `Rules` | Permission, Projection | Phase, player, status, roll |
| `pending_player` | Game, actor id | Player and rulesheet or error | `Rules` | All selection transitions | Phase, roll, membership, status |
| `volunteer_cost` | Shared roll, adjusted value | Cost or die error | `Ruleset` | Rules, Projection | Die domain before availability |
| `legal_initial_targets` | Rulesheet, sheet, mark | Cells | `Rules` | Turn options, first select validation | Accessible area and mark occupancy |
| `compatible_shape_placements` | Rulesheet, sheet, mark, value, selected cells | Placements | `Rules` | Select, deselect, selection projection | Static shape, area, mark occupancy |
| `classify_selection` | Selection, compatible placements, shape size | Single, partial, shape, or error | `Rules` | Submit validation, Projection | Cardinality before bonus derivation |
| `legal_continuations` | Selection and compatible placements | Cells | `Rules` | Projection, next select validation | Only compatible unique cells |
| `selection_bonus_options` | Original sheet and submit-ready classified result | Bonus entries | `Rules` | Projection | Primary candidate must be valid first |
| `resolve_primary_candidate` | Rulesheet, committed sheet, classified selection | Candidate sheet or error | `Rules` | Submit | Mark target, shape, area, occupancy |
| `apply_bonus_actions` | Rulesheet, original sheet, candidate sheet, ordered actions | Candidate sheet or error | `Rules` | Submit | Primary succeeds before any bonus |
| `turn_complete?` | Frozen players map | Boolean | `Rules` | Game | All player statuses submitted |

## Visibility Matrix

| Caller role and lifecycle | Visible selection | Visible choices and guidance | Hidden facts | Authoritative sources |
| --- | --- | --- | --- | --- |
| Waiting owner | None | Start permission and existing setup projection | Any future turn draft | Session, Game, Permission |
| Waiting participant or non-owner | None | Setup state without owner action | Any future turn draft | Session, Game, Permission |
| Pending player viewing self | Own full selection projection, or nil | Mark-keyed options, derived cost, legal continuations, submit readiness, resolution, bonus options, permission | Every other player's selection | Game selection, Ruleset, Rules, caller context |
| Pending player viewing another player | None | Public committed sheet and status only | Own draft in the other-player view and all other private drafts | Game, caller context |
| Submitted player | None | Waiting status and public committed sheets | Pending players' selections | Game, caller context |
| Spectator or non-member | None | Permitted public session and committed game fields | Every private selection and caller-only legal choices | Session, Game, caller context |
| Finished caller | None | Final committed sheets, scores, ranks, badges, rounds, and results | Historical drafts and forfeited local bonus preview | Game terminal state |

Every projected field is reproducible from current committed game state, immutable rules, and caller and session context. The separate client's local bonus preview is not projected and is never treated as authoritative.

## Risks / Trade-offs

- [A one-cell selection is both complete and extendable] -> Replace the old overloaded `complete` semantics with explicit `submit_ready` and `resolution`, and test that continuations remain available.
- [A future ruleset adds a one-cell die shape] -> Make the minimum shape size of two an explicit static invariant and fail ruleset validation or tests before the classification becomes ambiguous.
- [Removing action-keyed options breaks the separate client broadly] -> Treat backend, AsyncAPI, client types, command port, state reducer, controls, fixtures, and browser tests as one coordinated contract release.
- [The client has overlapping uncommitted state-machine work] -> Base the client migration on its current working state, preserve those user changes, and create a separate tracked client change before editing.
- [Old and new deployments cannot interoperate] -> Deploy backend and client together, restart active in-memory sessions, and roll both artifacts back together if validation fails.
- [Primary selection survives reconnect but local bonus ordering does not] -> Keep this existing boundary explicit; reconnect restores the submit-ready primary and legal bonus options, while the player rebuilds any unsubmitted bonus ordering.
- [Reset keeps a fourth editing command] -> Document it only as an optional bulk-clear convenience and ensure it has no separate commit semantics.

## Migration Plan

1. Add focused Ruleset, Rules, and aggregate tests for the mark domain, minimum shape size, one-cell readiness with continuations, partial shapes, full shapes, replacement, deselection, reset, and atomic submission.
2. Change the canonical selection, command payloads, Rules predicates, aggregate transitions, and caller projection together.
3. Remove direct single-cell command routing and update command, server, session, channel, and projection tests.
4. Update `priv/specs/koala-rescue-club.yaml` to the mark-based options and selection schema and remove direct `circle_*` messages.
5. Create and execute a linked repo-local issue and OpenSpec change in `ravecat/koala-rescue-club`, preserving the current centralized client-state work while migrating the affected files identified above.
6. Run focused backend and client checks, full backend tests, client browser tests, client production build, strict OpenSpec validation, and cross-boundary contract assertions.
7. Deploy the coordinated backend and client versions and restart active Koala Rescue Club sessions.

Rollback restores the previous backend contract and separate client version together, then restarts active sessions. No persisted data or database schema requires rollback.

## Open Questions

None.
