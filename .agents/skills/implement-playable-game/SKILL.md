---
name: implement-playable-game
description: Implement or extend a playable game in the D20 Phoenix application from a rules specification. Use for new game namespaces or substantial gameplay additions involving static Ruleset or rulesheet data, Command payload validation, state-dependent Rules predicates, Game state-machine transitions, Permission, Projection, optional custom D20.Game.Server events, registry wiring, AsyncAPI contracts, and layered tests. Do not use for catalog-only entries, iframe-only UI work, or minor isolated fixes.
---

# Implement Playable Game

## Purpose

Turn an arbitrary game specification into one server-authoritative D20 game without assuming any particular mechanics. Guide the work from rule discovery through module boundaries, runtime integration, public contract, and validation.

## Load Context

1. Read the repository `AGENTS.md` and every supplied source of game rules.
2. Read any active OpenSpec change named by the task. Treat unrelated `openspec/changes/` directories as historical context.
3. Read [references/architecture.md](references/architecture.md) before designing modules, predicates, or event paths.
4. Use [references/checklist.md](references/checklist.md) during implementation and validation.
5. Inspect the shared contracts:
   - `lib/d20/game.ex`
   - `lib/d20/game/server.ex`
   - `lib/d20/sessions.ex`
   - `lib/d20/sessions/session.ex`
   - `lib/d20/command.ex`
   - `lib/d20/permission.ex`
6. Inspect complete existing game namespaces and their tests only to learn repository conventions. Do not import their domain assumptions into the new game.

## Workflow

### 1. Build a rule inventory

Translate prose, tables, diagrams, and rulesheets into explicit decisions before writing modules. Capture:

- session creation inputs and variants
- participants, identities, roles, and membership behavior
- the participant set used by each progress or completion predicate, including the effect of join, leave, and reconnect
- initial committed state
- phases and transitions
- external commands, actors, payloads, and errors
- state-dependent legality
- action effects and atomicity boundaries
- progress, completion, outcome, and tie behavior
- caller visibility and derived guidance
- randomness ownership, sampling point, persistence, retry behavior, testability, deadlines, timers, and automatic actions

Produce four compact working artifacts in the plan or task notes:

1. A transition table: current phase, stimulus, predicate, next state, effects.
2. A command table: event, actor class, payload, allowed phases, stable errors.
3. A predicate catalog: name, inputs, result, owning module, consumers.
4. A visibility matrix: caller role and lifecycle state mapped to visible, hidden, and derived fields.

Ask the user only about gaps that materially alter rules, state, or public contracts. Do not guess missing semantics.

### 2. Assign every rule to one owner

| Rule or behavior | Owner |
| --- | --- |
| Immutable values, layouts, ranges, lookup tables, variant data | `Ruleset` and rulesheet modules |
| External event payload shape and bounded normalization | `Command` |
| Legality depending on current game, actor, or selected rulesheet | `Rules` |
| Committed aggregate state and accepted transitions | `Game` |
| Caller affordances | `Permission` |
| Caller-visible read model and derived options | `Projection` |
| Timers and process-owned automatic stimuli | Optional custom `Server` |

If one fact appears in several modules, expose it from its owner instead of duplicating it.

### 3. Model static configuration

Put facts that can be answered without a live game in `Ruleset`. Expose query functions and static predicates instead of making consumers inspect raw module attributes.

When the specification defines interchangeable rulesheets, add one common rulesheet contract and one declarative data module per variant. Normalize all variants into the same structure so `Rules` and `Game` operate on data rather than variant-specific branches.

Validate identifiers, references, dimensions, ranges, and other cross-field invariants before building state transitions.

### 4. Design dynamic predicates

Make `Rules` the single source for state-dependent legality. Prefer small, named, pure predicates that can be composed by command validation, permissions, projections, and transition code.

- Use boolean predicates for safe capability queries, such as `action_allowed?/2`.
- Use result predicates for authoritative validation, such as `require_phase/2` returning `:ok | {:error, reason}`.
- Keep predicate inputs explicit: game state, actor, normalized command, and normalized rulesheet data as needed.
- Make public predicates total for unknown actors, spectators, incomplete state, and terminal state.
- Keep stable reason values and make validation order intentional, because predicate order defines error precedence.
- Define the participant set or snapshot consumed by aggregate progress and completion predicates.
- Expose domain primitives for legal choices and candidate evaluation. Keep JSON formatting and transport envelopes out of `Rules`.
- Reuse the same legality primitives for command validation, permissions, and projections.

