# Game Module Patterns

## Purpose

Use this reference to convert an unknown rules specification into D20 module boundaries. It describes stable architectural patterns and intentionally contains no game-specific mechanics.

## Dependency Direction

Keep dependencies directed from orchestration and rendering toward domain facts:

```text
Server -> Session -> Game -> Rules -> Ruleset
                         ^        ^
                         |        |
                    Command   rulesheets

Projection -> Permission -> Rules -> Ruleset
Projection -----------------> Rules -> Ruleset
```

`Ruleset`, rulesheet data, and predicates must not depend on Phoenix channels, session processes, or transport formatting.

## Unidirectional Runtime Flow

Keep the mutation path and read path strictly one-way:

```text
external actor -> channel dispatch -----\
                                        -> Session.dispatch -> Game.dispatch -> committed state
custom Server -> internal dispatch -----/                                      |
                                                                                v
                                                Projection(current Session, caller)
                                                                                |
                                                                                v
                                           game-session topic join or projection event
                                                                                |
                                                                                v
                                                                  client XState machine
                                                                                |
                                                                                v
                                                                         public render
```

`Game.dispatch/2` runs Command and Rules validation before applying one complete transition. After initialization, it is the only path that changes authoritative game state.

A custom game Server may schedule a stimulus and send an actorless command through the same dispatch pipeline. It must not mutate the game aggregate directly.

Projection and rendering are downstream reads of the latest committed state held by the server. They may derive caller-specific permissions and legal choices through pure predicates, but they must not construct commands, dispatch events, schedule callbacks, call mutation APIs, or retain authoritative state. Deliver the initial projection in the game-session topic join reply and later projections through that topic's `projection` event. The client feeds those snapshots into its local state machine before rendering. A user interaction starts a new actor dispatch; it is never a side effect of rendering.

## Discovery Artifact Templates

Use these table shapes before implementation. Fill them with language from the supplied specification.

### Authoritative state model

Build this artifact first. Begin with orthogonal state dimensions rather than guessing one flat phase enum:

| State dimension | Finite domain or bounded shape | Authoritative source | What changes it | Derived or committed |
| --- | --- | --- | --- | --- |
|  |  |  |  |  |

Then derive the reachable behaviorally distinct combinations:

| State ID | Dimension values | Authoritative facts | Invariants | Entry sources | Allowed stimuli | Terminal |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |

Classify every material cross-product combination as reachable, unreachable with a rule justification, or unresolved. An unresolved combination is a blocking rule gap, not an implementation detail.

State IDs describe combinations that matter to behavior, legality, persistence, or visibility. They do not need a one-to-one mapping to runtime `Game.phase` atoms. For example, several modeled states may share one phase while differing by participant status or an optional authoritative selection.

Keep four concepts separate:

| Concept | Purpose | May contain derived values |
| --- | --- | --- |
| Modeled composite state | Names one reachable combination of all behaviorally relevant state dimensions | Only as annotation, never as state identity or authority |
| Runtime phase | Provides coarse `Game.dispatch/2` routing and process lifecycle | No |
| Committed aggregate | Stores minimal authoritative facts needed for future transitions and projections | No |
| Caller projection | Renders permitted committed facts and rule-derived guidance for one caller | Yes |

### Transition table

Derive every row from the authoritative state model and reference its stable state identifiers:

| Source state ID | Stimulus | Required predicates | Atomic effects | Resulting state ID | Stable errors |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

### Command table

| Event | Actor class | Payload | Allowed source state IDs | State-changing | Stable errors |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

### Predicate catalog

| Predicate | Inputs | Return shape | Owner | Consumers | Failure precedence |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

### Visibility matrix

| Caller role | Lifecycle state | Visible fields | Hidden fields | Derived fields | Authoritative sources |
| --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |

### State-model gate

Do not proceed to implementation until all checks pass:

- Every transition source and destination exists in the reachable-state table.
- Every non-initial reachable state has a modeled entry path.
- Every non-terminal reachable state has an allowed exit stimulus or an explicit rule-defined waiting condition.
- Every client and server-owned command appears in the transition and command tables.
- Every accepted command has one atomic effect and resulting state.
- Every rejection preserves the source state and has a stable error.
- Every aggregate field is an authoritative fact required by at least one future transition or projection.
- Every projected field traces to committed state, immutable rules, or explicit caller and session context.
- Every material unlisted state combination is proven unreachable rather than silently ignored.

## Ruleset and Rulesheet Pattern

### Purpose

Represent all facts that are stable for the lifetime of a game and can be queried without a live aggregate.

### Put here

- total round or turn count and other fixed progress bounds
- supported player count or range
- dice count, supported die kinds, and face or value domains
- supported configuration values
- bounded domains and fixed limits
- static layouts and relationships
- lookup and outcome tables
- static validation and transformation helpers
- named types for immutable primitives and normalized rulesheet data
- mapping from a variant id to a normalized rulesheet

### Keep out

- current phase or participant state
- current round or turn, joined player count, and current dice or roll
- current occupancy, progress, or availability
- caller identity
- command payload parsing
- public JSON representation

### Type ownership

Define named `@type` values in `Ruleset` for bounded primitive domains that exist independently of a live aggregate. Typical type roles include `round_number()`, `player_count()`, `die_kind()`, `die_value()`, coordinate or reference types, and `rulesheet_id()`. Use the actual finite unions and ranges from the specification rather than broad `atom()` or `integer()` types when they are known.

Type ownership follows domain meaning, not whether one runtime value later changes. `Ruleset` owns the allowed round-number or die-value domain; `Game` owns the current round and current roll and references the corresponding `Ruleset` types. Keep aggregate structures, phases, player statuses, and other state-machine vocabulary in `Game`.

When a primitive differs by rulesheet, put its value in the declarative rulesheet source and expose it through the normalized contract. Keep the shared type and query boundary in `Ruleset` or the common rulesheet module.

Use a rulesheet behavior when several variants must expose the same attributes. The behavior defines the complete source shape. A constructor normalizes that source into one struct consumed by all other modules. Keep each variant declarative and prevent the rest of the namespace from branching on variant names.

Static predicates answer questions about the configuration itself. Examples of predicate shape, not domain semantics:

```elixir
@spec valid_ref?(t(), ref()) :: boolean()
@spec fetch_value(t(), key()) :: {:ok, value()} | :error
```

Prefer these functions over duplicating id lists and structural assumptions in Command, Rules, Projection, and AsyncAPI.

## Command Pattern

### Purpose

Turn an untrusted wire payload into a bounded internal command representation before state-dependent rules see it.

`D20.Command` is trusted only for actor attribution when it was created by `D20.Sessions`. Its `attrs` remain untrusted.

Validate:

- the event is supported
- attributes have the expected container type
- required fields exist
- scalar and nested values have correct types
- numbers and collections meet structural bounds
- external enum strings belong to a finite mapping

Normalize string keys and bounded string values. Do not use `String.to_atom/1` or equivalent unbounded conversions.

Do not check live phase, membership, current availability, or action legality here. The same payload can be structurally valid while illegal in the current game.

## Rules and Predicate Pattern

### Purpose

Centralize every decision that depends on committed game state, actor context, or the selected rulesheet.

### Predicate categories

Use distinct function shapes for distinct consumers:

| Category | Return shape | Typical consumer |
| --- | --- | --- |
| Capability query | `boolean()` | Permission and Projection |
| Authoritative requirement | `:ok | {:error, reason}` | `Rules.validate/2` and candidate resolution |
| Lookup | `{:ok, value} | :error` | Rules composition |
| Legal-choice derivation | collection or result tuple | Projection and validation |
| Candidate application | `{:ok, candidate} | {:error, reason}` | Atomic transition preparation |
| Completion predicate | `boolean()` | Game transition orchestration |

Name predicates after domain language discovered in the specification. Avoid generic helpers such as `valid?/1` when several independent invariants exist.

### Predicate properties

