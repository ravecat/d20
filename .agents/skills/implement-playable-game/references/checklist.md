# Playable Game Implementation Checklist

## Rule Discovery

- [ ] Record namespace, slug, launch metadata, and creation inputs.
- [ ] Identify every authoritative source in the supplied specification.
- [ ] Separate immutable configuration, mutable committed facts, and derived values.
- [ ] List participants, identities, roles, and membership behavior.
- [ ] Define which participant set or snapshot each progress and completion predicate uses.
- [ ] Draw all domain phases and transitions.
- [ ] List every client and server-owned event.
- [ ] Record actor class, payload, phase, predicate, effect, and stable errors for every event.
- [ ] Define action atomicity and when progress becomes committed.
- [ ] Define completion, outcome, tie, and terminal behavior.
- [ ] Define caller visibility, private facts, and derived guidance.
- [ ] Define randomness ownership, sampling point, persistence, test control, retries, and idempotency.
- [ ] Build a visibility matrix for every caller role and lifecycle state.
- [ ] Resolve material ambiguity instead of copying another game.

## Unidirectional Runtime

- [ ] Draw the complete `stimulus -> dispatch -> transition -> committed state -> projection -> render` path.
- [ ] Route every authoritative game-state change after initialization through `Game.dispatch/2`.
- [ ] Limit mutation stimuli to authenticated actor dispatches and actorless internal dispatches emitted by a custom game Server.
- [ ] Keep the custom Server responsible for scheduling and dispatch, never direct aggregate mutation.
- [ ] Keep Projection a pure downstream read of caller context and the current Session.
- [ ] Confirm Projection does not construct commands, dispatch events, schedule work, call mutation APIs, or retain authoritative state.
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
- [ ] Make phase and event routing explicit.
- [ ] Choose and test phase-gate versus payload-error precedence.
- [ ] Run Command validation and Rules validation before transition code.
- [ ] Return the old state unchanged for every rejection.
- [ ] Commit compound behavior atomically.
- [ ] Keep transient UI state and process timers out of the aggregate.
- [ ] Enter an explicit terminal state so the outer Session can finish.

## Session Interaction

- [ ] Keep outer session phases separate from inner game phases.
- [ ] Define how `join` and `leave` affect both live membership and committed game state.
- [ ] Define late join, reconnect, duplicate join, and leave behavior from the specification.
- [ ] Test whether membership changes do or do not alter in-progress completion eligibility.
- [ ] Preserve owner-only session start while applying game readiness predicates separately.
- [ ] Confirm accepted commands produce one stored state and one publication.
- [ ] Confirm rejected commands produce no publication.

## Permission and Projection

- [ ] Implement the repository Permission and policy contracts.
- [ ] Return every permission key for every caller state.
- [ ] Treat permissions as client guidance only.
- [ ] Render an explicit public envelope instead of a raw Session or aggregate.
- [ ] Include caller identity and only the necessary public committed facts.
- [ ] Derive legal choices from Rules predicates.
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
- [ ] Add registry coverage.
- [ ] Add explicit `D20Web.Projection.render/2` routing.
- [ ] Add `priv/specs/<slug>.yaml` for creation, commands, replies, projection, permissions, and errors.
- [ ] Cross-check contract names and values against current code and tests.
- [ ] Add contract-serving coverage.
- [ ] Add the contract to the developer index and its test.
- [ ] Cover non-default creation inputs through session and relevant web tests.
- [ ] Coordinate a separate client only when explicitly in scope.

## Test Matrix

| Layer | Minimum behavior |
| --- | --- |
| Ruleset | Static invariants, each rulesheet, lookups, references, boundaries |
| Command | Valid normalization, malformed containers and fields, bounded values, unsupported events |
| Rules | Every predicate, conflicting failures, actor and phase paths, repeated and stale inputs |
| Game | Full transition graph, unchanged state on error, atomicity, completion, terminal state |
| Permission | Complete caller-specific booleans in every relevant state |
| Projection | Public shape, visibility matrix, negative leak checks, derived choices, non-members, terminal state |
| Session | Creation inputs, start ownership, membership policy, game-to-session completion |
| Channel | Replies, accepted broadcasts, rejected non-broadcasts, caller-specific rendering |
| Custom server | Selected module, scheduling, exactly-once action, actor rejection, nondeterministic-value idempotency, error behavior, idle coexistence |
| Registry and contract | Engine discovery, contract serving, developer index |

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

- [ ] Every rule has one clear owner.
- [ ] Predicates and transitions use specification language rather than borrowed mechanics.
- [ ] No rejected command mutates or publishes state.
- [ ] Every accepted mutation is authoritative and atomic.
- [ ] Every playable engine has explicit public projection routing.
- [ ] Runtime flow is one-way from stimulus through committed state to Projection and render.
- [ ] Projection derives only from caller context and current committed state and cannot initiate mutation.
- [ ] Internal commands cannot be invoked with a client identity.
- [ ] Game completion propagates to the outer session.
- [ ] Code, tests, AsyncAPI, and any in-scope client agree.
- [ ] Validation commands and remaining rule gaps are reported.
