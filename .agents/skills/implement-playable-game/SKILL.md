---
name: implement-playable-game
description: Implement or extend a playable game in the D20 Phoenix application from a rules specification. Use for new game namespaces or substantial gameplay additions involving static Ruleset or rulesheet data, Command payload validation, state-dependent Rules predicates, Game state-machine transitions, Permission, Projection, optional custom D20.Game.Server events, in-scope mobile-first game clients with XState and channel projection synchronization, registry wiring, AsyncAPI contracts, and layered tests. Do not use for catalog-only entries, iframe-only UI work, or minor isolated fixes.
---

# Implement Playable Game

## Purpose

Turn an arbitrary game specification into one server-authoritative D20 game without assuming any particular mechanics. Guide the work from rule discovery through module boundaries, runtime integration, public contract, client synchronization when in scope, and validation. Preserve one-way runtime flow: stimuli enter through dispatch, accepted transitions produce committed state, Projection renders only from that state, and the client reconciles its local interaction state with each delivered projection.

## Load Context

1. Read the repository `AGENTS.md` and every supplied source of game rules.
2. Locate and cite the current official publisher or designer rulebook, errata, player aids, and relevant official support links. Prefer canonical openly accessible sources over mirrors, community summaries, videos, or recollection. Record conflicting or missing official guidance as a blocking rule gap.
3. Read any active OpenSpec change named by the task. Treat unrelated `openspec/changes/` directories as historical context.
4. Read [references/architecture.md](references/architecture.md) before designing modules, predicates, or event paths.
5. Use [references/checklist.md](references/checklist.md) during implementation and validation.
6. Inspect the shared contracts:
   - `lib/d20/game.ex`
   - `lib/d20/game/server.ex`
   - `lib/d20/sessions.ex`
   - `lib/d20/sessions/session.ex`
   - `lib/d20/command.ex`
   - `lib/d20/permission.ex`
7. Inspect complete existing game namespaces and their tests only to learn repository conventions. Do not import their domain assumptions into the new game.

## Workflow

### 1. Build a rule inventory and authoritative state model

Translate prose, tables, diagrams, and rulesheets into explicit decisions before writing modules. Capture:

- session creation inputs and variants
- start-time inputs required between session creation and the outer `start` transition
- participants, identities, roles, and membership behavior
- the participant set used by each progress or completion predicate, including the effect of `join`, `left`, and reconnect
- initial committed state
- phases and transitions
- external commands, actors, payloads, and errors
- state-dependent legality
- action effects and atomicity boundaries
- progress, completion, outcome, and tie behavior
- caller visibility and derived guidance
- the minimal authoritative game facts needed to derive every caller projection from the current state, immutable rules, and caller and session context
- the complete permitted facts and rule-derived guidance each supported client workflow needs without reimplementing domain logic or reconstructing state from event history
- the exact official rule URLs, source priority, unresolved source conflicts, and any repository rulebook copies
- when a game client is in scope, every visible interaction, projection, informational, disabled, error, and focus state, including its semantic color role and non-color cue
- when a game client is in scope, the official visual-source inventory: palette, symbols, shapes, component appearance, terminology, publisher-hosted assets, provenance, and reuse constraints
- when a game client is in scope, the repository-native asset and color-scheme preview surface, plus an asset provenance ledger when a publisher or designer provides a separate static asset pack
- when a game client is in scope, the hybrid client state machine that combines the latest server projection with explicit local interaction, connection, pending, and recovery states
- when a game client is in scope, the narrow mobile and desktop layout behavior, information priority, touch interaction, and typography hierarchy
- randomness ownership, sampling point, persistence, retry behavior, testability, deadlines, timers, and automatic actions

Before designing modules or finalizing events, derive an authoritative state model from the inventory:

- Identify orthogonal state dimensions, including the outer Session lifecycle, inner game phase, participant status, roles, selections or other substates, and process-owned timing states when they affect behavior.
- Derive every reachable behaviorally distinct combination and give it a stable working state identifier. Record material cross-product combinations as reachable, unreachable with a rule justification, or unresolved.
- For each reachable state, record its authoritative committed facts, invariants, allowed actor or server stimuli, accepted atomic effects, resulting states, stable rejections, and terminal behavior.
- Distinguish modeled composite states from runtime `Game.phase` values. Several modeled states may share one phase and differ through participant status or another authoritative substate.
- Distinguish committed authoritative facts from values derived through immutable rules, caller and session context, predicates, permissions, or Projection.