- Pure: do not mutate state, send messages, generate transport responses, or depend on process state.
- Total: return a defined result for unknown actors, missing data, setup, and terminal states.
- Explicit: receive all relevant context as arguments.
- Composable: small requirements combine through `with` or a similarly visible validation chain.
- Stable: return deliberate reason values used by tests and the public contract.
- Shared: permission and projection calculations reuse the same domain primitives as command validation.

Validation order is observable behavior. Put identity, phase, membership, status, and domain constraints in a deliberate order and test conflicts where more than one predicate fails.

Keep wire-map construction out of Rules. A legal-choice function should return domain values; Projection converts them to the public representation.

For multi-step candidate evaluation, thread an immutable candidate through predicates:

```elixir
with :ok <- require_context(game, command),
     {:ok, candidate} <- apply_primary_rule(game, command),
     {:ok, candidate} <- apply_follow_up_rules(game, command, candidate) do
  {:ok, candidate}
end
```

`Game` commits the returned candidate only after the full chain succeeds.

## Game State-Machine Pattern

### Purpose

Own shared committed state and define how accepted stimuli transform it.

Implement from the reviewed authoritative state model. The aggregate is the minimal sufficient record of authoritative game facts identified by that model. Together with immutable rules and explicit caller and session context, it must contain enough information to deterministically derive future behavior and every public projection. If a projection depends on a game fact that cannot be reconstructed from those inputs, store that fact in the aggregate. Do not store cached projections, other derived values, process timers, connection state, or transient UI state.

After `init/1`, mutate the aggregate only inside an accepted `dispatch/2` transition. Do not expose alternate mutation functions to Projection, Permission, channels, or a custom Server.

Implement:

- `changeset/1` for creation-time configuration
- `init/1` for initial aggregate construction
- `dispatch/2` for phase and event routing
- `finished?/1` for outer session completion
- explicit aggregate types and terminal state

Use phase-specific clauses to make coarse transition routing visible. Map each clause to modeled source and resulting state identifiers. When several modeled states share a phase, distinguish them with explicit state-dependent Rules predicates instead of inventing a phase atom for each combination or leaving the transition implicit. Within a supported phase and event, validate the normalized payload, validate Rules, then apply one complete transition.

```elixir
def dispatch(%__MODULE__{phase: :some_phase} = game, %D20.Command{event: "some_event"} = command) do
  with {:ok, command} <- Command.validate(command),
       :ok <- Rules.validate(game, command) do
    {:ok, transition(game, command)}
  end
end
```

The exact phase and event names must come from the supplied specification. The snippet defines control flow only.

Every error must preserve the original aggregate. A transition may orchestrate several pure Rules functions, but no intermediate state becomes visible. Evaluate completion at the rule-defined boundary and enter a real terminal state so `D20.Sessions.Session` can finish.

## Nested Session and Game Lifecycles

The outer session owns generic multiplayer runtime concerns:

```text
waiting_for_players -> in_progress -> finished
```

The inner Game owns domain phases. These state machines are related but not interchangeable.

- Session validates the owner for `start`.
- Game Rules decide whether the game itself is ready.
- Session tracks live members.
- Game decides whether joining, leaving, reconnecting, or late participation changes domain state.
- Rules define which participant set or snapshot is used by each in-progress completion predicate.
- Session calls `Game.finished?/1` after accepted game transitions.

Write membership semantics from the new specification. Do not inherit them from another namespace.

### Uniform session launch

Every playable game uses the same outer launch path:

```text
create session
-> waiting_for_players shell controls
-> owner sends start through SessionPanel
-> Session enters in_progress
-> shell mounts the iframe module
```

The registry selects the engine and operational iframe metadata. It must not switch lifecycle ownership or choose a game-specific lobby. Do not add fields such as `start_in_module`, slug conditionals, or waiting-phase iframe exceptions.

If a game's `start` command needs attributes, the caller-specific waiting projection exposes them as declarative `attrs`. The shared `SessionPanel` renders those descriptors and submits their values through the normal `start` channel event. Use explicit field names for nested payloads, bounded values from Ruleset, stable display order, and caller-safe defaults. For a game that uses this form, callers that cannot start and states outside the applicable waiting setup return an empty `attrs` map. Games with an empty `start` payload omit `attrs` from their runtime projections entirely.

