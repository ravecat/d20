## Context

The current protocol treats each primary cell edit as a game command. `select`, `deselect`, and `reset` mutate a private selection stored in `Game.players`, then publish a complete session projection. `submit` reads that stored selection and commits the turn.

The selection is not a committed game outcome. It is an ephemeral interaction draft used by one client. Placement legality, volunteer cost, completion, and bonus availability remain authoritative server rules, so moving the draft to the client must not move those calculations.

## Goals / Non-Goals

**Goals:**

- Keep the game aggregate limited to committed authoritative facts.
- Let a client evaluate a complete primary draft against current server state without mutation or broadcast.
- Return enough caller-specific guidance that the client never computes placement legality.
- Revalidate and commit the complete turn atomically through `submit`.
- Remove all staged cell-edit commands and the normal projected selection.
- Define state, transition, command, predicate, and visibility models before runtime edits.

**Non-Goals:**

- Change shape geometry, placement rules, volunteer rules, bonuses, scoring, badges, rolls, membership, or completion.
- Persist an unsubmitted draft across reconnect or process restart.
- Store ordered bonus choices on the server before submit.
- Turn normal projection rendering into a request handler.
- Change calibrated client artwork or target geometry.

## Decisions

### The client owns the ephemeral primary draft

The client's root state machine stores:

```text
mark
die_value
selected_cells
last accepted draft preview
ordered bonus preview
```

This state exists only for the current connection and pending turn. Changing mark or die value clears selected cells and preview. Reconnect, a new turn, or loss of pending status clears the draft. The client may update selected cells optimistically for responsiveness, but it cannot declare a candidate legal.

Keeping the draft in `Game` was rejected because every click became an authoritative mutation even though no shared game fact changed.

### `draft` is a synchronous stateless preview request

The request payload is always complete:

```json
{
  "mark": "tree",
  "die_value": 4,
  "selected_cells": [{"area": "a", "row": 0, "column": 1}]
}
```

The success reply is a caller-specific read model:

```json
{
  "mark": "tree",
  "die_value": 4,
  "selected_cells": [{"area": "a", "row": 0, "column": 1}],
  "available_cells": [{"area": "a", "row": 0, "column": 2}],
  "required_cells": 3,
  "volunteers_used": 0,
  "submit_ready": true,
  "resolution": "single",
  "bonus_options": []
}
```

Actual arrays and values are derived by Rules. `draft` validates structure through `Command`, validates caller and current-state legality through `Rules`, and returns a value without changing `Session` or `Game`. It produces no session publication.

The shared read path is:

```text
SessionChannel draft
-> Sessions.preview
-> Game.Server current Session
-> Session.preview
-> Game.preview
-> Command and Rules
-> caller-only reply
```

Adding draft data to the normal projection was rejected because projection cannot receive a client candidate and must stay a pure render of committed state. Sending `draft` through normal mutation dispatch was rejected because accepted dispatches publish state and require an aggregate transition.

### `submit` carries and commits the complete candidate

`submit` carries `mark`, `die_value`, `selected_cells`, and ordered `bonus_actions`. The server validates the complete payload, resolves the primary candidate once against the current aggregate, validates and applies bonuses, spends volunteers, records the die value, and changes player status in one transition.

No intermediate candidate is committed. Any structural, stale, primary, or bonus error preserves the complete source aggregate and publishes nothing.

This makes retry and stale-client behavior explicit: a preview is guidance, while submit is always revalidated authority.

### Normal projection contains only committed facts and initial guidance

The pending player's normal projection retains mark-keyed `options` for each reachable adjusted die value. These options include legal initial cells and are derived from current committed state. The projection does not contain `selection`.

The draft reply contains candidate-specific guidance and is returned only to the requesting caller. Other players and spectators never receive it.

### Removed command vocabulary

The public primary workflow contains:

- `draft` as a non-mutating request.
- `submit` as the only primary state-changing command.

`select`, `deselect`, `reset`, `plant_trees`, `rehome_koalas`, `circle_tree`, and `circle_koala` are unsupported. Selection and deselection are local edits, not domain commands.

### Ruleset ownership remains static

`Ruleset` owns marks, die shapes, board references, and sheet-specific hospital identifiers. `Command` validates hospital identifiers as non-empty strings. Rules resolve them against the current player's selected sheet without creating transport-controlled atoms.

## Authoritative State Model

### State dimensions