Treat this as a blocking discovery gate. Do not begin `Command`, `Rules`, `Game`, `Permission`, or `Projection` implementation while a reachable state, invariant, transition, authoritative fact, or visibility source is unresolved. Do not silently omit a theoretical state combination: prove it unreachable from the rules or keep it as a blocking gap.

Produce five compact working artifacts in the plan or task notes:

1. An authoritative state model: state dimensions, reachable combinations, state identifiers, committed facts, invariants, allowed stimuli, effects, resulting states, rejections, and terminal behavior.
2. A transition table derived from the state model: source state identifier, stimulus, predicate, next state identifier, effects, and errors.
3. A command table derived from the state model: event, actor class, payload, allowed source states, stable errors.
4. A predicate catalog derived from state invariants and transition guards: name, inputs, result, owning module, consumers.
5. A visibility matrix derived from state identifiers and authoritative facts: caller role and lifecycle state mapped to visible, hidden, and derived fields, with the authoritative source of every projected field.

Cross-check the artifacts before implementation:

- Every transition source and destination references a reachable modeled state.
- Every client or server-owned command appears as a modeled stimulus.
- Every accepted command has one atomic effect and resulting state.
- Every rejection preserves its modeled source state.
- Every aggregate field and projected field traces to the state model, immutable rules, or explicit caller and session context.

Ask the user only about gaps that materially alter rules, state, or public contracts. Do not guess missing semantics.

Treat a projection that cannot be recomputed from the proposed committed game state, immutable rules, and explicit caller and session context as an unresolved state-design gap. Clarify the missing authoritative fact before implementation. Do not solve the gap by caching a projection or depending on a previous render or client-held history.

### 2. Assign every rule to one owner

| Rule or behavior | Owner |
| --- | --- |
| Immutable primitives and their domain types, layouts, ranges, lookup tables, variant data | `Ruleset` and rulesheet modules |
| External event payload shape and bounded normalization | `Command` |
| Legality depending on current game, actor, or selected rulesheet | `Rules` |
| Committed aggregate state and accepted transitions | `Game` |
| Caller affordances | `Permission` |
| Caller-visible read model and derived options | `Projection` |
| Timers and process-owned automatic stimuli | Optional custom `Server` |

If one fact appears in several modules, expose it from its owner instead of duplicating it.

Treat the write and read paths as separate and one-way. `Command`, `Rules`, and `Game` form the authoritative write path. `Projection` is a downstream read transformation and must not construct or dispatch commands, call a server mutation API, or provide state back to a transition.

### 3. Model static configuration

Put facts that can be answered without a live game in `Ruleset`. Treat it as the owner of immutable game primitives such as the total round or turn count, supported player count, dice count, supported die kinds and face or value domains, and other fixed limits discovered in the specification. These are categories to identify, not default values to copy between games. Expose query functions and static predicates instead of making consumers inspect raw module attributes.

Define named `@type` values beside static primitives when they form a shared bounded vocabulary, such as `round_number()`, `player_count()`, `die_kind()`, `die_value()`, or `rulesheet_id()`. Constrain each type to the finite union or range from the specification and reuse it from `Game`, `Command`, `Rules`, and `Projection` instead of repeating literals. `Ruleset` owns the allowed domain; `Game` owns the current round, current participants, current dice or roll, and other mutable values. Keep state-machine types such as phase and player status with `Game`.

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

Implement only from the reviewed authoritative state model. `Game` owns only shared committed facts and state transitions. Make the aggregate minimal but sufficient: it must retain every authoritative game fact identified by the model and needed to derive future behavior and every projection, while excluding values that can be derived from those facts, immutable rules, and explicit caller and session context. Implement the `D20.Game` callbacks, creation changeset, typed aggregate, explicit phase and event clauses, terminal state, and outcome calculation.

