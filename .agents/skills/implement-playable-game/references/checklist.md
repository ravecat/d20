# Playable Game Implementation Checklist

## Rule Discovery

- [ ] Record namespace, slug, launch metadata, and creation inputs.
- [ ] Record every start-time input separately from session creation inputs.
- [ ] Identify every authoritative source in the supplied specification.
- [ ] Separate immutable configuration, mutable committed facts, and derived values.
- [ ] List participants, identities, roles, and membership behavior.
- [ ] Define which participant set or snapshot each progress and completion predicate uses.
- [ ] Identify every orthogonal state dimension, including outer Session lifecycle, inner game phase, participant status, roles, selections or other substates, and process-owned timing states that affect behavior.
- [ ] Derive every reachable behaviorally distinct state combination and assign it a stable working state identifier.
- [ ] Classify every material state-dimension combination as reachable, unreachable with a rule justification, or unresolved.
- [ ] Record authoritative facts, invariants, entry sources, allowed stimuli, and terminal behavior for every reachable state.
- [ ] Derive all domain phases and transitions from the authoritative state model.
- [ ] List every client and server-owned event.
- [ ] Record actor class, payload, source state identifiers, predicate, atomic effect, resulting state identifier, and stable errors for every event.
- [ ] Define action atomicity and when progress becomes committed.
- [ ] Define completion, outcome, tie, and terminal behavior.
- [ ] Define caller visibility, private facts, and derived guidance.
- [ ] List the complete permitted facts, statuses, permissions, choices, constraints, progress, outcomes, and rule-derived guidance required by every supported client workflow.
- [ ] For an in-scope client, define the hybrid XState model, including projection synchronization, local interaction states, commands, guards, pending behavior, rejection, disconnect, and rejoin.
- [ ] For an in-scope client, define mobile-first information priority, narrow portrait and desktop layouts, touch behavior, and typography hierarchy.
- [ ] Trace every projected field to committed game state, immutable rules, or explicit caller and session context.
- [ ] Confirm the proposed aggregate contains the minimal authoritative game facts needed to derive every projection without prior renders or client-held history.
- [ ] Define randomness ownership, sampling point, persistence, test control, retries, and idempotency.
- [ ] Build a visibility matrix for every caller role and lifecycle state.
- [ ] Resolve material ambiguity instead of copying another game.

## Authoritative State Model Gate

- [ ] Build and review the authoritative state model before implementing `Command`, `Rules`, `Game`, `Permission`, or `Projection`.
- [ ] Distinguish modeled composite states from coarse runtime `Game.phase` atoms.
- [ ] Distinguish committed authoritative facts from derived permissions, legal options, projections, and client presentation state.
- [ ] Confirm every transition source and destination references a reachable modeled state.
- [ ] Confirm every non-initial reachable state has at least one modeled entry path.
- [ ] Confirm every non-terminal reachable state has an exit stimulus or an explicit rule-defined waiting condition.
- [ ] Confirm every accepted client or server-owned stimulus has one atomic effect and resulting state.
- [ ] Confirm every rejected stimulus preserves its source state and returns a stable error.
- [ ] Confirm semantically related actions with different event, draft, commit, or server paths are explicitly justified.
- [ ] Keep implementation blocked while any material reachable state, invariant, transition, authoritative fact, or visibility source remains unresolved.

## Unidirectional Runtime

- [ ] Draw the complete `stimulus -> dispatch -> transition -> committed state -> projection -> render` path.
- [ ] Route every authoritative game-state change after initialization through `Game.dispatch/2`.
- [ ] Limit mutation stimuli to authenticated actor dispatches and actorless internal dispatches emitted by a custom game Server.
- [ ] Keep the custom Server responsible for scheduling and dispatch, never direct aggregate mutation.
- [ ] Keep Projection a pure downstream read of caller context and the current Session.
- [ ] Confirm Projection does not construct commands, dispatch events, schedule work, call mutation APIs, or retain authoritative state.
- [ ] Return the initial projection when joining the game-session topic and publish later caller-specific snapshots through its `projection` event.
- [ ] Treat command replies as acknowledgements or errors rather than a parallel source of client game state.
- [ ] Treat every client interaction as a new actor dispatch, never as an effect of rendering.

