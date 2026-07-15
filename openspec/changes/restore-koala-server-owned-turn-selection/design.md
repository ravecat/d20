## Context

Koala shape selection is currently client-owned. Every cell change sends a complete `project_turn_selection` draft to a Koala-specific clause in the generic Phoenix channel, which reads a session snapshot and invokes event-specific projection code without dispatching to the session process. This avoids game mutation and broadcast, but it makes the shell know one game's interaction event, places rule-dependent validation in projection code, loses unfinished work on reconnect, and duplicates parts of submission validation.

The earlier server-owned workflow already demonstrated that a player selection can remain separate from the committed sheet while living inside the in-memory game aggregate. The current generic `Sessions.dispatch/3` and `D20.Game.Server` path serializes commands and broadcasts regular caller-specific projections, so no new runtime protocol is necessary.

Confirmed turn history currently stores `%{turn, die_value, action}` records even though chronological list order already identifies the accepted turn and no game rule consumes the recorded action. `Game` also repeats literal round and turn ranges that are static ruleset facts.

## Goals / Non-Goals

**Goals:**

- Keep `D20Web.SessionChannel` game-agnostic and route every Koala interaction through the existing dispatch path.
- Make the session process the single owner of each pending player's unfinished shape selection.
- Keep selection edits separate from committed sheet changes, volunteer spending, and submission status.
- Keep legality in `Rules` and use regular caller-specific rendering to derive selection details.
- Preserve atomic final turn resolution and private selection visibility.
- Reduce confirmed turn history to accepted adjusted die values.
- Make `Ruleset` the source of static round, active-turn, and die-value types.

**Non-Goals:**

- Persisting game sessions or selections outside the existing in-memory session process.
- Avoiding the normal session broadcast caused by an accepted selection command.
- Changing board geometry, action legality, bonus resolution, scoring, badges, roll scheduling, or player count.
- Adding a generic read-only game-query protocol to `D20.Sessions`.
- Retaining compatibility aliases for `project_turn_selection` or its payload and reply.

## Decisions

### Store only the canonical unfinished selection in `Game`

Each player will have `selection: nil | selection` with this canonical internal shape:

```elixir
%{
  action: String.t(),
  value: Ruleset.die_value(),
  volunteers: non_neg_integer(),
  cells: [Ruleset.cell()]
}
```

The stored value is authoritative workflow state for the pending player but does not alter the committed sheet. `cells` remains ordered and unique.

`required_cells`, `available_cells`, `complete`, and `bonus_options` remain derived values and will not be stored. The selection is cleared when the player submits successfully and whenever the game initializes player state for a new game or turn. A failed selection edit or failed submission leaves the prior selection unchanged.

Treating a private draft as game state is intentional: an aggregate may own an unfinished workflow without treating it as a committed board action. Caller-specific projection, rather than storage location, enforces privacy.

Alternative considered: keep the draft in the client and add a generic query capability to the runtime. This was rejected because the existing command path already provides serialization, reconnect recovery, and projection publication, while a new query protocol would add shell complexity for disposable preview traffic.

### Use `select`, `deselect`, and `reset` as ordinary game events

`select` requires `target_cell`. When no compatible stored selection exists, the wire payload also requires `action`, `die_value`, and `volunteers_used`; `Command` normalizes that context to stored `action`, `value`, and `volunteers`. Later `select` events may send only `target_cell`. Supplying a different complete context replaces the previous selection before adding the target. Selecting an already selected cell succeeds without changing state.

`deselect` requires `target_cell`, removes it from stored `cells` when present, and otherwise succeeds without changing the selection. Removing the final cell retains the selection context with an empty `cells` list. `reset` accepts an empty payload and clears the complete selection context.

`Command` normalizes wire payloads. `Rules` verifies phase, identity, player status, volunteer affordability, cell existence, uniqueness, and compatibility with at least one legal placement before returning an updated player. `Game` applies the validated player update. All three events use `Sessions.dispatch/3`, the existing game server call, and the normal broadcast path.