Projected start descriptors are read-model guidance, not authority. `Command` validates the submitted structure and finite values, `Rules` validates current legality, and `Game` commits the transition. Projection must not synthesize a command or trigger start.

## Event and Server Patterns

### Client mutation command

Use for any interaction that changes committed shared state:

```text
SessionChannel
-> D20.Sessions.dispatch/3
-> selected game server
-> D20.Sessions.Session.dispatch/3
-> Game.dispatch/2
-> Command and Rules
-> one stored and broadcast Session
```

The actor id comes from `Scope`, not the payload. Rejected commands keep the previous server state and do not broadcast.

### Server-owned state-changing event

Use a custom server only when an actual time or process boundary initiates the action.

```elixir
defmodule D20.MyGame.Server do
  use D20.Game.Server

  def callback_mode, do: [:handle_event_function, :state_enter]

  def handle_event(:enter, _old_state, :scheduled_phase, _data) do
    {:keep_state_and_data, [{:state_timeout, 1_000, :scheduled_event}]}
  end

  def handle_event(:state_timeout, :scheduled_event, :scheduled_phase, _data) do
    command = %D20.Command{event: "scheduled_event"}
    {:keep_state_and_data, [{:next_event, :internal, {:dispatch, command}}]}
  end
end
```

The phase and event names and timeout source must come from the specification. The pattern provides only scheduling and dispatch.

`use D20.Game.Server` supplies startup, registry naming, calls, Presence handling, publication, idle expiry, and fallback callbacks. Add narrow clauses and never a catch-all that intercepts shared behavior.

The custom Server owns process behavior, not game state. It schedules or emits internal commands and lets the normal dispatch path produce the next aggregate. It must not call Projection to decide or trigger a mutation.

An internal state-changing event uses `actor_id: nil` and follows the same Session, Command, Rules, and Game path as other mutations. Rules must require the missing actor and reject a client actor for the same event.

State timeouts are tied to the current `:gen_statem` state. Reads, Presence events, and rejected calls that keep the phase must not duplicate them. Named idle expiry is independent. The shared internal error path keeps old state, so add explicit observability or recovery when required by the specification.

If an automatic event obtains a nondeterministic value, define one authoritative sampling point, when the sampled value becomes committed, and what a duplicate or retried event does. Tests need a controllable boundary or assertions that do not depend on one exact random result.

### Synchronous follow-up

Keep an immediate consequence of an accepted command inside the same Game transition. Do not introduce a custom process event unless ordering, time, or an external stimulus creates a real asynchronous boundary.

## Permission Pattern

Permissions translate Rules into a complete caller-specific capability map for clients. They are not the security boundary.

- Implement the repository's `D20.Permission` and policy pattern.
- Return all documented keys for every caller and lifecycle state.
- Derive results from outer session context and total Rules predicates.
- Repeat every authoritative check during command dispatch.

## Projection Pattern

Projection owns the public read model:

- explicit session envelope
- caller identity
- complete permissions
- public committed game facts
- lifecycle and game statuses, progress, and outcomes needed by the caller
- derived caller-specific legal choices
- permitted constraints and other rule-derived guidance needed by supported client workflows
- explicit redaction of private facts

Create a visibility matrix for every caller role and lifecycle state. Test both the fields a caller receives and the fields that must be absent. Do not rely only on positive projection examples to detect leaks.

Keep dependency direction `Projection -> Rules -> Ruleset`. Projection may derive legal choices through pure Rules functions, but it never validates commands or commits state.

Prefer a complete, ready-to-consume read model over low-level facts that force the client to reproduce domain rules. Supply every permitted status, choice, constraint, progress value, outcome, and other derivation required by a supported workflow. Do not require the client to infer authoritative information from event history. Leave presentation formatting, layout, animation, and ephemeral interaction state to the client. Scope completeness by caller visibility and actual workflows: never expose private facts, raw internal representation, or speculative fields merely to make the payload larger.