## Predicate Catalog

- [ ] Give every state-dependent rule one owning Rules function.
- [ ] Use boolean predicates for safe capability queries.
- [ ] Use `:ok | {:error, reason}` requirements for authoritative validation.
- [ ] Use result tuples for lookups and candidate application.
- [ ] Pass game, actor, command, and rulesheet context explicitly.
- [ ] Keep public predicates pure and total for missing actors and every lifecycle state.
- [ ] Define deliberate predicate order and error precedence.
- [ ] Make aggregate progress and completion use an explicit participant set or snapshot.
- [ ] Reuse domain predicates across validation, permissions, and projections.
- [ ] Keep wire formatting out of Rules.
- [ ] Commit a candidate only after all predicates succeed.

## Ruleset and Rulesheets

- [ ] Put only state-independent facts and helpers in Ruleset.
- [ ] Record total rounds or turns, supported player count, dice count, die kinds, face or value domains, and other fixed limits defined by the specification.
- [ ] Define named types for bounded static primitives reused across modules.
- [ ] Reuse Ruleset types from Game, Command, Rules, and Projection instead of duplicating finite unions or ranges.
- [ ] Keep allowed domains in Ruleset while storing current round, participants, dice, roll, phase, and status in Game.
- [ ] Add one normalized contract when multiple rulesheets share behavior.
- [ ] Put variant-specific immutable primitive values in declarative rulesheets behind the shared contract.
- [ ] Keep each rulesheet module declarative.
- [ ] Validate identifiers, references, ranges, layout invariants, and cross-field consistency.
- [ ] Expose query functions instead of duplicating static values across modules.
- [ ] Keep live phase, actor, and mutable state out of static modules.

## Command

- [ ] Accept `%D20.Command{}` and validate only event and payload structure.
- [ ] Handle `nil`, non-map, missing, malformed, and extra attributes intentionally.
- [ ] Normalize string keys and finite external enum values.
- [ ] Avoid unbounded atom creation.
- [ ] Return stable malformed-payload and unsupported-event errors.
- [ ] Keep phase, membership, availability, and domain legality in Rules.
- [ ] Never accept caller identity from attributes.

## Game State Machine

- [ ] `use D20.Game` or declare one justified custom server.
- [ ] Validate creation inputs in `changeset/1` before process startup.
- [ ] Implement `init/1`, `dispatch/2`, and `finished?/1`.
- [ ] Define typed JSON-encodable committed state.
- [ ] Store every authoritative game fact required by the reviewed state model for future transitions and projections, but no cached projection or other derivable value.
- [ ] Derive runtime phases and event routing from modeled source and resulting state identifiers.
- [ ] Use explicit Rules predicates when multiple modeled states share one runtime phase.
- [ ] Choose and test phase-gate versus payload-error precedence.
- [ ] Run Command validation and Rules validation before transition code.
- [ ] Return the old state unchanged for every rejection.
- [ ] Commit compound behavior atomically.
- [ ] Keep transient UI state and process timers out of the aggregate.
- [ ] Enter an explicit terminal state so the outer Session can finish.

## Session Interaction

- [ ] Keep outer session phases separate from inner game phases.
- [ ] Preserve `create -> waiting_for_players -> generic SessionPanel start -> in_progress -> iframe` for every game.
- [ ] Keep the iframe unmounted while the outer session is waiting.
- [ ] Avoid registry flags, slug branches, or game-specific shell lobby paths.
- [ ] Define how `join` and `left` events affect both live membership and committed game state.
- [ ] Define late join, reconnect, duplicate join, and `left` event behavior from the specification.
- [ ] Test whether membership changes do or do not alter in-progress completion eligibility.
- [ ] Preserve owner-only session start while applying game readiness predicates separately.
- [ ] Confirm accepted commands produce one stored state and one publication.
- [ ] Confirm rejected commands produce no publication.