| Dimension | Finite domain or bounded shape | Authoritative source | What changes it | Classification |
| --- | --- | --- | --- | --- |
| Outer session phase | `waiting_for_players`, `in_progress`, `finished` | `Session.phase` | session lifecycle | Committed |
| Game phase | `setup`, `ready`, `roll`, `submit`, `finished` | `Game.phase` | accepted game transitions | Committed |
| Players | bounded id-keyed records | `Game.players` | join and setup leave | Committed |
| Player status | `ready`, `pending`, `submitted` | player record | start, roll, submit, next turn | Committed |
| Player sheet and volunteers | rulesheet state | player record | accepted submit | Committed |
| Shared roll | `nil` or `1..6` | `Game.roll` | automatic roll and next turn | Committed |
| Turn history and scores | bounded values | game and player records | accepted submit and completion | Committed |
| Initial mark options | bounded map | Rules from game, actor, ruleset | never stored | Derived projection |
| Primary draft and preview | bounded candidate and reply | requesting client | local edits and draft replies | Client-only |

There is no primary selection dimension in the aggregate.

### Reachable composite states

| State ID | Dimension values | Authoritative facts and invariants | Entry sources | Allowed stimuli | Terminal |
| --- | --- | --- | --- | --- | --- |
| `G_SETUP` | Waiting session, game `setup` | roster below startable range, roll nil | creation or setup leave | join, left | No |
| `G_READY` | Waiting session, game `ready` | startable roster, roll nil, players ready | setup join or left | join, left, owner start | No |
| `G_ROLL` | In-progress session, game `roll` | players ready, roll nil | start or completed non-final turn | actorless roll, in-progress presence no-op | No |
| `G_SUBMIT_PENDING` | In-progress session, game `submit` | roll present and at least one pending player | automatic roll or another submit | pending caller draft or submit, presence no-op | No |
| `G_SUBMIT_MIXED` | In-progress session, game `submit` | roll present, pending and submitted players coexist | non-final player's submit | remaining caller draft or submit, presence no-op | No |
| `G_FINISHED` | Finished session, game `finished` | final scores committed, no pending player | last final-turn submit | reads only | Yes |

The all-submitted combination is not externally stored. The last accepted submit synchronously advances to `G_ROLL` or `G_FINISHED`.

### Unreachable combinations

| Combination | Justification |
| --- | --- |
| Waiting session with game `roll`, `submit`, or `finished` | outer start and game start are committed together |
| In-progress session with game `setup` or `ready` | start moves the game to `roll` before publication |
| Game `submit` with roll nil | only the automatic roll enters submit |
| Pending player outside game `submit` | start and next-turn reset use ready, roll uses pending |
| Authoritative player selection or draft | the aggregate type has no such field |
| Finished game with pending players | last submit completes synchronously |

## Transition Table

| Source state ID | Stimulus | Required predicates | Atomic effects | Result state ID | Stable errors |
| --- | --- | --- | --- | --- | --- |
| `G_SETUP`, `G_READY` | join | valid actor and player count | add idempotent player, refresh setup phase | `G_SETUP` or `G_READY` | `invalid_identity`, `invalid_player_count` |
| `G_SETUP`, `G_READY` | left | setup membership rules | remove player, refresh setup phase | `G_SETUP` or `G_READY` | none |
| `G_READY` | start | owner at Session layer, startable roster, valid sheets | initialize turn facts | `G_ROLL` | `invalid_phase`, `not_ready` |
| `G_ROLL` | actorless roll | system actor, valid generated die | commit roll, mark players pending | `G_SUBMIT_PENDING` | `invalid_actor`, `invalid_roll` |
| `G_SUBMIT_PENDING`, `G_SUBMIT_MIXED` | draft request | caller is pending, complete candidate is structurally and legally valid | return derived reply only, no atomic effect | same source state | command or rule reason |
| `G_SUBMIT_PENDING`, `G_SUBMIT_MIXED` | submit | caller is pending, complete candidate and bonuses legal | atomically apply full turn and mark caller submitted | `G_SUBMIT_MIXED`, `G_ROLL`, or `G_FINISHED` | command or rule reason |
| Any state | rejected stimulus | first applicable predicate fails | none | same source state | stable reason |

## Command and Request Table