Treat Projection as a deterministic function of caller context and the current Session. It consumes the committed state produced by the game state machine and returns a public read model. It does not retain state between renders, trigger transitions, or feed projected values back into `Game`.

Trace every projected field to committed game state, immutable rules, or explicit caller and session context. A field that also needs prior projections, client-held history, or hidden Projection state exposes a missing authoritative input in the aggregate design.

Render Projection only from caller context and the current Session. Do not route channel events, validate interaction payloads, or construct `%D20.Command{}` values in Projection.

`D20Web.Projection.render/2` uses explicit engine routing. Add a clause for every playable engine. Its generic fallback returns the raw Session, so relying on it is a contract and data-exposure defect.

## Client State-Machine Pattern

Model an in-scope game client as a hybrid XState machine with two distinct inputs:

- the latest caller-specific Projection, which is authoritative for session and game facts, permissions, legal choices, constraints, progress, and outcomes
- explicit local state for connection, pending commands, selections, drafts, dialogs, animation, and other interaction facts that are not authoritative server state

### Hierarchy and state identity

Use the statechart hierarchy as the canonical identity of mutually exclusive modes. Put facts that answer "which mode is active?" in state nodes. Put data needed by more than one mode, such as the latest Projection, a selection, or a correlation epoch, in context. Do not mirror the same mode with a state node, a context boolean, a component store, and a tag.

Design the tree so each compound state names a meaningful behavioral scope. For example, a turn may contain `waiting`, `editing`, and `submitting`, while `editing` contains `primary` and `review`. A parent state then answers the broad question and a leaf answers the precise question.

Use local transition targets from the state node that owns the event:

| Relationship from transition source | Target shape |
| --- | --- |
| Sibling | `sibling` |
| Descendant of a sibling | `sibling.child` |
| Descendant of the current state | `.child.grandchild` |

Avoid custom state-node IDs that merely create a second naming system for the same hierarchy. Keep IDs for invoked or spawned actors that must be addressed, or for a deliberate state-node reference that cannot be expressed through a maintainable local path.

Declare an event on the narrowest compound state that contains every valid source and target. XState checks active leaf states before their parents, so a child can specialize an inherited event. Use an explicit empty transition such as `{ "game.player.view": {} }` only when that child must forbid the parent's behavior.

If one event has alternative transitions, XState evaluates them in order and takes the first enabled candidate. Put the most specific guarded case first and an unconditional fallback last. Do not treat the array as a set of transitions that all run.

### Guards, actions, and state queries

Keep guards pure, synchronous, and free of mutation or effects. Define reusable guards in `setup(...)`; keep an inline guard only when its complete condition is easier to understand at the transition. Use `and`, `or`, and `not` when composition exposes the decision more clearly than one large predicate.

Prefer transition ownership over an in-state guard. Use `stateIn(stateValue)` when a root-owned event, parallel region, or other real cross-tree decision must inspect structural state. Pass object state values such as `{ ready: { game: { turn: "submitting" } } }` so the hierarchy remains visible.

Use `snapshot.matches(stateValue)` for a structural read such as "is this exact workflow branch active?" Use a tag when a stable semantic category intentionally spans unrelated branches and should survive hierarchy refactoring. Do not add a tag that only renames one existing parent state.

Use `assign(...)` to replace context immutably after narrowing the discriminated event type. Keep external I/O in invoked actors or other actor logic and send typed events between actors. An action may orchestrate effects, but a guard must remain safe to execute repeatedly because `snapshot.can(event)` also evaluates guards.

Build the complete typed event object, including its payload, before checking availability. Use `snapshot.can(event)` to derive an affordance or filter legal local targets, then send that same event object. This keeps the component aligned with current state, event payload, and guard logic without reproducing those checks outside the machine.

### Target and transient-state semantics

A transition without `target` runs its actions and preserves the active state and descendants. Use this deliberately when a synchronization event updates context but the new data proves that an in-flight mode remains valid.