## Permission and Projection

- [ ] Implement the repository Permission and policy contracts.
- [ ] Return every permission key for every caller state.
- [ ] Treat permissions as client guidance only.
- [ ] Render an explicit public envelope instead of a raw Session or aggregate.
- [ ] Project declarative `attrs` only when owner start requires game-specific input, return an empty form when that form is unavailable to the caller, and omit the field entirely for games with an empty start payload.
- [ ] Include stable field order, labels, nested input names, caller-safe defaults, and bounded values in projected start descriptors.
- [ ] Include caller identity and only the necessary public committed facts.
- [ ] Derive legal choices from Rules predicates.
- [ ] Include the permitted rule-derived statuses, constraints, progress, outcomes, and guidance needed by each supported client workflow.
- [ ] Confirm clients need not duplicate authoritative game calculations or reconstruct current state from event history.
- [ ] Confirm the client can replace or reconcile its previous authoritative snapshot from each Projection without command reply state or local history.
- [ ] Keep only presentation calculations and ephemeral interaction state on the client.
- [ ] Redact private facts explicitly.
- [ ] Add negative assertions for every field marked hidden in the visibility matrix.
- [ ] Handle owners, participants, non-members, and all lifecycle states safely.
- [ ] Render only from caller context and the current Session.
- [ ] Keep event routing, interaction payload validation, and command construction out of Projection.

## Event Path

### State-changing client event

- [ ] Route through `Sessions.dispatch/3`.
- [ ] Derive actor identity from Scope.
- [ ] Revalidate complete payload and current-state legality.
- [ ] Store and broadcast only after complete success.
- [ ] Deliver resulting caller-visible state through Projection on the game-session topic rather than embedding authoritative state in the command reply.

### Custom server event

- [ ] Justify a real time, process, or external-stimulus boundary.
- [ ] Build on `use D20.Game.Server` with narrow clauses only.
- [ ] Keep domain decisions in Rules and mutations in Game.
- [ ] Dispatch state-changing system events as actorless commands.
- [ ] Require `actor_id: nil` and reject client actors.
- [ ] Preserve shared calls, Presence, publication, and idle expiry.
- [ ] Prevent duplicate scheduling when reads or rejected calls keep the same phase.
- [ ] Define internal error observation, retry, or termination behavior.
- [ ] Sample automatically produced nondeterministic values once and define duplicate-event idempotency.
- [ ] Make nondeterministic behavior controllable or safely assertable in tests.

## Shell and Contract Integration

- [ ] Add or update the engine entry in `config/config.exs`.
- [ ] Keep registry configuration limited to engine and operational launch metadata, not lifecycle ownership.
- [ ] Route all owner starts through the shared `SessionPanel` and `start` event.
- [ ] Cover projected start forms and submitted nested start payloads without game-specific shell branches.
- [ ] Add registry coverage.
- [ ] Add explicit `D20Web.Projection.render/2` routing.
- [ ] Add `priv/specs/<slug>.yaml` for creation, commands, replies, projection, permissions, and errors.
- [ ] Cross-check contract names and values against current code and tests.
- [ ] Add contract-serving coverage.
- [ ] Add the contract to the developer index and its test.
- [ ] Cover non-default creation inputs through session and relevant web tests.
- [ ] Coordinate a separate client only when explicitly in scope.

## Client State, Presentation, and Accessibility

Complete this section whenever the shell UI or a separate iframe client is in scope.