Map each phase and event clause to modeled source and destination states. When multiple modeled states share one runtime phase, use explicit Rules predicates over authoritative substate rather than adding a phase atom for every combination or leaving the distinction implicit.

For every accepted mutation, preserve this sequence:

```text
phase and event gate
-> Command.validate/1
-> Rules.validate/2
-> apply one complete transition
-> return one new aggregate
```

Rejected commands must return the old state unchanged and must not publish. Accepted compound behavior must commit atomically. Store committed domain facts in the aggregate and keep transient UI state out.

After `init/1`, every authoritative game-state change must result from an accepted `Game.dispatch/2`. Its stimulus originates either from an authenticated actor through `D20.Sessions` or from an actorless internal command emitted by a custom game `Server`. Server callbacks may schedule and dispatch stimuli, but they must not mutate the aggregate directly.

Remember that the game state machine is nested inside the generic session state machine. `D20.Sessions.Session` owns session membership, owner-only start, and outer completion. The game owns readiness, inner phases, legal transitions, and `finished?/1`.

Preserve one shell-owned launch lifecycle for every game:

```text
create session -> waiting_for_players -> generic SessionPanel start -> in_progress -> iframe
```

Do not add registry capabilities, slug checks, or early iframe mounting to bypass game-specific start inputs. When `start` needs game-specific attributes, Projection must expose caller-specific declarative `attrs` that the shared `SessionPanel` can render and submit through the same `start` event. When `start` needs no game-specific attributes, omit `attrs` from the runtime projection entirely. The descriptor supplies fields and allowed values only. `Command` and `Rules` still normalize and validate the submitted payload, and Projection never constructs or dispatches the command.

### 7. Choose the event path and server

Classify every state-changing stimulus:

| Stimulus | Path |
| --- | --- |
| Changes shared committed state | `SessionChannel -> Sessions.dispatch -> Session.dispatch -> Game.dispatch` |
| Is initiated by a process timer or automatic trigger | Custom `D20.Game.Server` -> actorless internal dispatch |

Maintain this direction for every runtime interaction:

```text
actor or internal Server
-> dispatch
-> Command and Rules validation
-> Game transition
-> committed server state
-> Projection(current Session, caller)
-> game-session topic join reply or projection event
-> client state machine
-> public render
```

There is no reverse edge from Projection or rendering to dispatch. A client interaction is a new actor stimulus sent through the channel, not an effect emitted by Projection.

Send client commands through the game-session channel and deliver all caller-visible gameplay state through Projection. In D20, return the initial caller projection when joining `session:<id>` and push later projections with the `projection` event on that topic. Treat command replies as acknowledgements or errors, not as an alternate source of game state. Never send a raw Session or Game aggregate to let the client reconstruct authority outside Projection.

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

Build an explicit caller-specific projection from the visibility matrix. Render it only from caller context and the current Session. Make it a complete, ready-to-consume read model for each supported client workflow: include permitted committed facts, caller identity, lifecycle and game statuses, permissions, legal choices, constraints, progress, outcomes, and other rule-derived guidance the client needs. Do not omit domain information merely because the client could recompute it from lower-level facts or event history. Keep client calculations limited to presentation concerns and ephemeral interaction state. Handle spectators and all lifecycle states without returning a raw aggregate, exposing private facts, or adding speculative fields that no supported workflow uses. Add negative tests that prove hidden fields do not leak to other caller roles.

If owner start requires a payload, include a declarative `attrs` form in the waiting projection. Return an empty form for callers or lifecycle states that cannot use it. If start has an empty payload, omit the field instead of projecting an empty placeholder. Keep field ordering, labels, current values, bounded choices, and input names explicit enough for the shared shell to submit the intended nested payload without game-specific branches.

For every projected field, verify that its value is reproducible from the current committed game state, immutable rules, and explicit caller and session context. If it is not, add the missing authoritative game fact to the aggregate instead of adding hidden state to Projection or relying on client history.

Keep Projection a pure derivation of caller context and the current committed state held in Session. The same inputs must produce the same public read model. Projection may call pure Rules queries for permissions and legal choices, but it must not validate interaction payloads, dispatch commands, schedule work, call mutation APIs, retain authoritative state, or synthesize `%D20.Command{}` values. Rendering never advances the state machine.