Alternative considered: send a complete replacement draft with one `set_selection` event. This is simpler and idempotent at the transport boundary, but it makes the client authoritative for reconstructing every intermediate state and does not match the agreed incremental event vocabulary.

### Derive selection details during regular caller-specific rendering

`Projection.render/2` will include top-level `selection` alongside `options`. It will ask `Rules` for legal option and selection analysis, then map that result into the public representation. `Rules` owns placement filtering, completion, action simulation, and unlocked bonus calculation; projection code owns only caller-specific field assembly and rendering.

The selection owner receives the stored context plus `required_cells`, normalized `selected_cells`, legal `available_cells`, `complete`, and `bonus_options`. Projection maps internal `value`, `volunteers`, and `cells` to the existing public `die_value`, `volunteers_used`, and `selected_cells` fields. Other callers receive no selection, and player entries under the shared game projection never expose another player's stored selection.

The special `project_turn_selection` channel clause and `D20Web.Projection.render_event/4` are removed. A successful selection event first receives the normal command reply and then the regular session projection produced by the broadcast.

### Submit the stored selection atomically

`submit_turn_selection` carries only ordered `bonus_actions`. `Rules` requires a stored complete selection and revalidates it against the current game before spending volunteers, applying the primary action, resolving bonuses, marking the player submitted, and clearing the selection in one transition.

The server does not treat earlier selection validation as a reservation. A failed submit preserves the committed sheet, player status, volunteer slots, and staged selection so the caller can correct bonus decisions or continue editing.

### Store confirmed turns as adjusted die values

`player.turns` becomes an ordered list of accepted adjusted die values. Every successfully submitted shape or single-cell primary action appends its `die_value`; rejected commands append nothing. List position already preserves chronological order, while action history is not consumed by rules or scoring.

The `turn_result` type and `%{turn, die_value, action}` records are removed. Regular projections and AsyncAPI expose `turns` as an array of integers from 1 through 6.

### Keep static scalar domains in `Ruleset`

`Ruleset` will expose `round`, `turn`, and `die_value` types for the static domains `1..2`, `1..30`, and `1..6`. `Game`, `Rules`, and `Projection` will reference these types instead of repeating literal ranges.

The game state's pre-start `turn: 0` is a lifecycle sentinel rather than a legal ruleset turn, so its state type remains `0 | Ruleset.turn()`. This preserves runtime behavior while keeping the active-turn range owned by `Ruleset`.

## Risks / Trade-offs

- [Every accepted cell edit broadcasts a session update to all subscribers] -> Keep selection caller-private in projection, rely on the small session and board sizes, and cover non-disclosure in channel and projection tests.
- [Multiple clients for one actor can edit the same selection] -> Serialize all events in the session process; the latest accepted command becomes authoritative and every connected client receives the resulting projection.
- [Projection and submission legality can drift] -> Make both paths consume the same `Rules` analysis and transition helpers and cover equivalent valid and invalid selections.
- [Active sessions have incompatible player and turn-history shapes] -> Restart active Koala sessions during coordinated deployment; no persisted data migration is required.
- [Backend and iframe client can disagree during rollout] -> Update and validate AsyncAPI, backend, and dependent client together, then deploy or roll back them in one release window.

## Migration Plan

1. Add ruleset-owned scalar types and change internal turn history to adjusted values.
2. Add stored player selection plus `select`, `deselect`, and `reset` command validation, rules, and game transitions.
3. Restore selection analysis to regular projections and remove the event-specific channel and web projection path.
4. Change submission to consume the stored selection and update focused game, rules, projection, server, and channel tests.
5. Update and validate AsyncAPI, then update the dependent Svelte transport, store, types, fixtures, and browser tests.
6. Deploy backend and client together and restart active Koala sessions.

Rollback requires reverting backend, AsyncAPI, and client changes together and restarting active Koala sessions. Unfinished selections and in-memory turn histories may be discarded.

## Open Questions

None. The incremental payload behavior and value-only turn history are fixed by this change.