- [ ] Model the client with XState as a hybrid of the latest authoritative Projection and explicit local interaction state.
- [ ] Use the hierarchical state value as the canonical identity of mutually exclusive modes instead of duplicating it in context booleans, tags, component stores, or custom state-node IDs.
- [ ] Put each event on the narrowest compound state that owns all valid sources and use local sibling or descendant target paths.
- [ ] Use `stateIn(...)` and `snapshot.matches(...)` for exact structural questions, and reserve tags for stable cross-cutting semantics that span unrelated branches.
- [ ] Keep guards pure and synchronous, order alternative transitions from most specific to fallback, and keep mutations or effects in actions and actors.
- [ ] Use targetless transitions only when actions should preserve the active descendants, and use explicit targets or `reenter: true` only when reset or restart semantics are intended.
- [ ] Keep guarded `always` states transient and avoid UI or test assertions that require those states to be emitted.
- [ ] Feed the game-session topic join projection and every `projection` event into the machine as synchronization events.
- [ ] Model connection snapshots and Projection snapshots as distinct typed events with separate context assignments and invalidation rules.
- [ ] Preserve an in-flight state across a snapshot only through a guarded targetless transition that proves the new snapshot keeps it valid; otherwise reclassify from updated context.
- [ ] Let the latest Projection win conflicts and invalidate stale local selections, pending assumptions, or optimistic state safely.
- [ ] Send commands from machine effects and wait for a Projection before treating authoritative state as changed.
- [ ] Define connection, rejoin, pending, rejection, and resynchronization states wherever the supported workflow can encounter them.
- [ ] Define XState guards from local facts plus projected permissions, legal choices, constraints, and lifecycle status without treating them as server authorization.
- [ ] Build the exact typed event payload first, use `snapshot.can(event)` for the affordance, and send that same event object without recreating guard logic in the component.
- [ ] Use XState machine and actor primitives directly and keep framework-specific subscriptions and rendering adapters thin.
- [ ] Avoid parallel component or store state that duplicates the machine state node, local context, or current Projection.
- [ ] Design narrow portrait mobile layouts first, then enhance the same information hierarchy for supported desktop sizes.
- [ ] Keep current status, the required choice, and the primary action visible and operable without horizontal scrolling, zooming, or hover-only behavior.
- [ ] Prefer a minimal but informative composition and progressively disclose secondary history or explanation.
- [ ] Use a readable, consistent type scale, line height, hierarchy, line length, and tabular numerals for changing scores, counters, and timers.
- [ ] Size controls for touch, account for safe areas and on-screen keyboards, and preserve keyboard and pointer access.
- [ ] Reuse the color schemes and presentation tokens supplied by the game assets for the client interface, overlays, and gameplay-related controls before introducing new tokens.
- [ ] Inventory every interaction, projection, informational, disabled, error, and focus state before choosing colors.
- [ ] Map semantic state roles to shared presentation tokens instead of repeating color literals.
- [ ] Verify WCAG 2.2 AA contrast against actual adjacent colors: 4.5:1 for normal text, 3:1 for large text, and 3:1 for required controls, states, and meaningful graphics.
- [ ] Test every state over the least-contrasting expected area of the real board or artwork and avoid relying on nominal ratios for thin anti-aliased strokes.
- [ ] Pair color with shape, line style, pattern, icon, text, or another visible cue.
- [ ] Keep preview and temporary-selection geometry stable when both represent the same position and action.
- [ ] Keep keyboard focus visible, distinct from persistent game state, and compatible with forced-colors mode.
- [ ] Confirm halos, keylines, and local boundaries cannot be mistaken for game spaces, targets, or states and do not obscure the board.
- [ ] Preserve accessible names, roles, selected or pressed states, keyboard behavior, hit geometry, and pointer behavior.
- [ ] Keep decorative overlays out of the accessibility tree and expose meaningful game state through operable controls or text.
- [ ] Run browser interaction and computed-style checks, then inspect real assets at desktop and narrow scales with forced-colors and representative color-vision or monochrome evaluation.

## Test Matrix