Treat the latest delivered projection as the authoritative client snapshot. Include enough phase, status, permission, legal-choice, and outcome information for the client to replace or reconcile its previous snapshot without inferring authority from command acknowledgements, local history, or optimistic state.

### 9. Implement a mobile-first accessible game client when in scope

Treat accessible presentation as a completion requirement whenever the task explicitly includes the shell UI or a separate iframe client.

- Derive gameplay UI from the public Projection and keep only presentation calculations and ephemeral interaction state on the client.
- Model the client as a hybrid XState machine whose context contains the latest authoritative Projection and the minimal complete local facts needed for the current interaction. Represent behaviorally distinct local modes explicitly instead of scattering them across component variables.
- Use the hierarchical state value as the canonical identity of mutually exclusive client modes. Put an event on the narrowest compound state that owns every valid source, target descendants through local state paths, and avoid custom state-node IDs that only alias those paths.
- Use `stateIn(...)` inside the machine and `snapshot.matches(...)` at read boundaries for exact structural state questions. Use tags only for a stable cross-cutting semantic group that genuinely spans unrelated branches, not to duplicate an existing parent state.
- Keep guards pure and synchronous. For alternative guarded transitions, order the most specific cases first and put an unconditional fallback last.
- Omit `target` when an event should update context or run an action while preserving the active child state. Add an explicit target or `reenter: true` only when descendant resolution or invoked actors should restart.
- Use guarded `always` transitions only for internal classification that may be transient. Do not make rendering or tests depend on observing an `always`-only state.
- Build the exact typed event object first and use `snapshot.can(event)` for client affordances before sending that same object. Do not recreate guard logic in components.
- Feed the channel join result and every `projection` event into the machine as server synchronization events. Replace or reconcile the authoritative slice from the newest projection, let server state win every conflict, and clear or repair local selections and pending assumptions that the projection makes invalid.
- Keep connection snapshots and game-session Projection snapshots as distinct typed events because they update different context slices and invalidate different assumptions. Reclassify from the updated context, while using a guarded targetless synchronization transition only when the new snapshot proves an in-flight local state is still valid.
- Send player intents as channel commands from machine effects, but wait for a projection before considering authoritative game state changed. Model connection, rejoin, pending, rejection, and resynchronization behavior when those states affect the supported workflow.
- Define XState guards from both local context and projected permissions, legal choices, constraints, and lifecycle status. Use these guards for client affordances only and revalidate every command on the server.
- Prefer XState state-machine and actor primitives such as `setup`, `createMachine`, guards, actions, and invoked actors. Keep Svelte or other framework integration at a thin subscription and rendering boundary. Do not add helpers that hide the machine graph, events, guards, or transition ownership unless they remove demonstrated repetition across machines.
- Design the narrow portrait mobile layout first because mobile play is the primary use case, then enhance the same information hierarchy for desktop. Keep the current game status and primary action usable without horizontal scrolling, zooming, or desktop-only hover behavior.
- Prefer the smallest interface that remains complete and informative. Prioritize current phase, active player or turn, required choice, primary action, and actionable error; progressively disclose secondary history or explanation without hiding information needed to play correctly.
- Apply typography best practices as a design recommendation: use a small consistent type scale, readable body size and line height, clear heading and label hierarchy, concise copy, controlled line length, and tabular numerals for changing scores, counters, and timers. Do not shrink essential text to force a desktop composition into a mobile viewport.
- Size and space controls for touch, account for safe areas and on-screen keyboards, and preserve the same actions through keyboard and pointer input.
- Build a visual-source inventory from the official rulebook, supplied official references, and relevant publisher-hosted assets linked by those sources. Record exact URLs and distinguish source authority from permission to reuse artwork.
- Derive the game-specific palette, symbols, shapes, component appearance, terminology, and relative emphasis from approved official visual sources instead of inventing an unrelated visual language.
- Open access to a rulebook does not establish reuse rights for its artwork. Do not copy scans, logos, illustrations, card faces, board images, or extracted production assets unless their license or explicit permission allows it. Record provenance and reuse constraints for authorized assets; otherwise create fit-for-purpose local assets from the permitted visual reference.
- Inspect any separately published official static asset pack before creating replacements. When reuse is permitted, keep an approved local copy instead of adding a runtime hotlink and create an asset ledger recording source URL, publisher or owner, version or retrieval date, reuse basis or license, source hash when downloaded, local path, transformations, and known consumers.
- Create or update the repository-native asset preview surface, such as a Storybook asset story or equivalent catalog. Show the approved source palette, every reusable local asset, derived variants, meaningful interaction states, and representative minimum and desktop sizes without embedding unlicensed source artwork.
- Compare the preview against the official visual sources before accepting the assets. Verify asset loading, intended color use, recognizable symbols, geometry, clipping, contrast, non-color cues, and consistency between the preview and production consumers.
- Map the approved source palette and existing game assets onto semantic presentation tokens before introducing new colors. Adapt print values for responsive interaction and accessibility when literal reproduction cannot express a required state accessibly.
- Inventory semantic roles such as available, preview, temporary, committed, bonus, danger, disabled, informational, and focus before choosing colors. Expose them through shared presentation tokens instead of repeating literals.
- Meet WCAG 2.2 AA contrast in the actual rendered context: at least 4.5:1 for normal text, 3:1 for large text, and 3:1 for visual information required to identify controls, states, and meaningful graphics against adjacent colors. Test every state over the least-contrasting expected board or artwork region, and leave extra margin for thin SVG strokes and anti-aliasing.
- Never use color as the only state cue. Combine it with shape, line style, pattern, icon, text, or another visible distinction so users with color-vision deficiencies, low vision, aging vision, or monochrome displays can understand the state.
- Keep preview and temporary-selection geometry stable when they represent the same position and action. Change size or shape only when that difference conveys an intentional state transition.
- Keep keyboard focus visible and distinct from persistent game state. Preserve system-color behavior in forced-colors mode.
- Do not add a universal halo, keyline, or duplicated geometry solely to satisfy contrast. First verify that it cannot be mistaken for an empty space, legal target, or other game state and does not obscure the board. Prefer one authoritative semantic outline and use a local boundary only where it remains unambiguous.
- Preserve accessible names, roles, pressed or selected states, keyboard operation, hit geometry, and pointer behavior. Keep decorative SVG overlays out of the accessibility tree while exposing the same meaningful state through operable controls or text.
- Validate with computed contrast checks and browser interaction tests, then inspect the real artwork at narrow mobile portrait and supported desktop scales. Include forced-colors and representative color-vision or monochrome evaluation when the client supports authored game colors.