An explicit target re-resolves the targeted descendant path. A transition to the same compound state therefore resets its child state to the selected or initial descendant. Add `reenter: true` only when the compound state's entry, exit, delays, or invoked actors must restart too.

Use guarded `always` transitions for immediate internal classification after context changes. Every branch must converge on a different stable state, and no rendering or test should depend on observing the transient routing state because subscribers receive the final snapshot after eventless microsteps.

### Authoritative snapshot reconciliation

Join the D20 game-session topic at `session:<id>`, treat the join reply as the initial projection, and send every later `projection` event into the machine as a synchronization event. Replace or reconcile the authoritative slice from that payload. When local assumptions conflict with the projection, let the projection win and transition to the appropriate valid local state. On rejoin, rebuild from the new projection instead of replaying client history as authority.

Represent connection snapshots and game-session Projection snapshots as distinct discriminated events. They update different context slices: connection snapshots describe transport availability, while Projection snapshots replace server-authoritative session and game facts. Their guards and reconciliation therefore have different invalidation criteria even when both ultimately reclassify the machine.

A useful synchronization pattern is:

1. Handle each snapshot event once at the machine root.
2. Narrow its event type and update only the corresponding context slice with `assign(...)`.
3. If the machine is in a critical in-flight state, take a guarded targetless transition only when the new snapshot proves that state is still valid.
4. Otherwise target a transient classifier whose guarded `always` transitions derive the next stable state from the newly updated context.

This pattern preserves an active submission across harmless connection or Projection updates without allowing stale local workflow to survive an authoritative phase, permission, actor, or turn-epoch change.

Send player intent through channel commands from machine effects. Treat command replies as acknowledgement or rejection only, and wait for a delivered projection before moving authoritative state forward. Keep pending state local and make rejection, disconnect, retry, and resynchronization transitions explicit when the workflow can encounter them.

Use XState guards to combine local interaction facts with projected permissions and legal choices. A guard may decide whether to show or enter a client state, but it never replaces server authorization or Rules validation. Prefer XState primitives such as `setup`, `createMachine`, guards, actions, and invoked actors. Keep framework adapters thin so components render machine state and send events without hiding transition ownership behind framework-specific helpers.

Keep the machine locally complete but minimal. Represent every behaviorally distinct local state required by the workflow, while deriving values from the current state node and Projection instead of copying them into parallel stores or component variables.

Test the transition contract directly. Cover hierarchical entry and exit, guarded-candidate priority, targetless descendant preservation, targeted reset or reentry when intentional, snapshot-driven invalidation, stale reply correlation, and `snapshot.can(event)` with the same payload later sent by the UI.

## Shell Integration Pattern

| Concern | Source |
| --- | --- |
| Engine binding and launch metadata | `config/config.exs` |
| Registry validation | `lib/d20/games/registry.ex` |
| Session creation and dispatch | `lib/d20/sessions.ex`, `lib/d20/sessions/session.ex` |
| Generic waiting controls and start form submission | `assets/js/components/session_panel.svelte`, `assets/js/stores/session.ts` |
| Public projection routing | `lib/d20_web/projection.ex` |
| Channel command routing | `lib/d20_web/channels/session_channel.ex` |
| AsyncAPI serving | `lib/d20_web/plugs/async_api.ex` |
| Public contract | `priv/specs/<slug>.yaml` |
| Developer contract index | `assets/js/pages/developers.svelte` |

Creation forms and generic endpoints derive inputs from `Game.changeset/1`. Change shared controllers only when a discovered requirement cannot use the generic path.

Keep session creation inputs and waiting-session inputs distinct even though both are named attrs at their respective boundaries. Creation attrs come from `Game.changeset/1` before the process exists. When required, waiting-session attrs come from the caller-specific projection field `attrs` and are submitted by the shared shell. An empty start payload has no projected attrs. The iframe is mounted only after the outer session reaches `in_progress` or `finished`.

Cross-check code, tests, and AsyncAPI. Existing namespaces are evidence for repository patterns, not specifications for a new game's rules.