| Layer | Minimum behavior |
| --- | --- |
| State model | State dimensions, reachable and justified unreachable combinations, invariants, entry and exit coverage, transition traceability |
| Ruleset | Static invariants, each rulesheet, lookups, references, boundaries |
| Command | Valid normalization, malformed containers and fields, bounded values, unsupported events |
| Rules | Every predicate, conflicting failures, actor and phase paths, repeated and stale inputs |
| Game | Full transition graph, unchanged state on error, atomicity, completion, terminal state |
| Permission | Complete caller-specific booleans in every relevant state |
| Projection | Complete client-ready public shape, visibility matrix, negative leak checks, derived choices and guidance, non-members, terminal state |
| Session | Creation inputs, start ownership, membership policy, game-to-session completion |
| Shell start | Empty starts for ordinary games, projected attrs when required, nested payload serialization, no waiting iframe |
| Channel | Replies, accepted broadcasts, rejected non-broadcasts, caller-specific rendering |
| Custom server | Selected module, scheduling, exactly-once action, actor rejection, nondeterministic-value idempotency, error behavior, idle coexistence |
| Registry and contract | Engine discovery, contract serving, developer index |
| In-scope client | Game-session projection synchronization, hierarchical XState paths and transition ownership, guarded-candidate priority, targetless preservation, intentional resets, `snapshot.can(event)` affordances, mobile-first and desktop layouts, typography, semantic states, contrast, non-color cues, focus, accessible interaction, responsive real-asset rendering |

## Validation Commands

Start with the smallest applicable set and broaden according to risk:

```sh
mix format lib/d20/<game>/*.ex test/d20/<game>/*_test.exs
mix test test/d20/<game>/
mix test test/d20_web/projection_test.exs
mix test test/d20/sessions/session_test.exs test/d20/sessions_test.exs
mix test test/d20_web/channels/session_channel_test.exs
mix test test/d20/games/registry_test.exs test/d20_web/plugs/async_api_test.exs
```

When the developer contract index changes:

```sh
cd assets
bun run test -- js/pages/game_pages.test.ts
```

Run `just check` for broad, cross-stack, or release-relevant changes. It does not semantically validate AsyncAPI documents.

## Completion Gate

- [ ] The authoritative state model was completed before implementation and has no unresolved material combinations or invariants.
- [ ] Every reachable modeled state has tested entry, allowed behavior, rejection preservation, and exit or terminal coverage.
- [ ] Every command, transition, aggregate field, predicate, permission, and projected field traces to the authoritative state model.
- [ ] Every rule has one clear owner.
- [ ] Predicates and transitions use specification language rather than borrowed mechanics.
- [ ] No rejected command mutates or publishes state.
- [ ] Every accepted mutation is authoritative and atomic.
- [ ] Every playable engine has explicit public projection routing.
- [ ] Runtime flow is one-way from stimulus through committed state to Projection and render.
- [ ] Projection derives only from caller context and current committed state and cannot initiate mutation.
- [ ] Every projected field is reproducible from committed game state, immutable rules, and explicit caller and session context.
- [ ] Every supported client workflow receives its permitted rule-derived information without duplicating authoritative calculations.
- [ ] Every in-scope client treats channel-delivered Projection as authoritative and reconciles it through an explicit hybrid XState machine.
- [ ] Client guards consume projected permissions and legal choices for affordances while server Rules remain authoritative.
- [ ] Internal commands cannot be invoked with a client identity.
- [ ] Game completion propagates to the outer session.
- [ ] Every game follows the same shell-owned session launch lifecycle without registry or slug-specific bypasses.
- [ ] Code, tests, AsyncAPI, and any in-scope client agree.
- [ ] Every in-scope client meets the mobile-first layout, typography, contrast, non-color-cue, focus, accessible-interaction, and real-asset validation requirements at narrow mobile and supported desktop sizes.
- [ ] Validation commands and remaining rule gaps are reported.