### 10. Complete runtime and contract integration

Wire the playable engine into the registry, explicit web projection routing, public AsyncAPI document, developer contract index, and focused integration tests.

Do not edit a separate client repository unless the task explicitly includes it. Report required client coordination when a public contract changes.

### 11. Validate by boundary and end-to-end flow

Test static definitions, payload normalization, predicates, every reachable modeled state, every modeled transition, rejected-state preservation, unreachable-state invariants, completion, permissions, complete caller projections, session lifecycle, replies, broadcasts, registry wiring, and contract serving. Verify that supported client workflows receive their permitted rule-derived information without reimplementing authoritative calculations.

For custom servers, test automatic-event identity, scheduling, duplicate prevention, failure behavior, and coexistence with idle expiry.

Format touched files and broaden checks according to risk. Do not claim semantic AsyncAPI validation from `just check`; the repository currently has no native semantic validator for it.

For an in-scope client, run its native format, lint, type, browser-test, and production-build commands. Verify channel projection reconciliation, XState transitions and guards, mobile and desktop behavior, typography, accessibility, and game-state presentation against the real assets, not only isolated token values.

## Completion Output

Report:

- how the specification was mapped into modules and predicates
- the authoritative state model and how runtime phases, commands, transitions, aggregate facts, and projections derive from it
- the state machine and event-path decisions
- default or custom server choice
- public contract and integration points changed
- official rule sources, unresolved source conflicts, and any repository rulebook copies
- client projection transport, XState synchronization, responsive layout, typography, visual-source, asset-preview, external-static, and asset-provenance decisions when a client is in scope
- commands run and behavior verified
- unresolved rule gaps, external coordination, and remaining risks