Do not mutate the aggregate in predicates. If validating an atomic compound action needs intermediate results, return a candidate value and commit it only after the full chain succeeds.

### 5. Define the command boundary

Use the game-specific `Command` module to validate untrusted event attributes independently of current state.

- Validate maps, required fields, types, bounded values, nested structures, and unknown events.
- Normalize external strings through finite mappings.
- Never derive caller identity from attributes and never create atoms from arbitrary input.
- Keep phase, membership, availability, and state-dependent target checks in `Rules`.

Decide whether phase gating or payload validation has precedence, then encode and test that choice consistently.

### 6. Implement the game state machine

`Game` owns only shared committed facts and state transitions. Implement the `D20.Game` callbacks, creation changeset, typed aggregate, explicit phase and event clauses, terminal state, and outcome calculation.

For every accepted mutation, preserve this sequence:

```text
phase and event gate
-> Command.validate/1
-> Rules.validate/2
-> apply one complete transition
-> return one new aggregate
```

Rejected commands must return the old state unchanged and must not publish. Accepted compound behavior must commit atomically. Store committed domain facts in the aggregate and keep transient UI state out.

Remember that the game state machine is nested inside the generic session state machine. `D20.Sessions.Session` owns session membership, owner-only start, and outer completion. The game owns readiness, inner phases, legal transitions, and `finished?/1`.

### 7. Choose the event path and server

Classify every state-changing stimulus:

| Stimulus | Path |
| --- | --- |
| Changes shared committed state | `SessionChannel -> Sessions.dispatch -> Session.dispatch -> Game.dispatch` |
| Is initiated by a process timer or automatic trigger | Custom `D20.Game.Server` -> actorless internal dispatch |

Use the default server through `use D20.Game` unless the process itself must initiate an asynchronous stimulus.

For a custom server:

- Declare it through `use D20.Game, server: MyGame.Server`.
- Build it with `use D20.Game.Server` and add only narrow callback clauses.
- Keep domain decisions in `Rules` and state changes in `Game`.
- Represent a state-changing system event as `%D20.Command{actor_id: nil}` and send it through the normal dispatch pipeline.
- Require the missing actor for system-only events and reject the same event from clients.
- Preserve inherited dispatch, Presence, broadcast, read, and idle-timeout behavior.
- Define explicit handling when an internal-command error must be observed, retried, or terminate the process.
- Make automatically produced values idempotent across duplicate delivery or retry, and define how their source is controlled in tests.

Keep synchronous consequences of an accepted command inside the same `Game` transition. Add a custom event only for a real process or time boundary.

### 8. Build permissions and projections

Derive permission booleans from the same Rules predicates, but never treat them as authorization. Every dispatched command must still validate actor and legality authoritatively.

Build an explicit caller-specific projection from the visibility matrix. Render it only from caller context and the current Session. Include only public committed facts, caller identity, permissions, and derived options required by the client. Handle spectators and all lifecycle states without returning a raw aggregate. Add negative tests that prove hidden fields do not leak to other caller roles.

Keep gameplay events and command construction out of Projection. Projection renders state; it does not route interactions or synthesize `%D20.Command{}` values.

### 9. Complete runtime and contract integration

Wire the playable engine into the registry, explicit web projection routing, public AsyncAPI document, developer contract index, and focused integration tests.

Do not edit a separate client repository unless the task explicitly includes it. Report required client coordination when a public contract changes.

### 10. Validate by boundary and end-to-end flow

Test static definitions, payload normalization, predicates, transitions, rejected-state preservation, completion, permissions, caller projections, session lifecycle, replies, broadcasts, registry wiring, and contract serving.

For custom servers, test automatic-event identity, scheduling, duplicate prevention, failure behavior, and coexistence with idle expiry.

Format touched files and broaden checks according to risk. Do not claim semantic AsyncAPI validation from `just check`; the repository currently has no native semantic validator for it.

## Completion Output

Report:

- how the specification was mapped into modules and predicates
- the state machine and event-path decisions
- default or custom server choice
- public contract and integration points changed
- commands run and behavior verified
- unresolved rule gaps, external coordination, and remaining risks