| Event | Actor class | Payload | Allowed source state IDs | State-changing | Stable errors |
| --- | --- | --- | --- | --- | --- |
| join | authenticated member | empty | `G_SETUP`, `G_READY` | Yes | identity and roster errors |
| left | Presence actor id | empty | all non-terminal states | setup only | none |
| start | authenticated owner | rulesheet selections | `G_READY` | Yes | structural, owner, readiness errors |
| roll | actorless server | generated die value | `G_ROLL` | Yes | actor and die errors |
| draft | authenticated pending player | `mark`, `die_value`, non-empty unique `selected_cells` | `G_SUBMIT_PENDING`, `G_SUBMIT_MIXED` | No | structural, membership, status, target, shape, die errors |
| submit | authenticated pending player | complete draft plus ordered `bonus_actions` | `G_SUBMIT_PENDING`, `G_SUBMIT_MIXED` | Yes | structural, membership, status, stale candidate, primary and bonus errors |

`select`, `deselect`, `reset`, `plant_trees`, `rehome_koalas`, `circle_tree`, and `circle_koala` do not exist in the resulting protocol.

## Predicate Catalog

| Predicate | Inputs | Return shape | Owner | Consumers | Failure precedence |
| --- | --- | --- | --- | --- | --- |
| `pending_player` | game, actor id | player and rulesheet or reason | Rules | draft, submit, permission, options | phase, roll, membership, status |
| `volunteer_cost` | roll, adjusted value | integer or reason | Ruleset | draft, submit, options | die domain before availability |
| `legal_initial_targets` | rulesheet, sheet, mark, value | cells | Rules | projection options, candidate evaluation | area and occupancy rules |
| `compatible_shape_placements` | rulesheet, sheet, mark, value, cells | placements | Rules | candidate evaluation | cell validity before geometry |
| `classify_candidate` | cells, shape size, compatible placements | `single`, `partial`, `shape`, or reason | Rules | draft and submit | cardinality before bonus derivation |
| `draft_details` | game, actor id, candidate | reply or reason | Rules | Game preview and submit preparation | pending player, die, cells, placement |
| `apply_bonus_actions` | candidate player, ordered actions | player or reason | Rules | submit preparation | unlock order and target legality |
| `turn_complete?` | game players | boolean | Rules | Game | after accepted submit only |

## Visibility Matrix

| Caller role | Lifecycle state | Visible fields | Hidden fields | Derived fields | Sources |
| --- | --- | --- | --- | --- | --- |
| Owner or member | waiting | public session, roster, permissions, own setup form when allowed | internal aggregate | start guidance | Session, Permission, Ruleset |
| Pending player | submit normal projection | public session, committed sheets, roll, statuses, own options | draft, other private interaction state, internal representation | permissions, initial legal cells, scores | Game, Rules, Ruleset, caller |
| Pending player | successful draft reply | only own complete candidate guidance | all other players' candidates and internal aggregate | available cells, required cells, cost, readiness, resolution, bonus options | current Game, Rules, Ruleset, caller request |
| Submitted player | submit | public committed state and empty own options | pending player's draft replies | permissions and scores | Game, Rules, caller |
| Spectator or non-member | any | permitted public committed state | all draft replies and private setup inputs | read permissions and scores | Session, Game, Permission |
| Any caller | finished | final committed sheets, scores, results, permissions | all drafts | outcomes | Game, Rules |

Every normal projected field traces to committed state, immutable rules, or caller/session context. Every draft reply additionally traces to the explicit request candidate and is never retained by Projection.

## Client Reconciliation

The client machine keys a request by mark, die value, ordered cells, and turn epoch. It accepts a preview reply only for the current key and epoch. A failed preview rolls local cells back to the last accepted preview. Explicit drafting and submitting machine states disable competing player events while a command is pending.

On reconnect the client receives no server draft. It resets local primary and bonus state and starts again from normal projected options. On successful submit, the next normal projection changes status or turn and clears local draft state.

## Risks / Trade-offs

- A reconnect loses unsubmitted work. This is intentional because the draft is presentation state.
- A preview can become stale before submit. Full submit revalidation preserves authority and atomicity.
- A shared preview callback expands the D20 engine contract. A default unsupported implementation preserves existing engines.
- A malformed or failed draft has no broadcast to carry errors. The direct channel reply carries the same stable error formatting as dispatch.
- Backend and old client are incompatible. Both artifacts must be released and rolled back together.

## Migration Plan

1. Add and test the shared synchronous preview boundary with a default unsupported engine implementation.
2. Replace Koala staged commands and aggregate selection with `draft` preview and full `submit`.
3. Remove `selection` from normal projection and update AsyncAPI.
4. Move primary draft ownership into the separate client and consume draft replies.
5. Run focused and full checks in both repositories, then validate real UI states.
6. Deploy both artifacts together and restart active Koala sessions.

Rollback restores the prior backend and client artifacts together. No persisted data migration is required.

## Open Questions

None.
