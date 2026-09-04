## Context

The current protocol treats each primary cell edit as a game command. `select`, `deselect`, and `reset` mutate a private selection stored in `Game.players`, then publish a complete session projection. `submit` reads that stored selection and commits the turn.

The selection is not a committed game outcome. It is an ephemeral interaction draft used by one client. Placement legality, volunteer cost, completion, and bonus availability remain authoritative server rules, so moving the draft to the client must not move those calculations.

## Goals / Non-Goals

**Goals:**

- Keep the game aggregate limited to committed authoritative facts.
- Let a client evaluate a complete primary draft against current server state through the generic dispatch boundary without mutation or broadcast.
- Return enough caller-specific guidance through the game projection boundary that the client never computes placement legality.
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

### `draft` is a synchronous response from the unified dispatch path

The request payload is always complete:

```json
{
  "mark": "tree",
  "die_value": 4,
  "selected_cells": [{"area": "a", "row": 0, "column": 1}]
}
```

The success reply remains a caller-specific read model:

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

Rules exposes independent state-dependent validations and derivations without defining a combined draft analysis or response shape. `draft` validates structure through `Command`, composes those rules, and assembles the complete game-specific reply data inline in `Game.dispatch/2` without changing `Session` or `Game`. It produces no session publication.

The game dispatch contract preserves `:ok` and `:error` as its only status atoms:

```text
{:ok, updated_game}
{:ok, unchanged_game, reply}
{:error, reason}
```

The second element of every accepted result remains the game state. The three-element form adds a game-specific reply without introducing a nested result status and is valid only when the returned game is exactly the source game. `D20.Sessions.Session` propagates it as `{:ok, unchanged_session, reply}`. `D20.Sessions.Server` returns that result without storing state or broadcasting. This keeps the reply behind the existing `D20.Sessions.dispatch/3` API instead of adding another public session operation.

The shared request path is:

```text
SessionChannel generic handle_in
-> Sessions.dispatch
-> Sessions.Server current Session
-> Session.dispatch
-> Game.dispatch
-> Command and Rules
-> unchanged Session plus game-specific reply
-> D20Web.Projection.reply/3
-> KoalaRescueClub.Projection.reply/3
-> caller-only channel reply
```

The Koala engine returns `{:draft, data}`: the atom identifies the game-specific reply and `data` is the complete response map produced by the engine from the Rules result. It does not duplicate the actor id because `D20.Sessions.dispatch/3` creates the command from the caller's `Scope` and the synchronous channel reply remains correlated to that caller. The unchanged Session is passed only as routing context. `KoalaRescueClub.Projection.reply/3` trusts and returns `data` unchanged instead of filtering or rebuilding an engine-owned response.

Adding draft data to the normal session projection was rejected because that projection has no request candidate and must stay a pure render of committed state. A second public preview API and a command-specific channel clause were rejected because they duplicate authorization, OTP request, error, and reply paths. Treating the draft as a state transition was rejected because no authoritative fact changes.

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
| `available_volunteer_cost` | player sheet, roll, adjusted value | integer or reason | Rules | draft and submit | die domain before availability |
| `legal_initial_targets` | rulesheet, sheet, mark | cells | Rules | projection options, candidate validation | area and occupancy rules |
| `validate_selection_cells` | cells, shape size | ok or reason | Rules | draft and submit | cardinality before geometry |
| `compatible_shape_placements` | rulesheet, sheet, selection | placements or reason | Rules | draft and submit | cell validity before geometry |
| `classify_selection` | cells, shape size, compatible placements | readiness and resolution | Rules | draft and submit | cardinality before bonus derivation |
| `unlocked_bonuses_after_selection` | rulesheet, sheet, selection, resolution | bonus entries | Rules | Game draft reply assembly | primary resolution before unlock derivation |
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
- The dispatch callback gains an optional game-specific reply as a third element while retaining only `:ok` and `:error` status atoms. Existing engines retain their two-element results, while Session enforces unchanged state for reply-bearing results.
- A malformed or failed draft has no broadcast to carry errors. The direct channel reply carries the same stable error formatting as dispatch.
- Backend and old client are incompatible. Both artifacts must be released and rolled back together.

## Migration Plan

1. Replace the separate preview stack with the unified dispatch outcome and generic SessionChannel handler.
2. Route Koala `draft` through `Game.dispatch/2` and pass its engine-owned `{:draft, data}` reply unchanged through `Projection.reply/3`.
3. Preserve the existing draft and submit wire schemas while updating AsyncAPI descriptions and focused contract coverage.
4. Verify the separate client still correlates and consumes the unchanged draft reply shape.
5. Run focused and full checks in both repositories, then validate real UI states.
6. Deploy compatible artifacts together and restart active Koala sessions.

Rollback restores the prior backend and client artifacts together. No persisted data migration is required.

## Open Questions

None.
