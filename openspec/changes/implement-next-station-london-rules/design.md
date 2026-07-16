## Context

`D20.NextStationLondon.Game` is a registered `D20.Game` implementation, but `init/1` and `dispatch/2` return `:not_implemented`. The shell already provides generic session creation, owner-only start, live membership, `D20.Game.Server`, explicit projection routing, registry metadata, and AsyncAPI serving. The game namespace must own all Next Station: London rules without changing those generic contracts.

The reviewed rule sources are:

- Blue Orange's current English rulebook: <https://blueorangegames.eu/wp-content/uploads/2023/05/NextStationLondon-Rules-EN.pdf>
- Blue Orange's official map: <https://blueorangegames.eu/wp-content/uploads/2022/05/NextStation-LondonMap.pdf>
- The existing local rulebook copies at `assets/public/rules/next_station_london.pdf` and `priv/static/rules/next_station_london.pdf`
- The supplied local map at `priv/static/rules/next_station_london_map.pdf`, whose SHA-256 is `3a28e0ab5d4309ae1bfc80fb78bbf5cd931133e5a3e52894663a17cf1ccc9cea`, identical to the official map download

The PDF files are design inputs, not runtime data stores. The engine must use reviewed static Elixir data and must not parse, rasterize, or infer rules from a PDF while a session is running.

## Goals / Non-Goals

**Goals:**

- Specify the complete 1 to 4 player base game, solo mode, Shared Objectives, and Pencil Powers.
- Make the map and all scoring tables exact, reviewable, and independently testable before transition logic is implemented.
- Keep random card preparation server-owned, commit every sampled value once, and keep future cards hidden.
- Make section validation, simultaneous progress, line scoring, final scoring, permissions, and projections server-authoritative.
- Preserve the generic outer session lifecycle and propagate the inner terminal phase through `D20.Game.finished?/1`.
- Implement the separate Next Station: London iframe client against the caller-specific projection without moving authoritative rule calculations into Svelte.

**Non-Goals:**

- Do not add game-specific UI to the D20 shell; the playable UI belongs to the separate `next_station_london` iframe repository.
- Do not add persistence, replay storage, matchmaking, bots, deadlines, automatic player passes, or player removal after start.
- Do not change the generic session command envelope, routes, iframe sandbox, or another game namespace.
- Do not implement modules from Next Station: Tokyo or cross-game component compatibility.
- Do not reproduce publisher artwork as authoritative rule logic.

## Decisions

### 1. Scope includes every module in the London rulebook

Session creation will accept top-level `objectives` and `powers` booleans, both defaulting to `false`. The aggregate will not contain a `variants` wrapper. It normalizes disabled modules to `objectives: nil` and `powers: nil`, and enabled but not yet prepared modules to `objectives: []` and `powers: %{}`. First-round preparation replaces those empty values with the two selected objective ids and the complete color-to-power assignment. Base construction and scoring always apply. A one-player session uses the same aggregate and transition graph as multiplayer, then adds the solo achievement result and a 10 point final rating penalty for each enabled advanced module.

Alternative considered: keep a `variants` wrapper with separate `shared_objectives` and `pencil_powers` flags. That would duplicate module state after the selected objectives and assigned powers are committed. Implementing only the base multiplayer game was also rejected because it would leave advertised player count and rulebook modules unsupported and force later changes to creation attrs, aggregate shape, scoring, and AsyncAPI.

### 2. `Ruleset` owns one normalized static map and fixed lookup tables

Use stable string station ids `r<row>c<column>`, with rows and columns numbered `0` through `9`. Each station entry contains `id`, `row`, `column`, `symbol`, `district`, `tourist`, and optional `departure_color`. Symbols are `circle`, `square`, `triangle`, `pentagon`, and the central `wild` symbol. Colors are `purple`, `blue`, `pink`, and `green`.

The exact station transcription is below. `C`, `S`, `T`, `P`, and `W` mean circle, square, triangle, pentagon, and central wild. `*` marks a tourist site and a color in parentheses marks a departure station.

| Row | Stations by column |
| --- | --- |
| 0 | `c0 P`, `c1 T`, `c2 S`, `c4 T`, `c5 C`, `c7 T`, `c9 C` |
| 1 | `c1 P`, `c3 S`, `c6 P*`, `c8 S`, `c9 P` |
| 2 | `c0 C`, `c3 T(green)`, `c6 S`, `c9 T` |
| 3 | `c0 S*`, `c2 P`, `c4 T`, `c5 W*`, `c6 C`, `c7 C(pink)`, `c9 S` |
| 4 | `c1 T`, `c2 S`, `c4 P`, `c5 S`, `c8 P` |
| 5 | `c0 P`, `c2 S(purple)`, `c4 C`, `c7 C` |
| 6 | `c3 P`, `c4 T`, `c6 S`, `c7 T`, `c9 T*` |
| 7 | `c0 C`, `c2 S`, `c3 C`, `c5 P(blue)`, `c8 C`, `c9 P` |
| 8 | `c1 C`, `c6 P`, `c8 T` |
| 9 | `c0 T`, `c1 S`, `c3 P`, `c4 C*`, `c5 T`, `c7 C`, `c9 S` |

This yields 53 stations: 13 of each ordinary symbol and one central wild station. The tourist sites are `r1c6`, `r3c0`, `r3c5`, `r6c9`, and `r9c4`. Departure stations are green `r2c3`, pink `r3c7`, purple `r5c2`, and blue `r7c5`.

The 9 main districts use the row bands `0..2`, `3..6`, and `7..9` and column bands `0..2`, `3..6`, and `7..9`. The four corner stations are removed from those bands and become one-station secondary districts:

| District | Station count |
| --- | ---: |
| `northwest` | 4 |
| `north` | 6 |
| `northeast` | 4 |
| `west` | 6 |
| `central` | 9 |
| `east` | 6 |
| `southwest` | 4 |
| `south` | 6 |
| `southeast` | 4 |
| `outer_northwest` at `r0c0` | 1 |
| `outer_northeast` at `r0c9` | 1 |
| `outer_southwest` at `r9c0` | 1 |
| `outer_southeast` at `r9c9` | 1 |

A legal potential section joins a station to the first station encountered on one of the eight horizontal, vertical, or 45 degree diagonal rays. The explicit normalized edge set must contain 155 unique undirected sections. This nearest-station invariant prevents any edge from passing through an intermediate station and provides exact geometry for crossing checks.

Each edge stores a `crosses_thames` flag. The 24 flagged edges are:

`r2c0-r4c2`, `r3c0-r5c0`, `r3c0-r4c1`, `r1c1-r4c1`, `r3c2-r4c1`, `r3c2-r4c2`, `r4c2-r4c4`, `r3c4-r5c2`, `r5c2-r5c4`, `r2c3-r6c3`, `r5c4-r6c3`, `r4c4-r6c6`, `r5c4-r6c4`, `r5c4-r5c7`, `r3c7-r6c4`, `r3c5-r5c7`, `r4c5-r7c5`, `r4c5-r6c7`, `r3c6-r6c6`, `r3c6-r6c9`, `r3c7-r5c7`, `r4c8-r5c7`, `r4c8-r7c8`, and `r3c9-r6c9`.

`Ruleset` also owns:

- the 11 unique Station cards: one Street and one Underground card for each ordinary symbol, one Street and one Underground Joker, and one Street Railroad Switch
- Underground card classification and the fifth-Underground round-end predicate
- tourist score track `%{0 => 0, 1 => 1, 2 => 2, 3 => 4, 4 => 6, 5 => 8, 6 => 11, 7 => 14, 8 => 17, 9 => 21, 10 => 25}`
- interchange values `%{2 => 2, 3 => 5, 4 => 9}`
- five Shared Objective definitions and four Pencil Power definitions
- solo rating bands and fixed module penalties

Static validation must reject duplicate ids, missing station references, non-canonical edges, an edge that is not horizontal, vertical, or 45 degree diagonal, an edge that skips a station, invalid departure or tourist references, unbalanced symbol counts, incorrect district membership, and an invalid deck or scoring table.

Alternative considered: keep only image coordinates and let callers infer adjacency. That would duplicate legality logic in backend and client code and would make the 24 Thames scoring edges unreviewable.

### 3. The game uses one unordered players map and simultaneous instruction resolution

The aggregate stores accepted gameplay membership only in `players`, keyed by participant id. It has no parallel participant set or player-order field. A setup join is idempotent and adds at most four map entries. A setup leave removes that entry. Start freezes the map by phase: after start, `join` and `leave` only update outer session membership, reconnecting actors retain the state at their existing key, and new actors are spectators. Round completion always waits for every entry in the frozen map, including a disconnected player. No rule sorts players or relies on map enumeration order. There is no automatic pass or forfeit.

Each player owns four colored line graphs. The current line starts with its departure station as its only node. That node belongs to the colored line even if the player passes every instruction, so it participates in district, interchange, and objective calculations. A player is `pending` or `submitted` for the current shared instruction. Accepted sections are committed immediately to that player's graph, but the next instruction is not exposed until every frozen participant has drawn or passed.

For every game, first-round preparation samples a four-color `pencil_cycle` and commits one distinct `pencil_offset` into each player value. In round `r`, that player uses `pencil_cycle[(pencil_offset + r - 1) mod 4]`. The preparation payload identifies offsets by participant id and never derives them from map traversal. A solo game receives offset 0 and therefore follows one random four-color cycle. A multiplayer game assigns the shuffled player ids offsets `0` through `player_count - 1`, which gives every player every color exactly once and gives all active players distinct colors in each round without introducing a roster order. Pencil assignment is automatic and is not a start-time player choice.

Alternative considered: derive progress from current Presence members. A disconnect would then change rule outcomes or unblock a round, which is both exploitable and inconsistent with a fixed paper game.

### 4. The phase and transition graph is explicit

| Current phase | Stimulus | Required predicates | Atomic effects | Next phase | Stable errors |
| --- | --- | --- | --- | --- | --- |
| `setup` or `ready` | `join` | valid actor, capacity available or duplicate | add player once and recompute readiness | `setup` or `ready` | `player_limit_reached` |
| `setup` or `ready` | `leave` | actor identity | remove player before start and recompute readiness | `setup` or `ready` | none for an absent actor |
| `ready` | `start` | outer owner check, owner joined, 1 to 4 players, empty payload | freeze the players map and enter randomized preparation | `preparing_round` | `invalid_command`, `not_joined`, `not_ready` |
| `preparing_round` | system `prepare_round` | actor is nil, payload is a valid sampled setup for this round | commit hidden deck, first-round random pencil cycle and participant offsets, enabled module assignments, reveal the first instruction, mark all players pending | `build` | `system_only`, `invalid_system_setup` |
| `build` | `draw_sections` | participant is pending, payload and power are legal, all section predicates pass | commit one atomic action and mark caller submitted | `build` | rule-specific errors |
| `build` | `pass` | participant is pending, optional station-count power is legal | commit the optional power and mark caller submitted | `build` | `not_joined`, `already_submitted`, power errors |
| `build` | last required submission, round continues | every player map entry is submitted and fewer than five Underground cards are revealed | reveal the next instruction from the committed deck and reset statuses | `build` | none after accepted action |
| `build` | last required submission on the fifth Underground card, rounds 1 to 3 | every player map entry is submitted | score current lines, cap tourist marks, increment round, rotate colors, clear round-only state | `preparing_round` | none after accepted action |
| `build` | last required submission on the fifth Underground card, round 4 | every player map entry is submitted | score lines, network, objectives, tie data, and solo result | `finished` | none after accepted action |
| `finished` | any game command | terminal state | no mutation | `finished` | `finished` |

Line scoring and round advancement are synchronous consequences of the last accepted participant action. Only random round preparation crosses the custom process boundary.

### 5. Command structure is bounded before state-dependent validation

| Event | Actor class | Payload | Allowed phases | State-changing | Stable errors |
| --- | --- | --- | --- | --- | --- |
| `join` | authenticated actor | generic member attrs are ignored by game rules | `setup`, `ready`, in progress reconnect or spectator join | yes before start, no game change after start | `player_limit_reached` |
| `leave` | authenticated actor | empty | `setup`, `ready`, in progress disconnect | yes before start, no game change after start | none for absent actor |
| `start` | outer session owner | empty map | `ready` | yes | `invalid_command`, `not_joined`, `not_ready` |
| `prepare_round` | system actor with `actor_id: nil` | exact deck permutation and round-one assignments | `preparing_round` | yes | `system_only`, `invalid_system_setup` |
| `draw_sections` | frozen player | one or two `{from, to}` section maps, optional finite power kind, optional `chosen_symbol`, optional station-count target | `build` | yes | `invalid_command` plus rule errors |
| `pass` | frozen player | optional station-count power target only | `build` | yes | `invalid_command` plus membership, status, and power errors |

`D20.NextStationLondon.Command` validates map containers, required keys, list bounds, station ids, finite color, symbol, objective, and power values, and exact system setup shapes. It never accepts actor identity in attrs and never creates atoms from external strings. Phase, membership, pending status, current pencil, power assignment, geometry, occupancy, and scoring legality remain in `Rules`.

Phase and event gating precede payload validation. An unsupported event in a valid non-terminal phase returns `unknown_command`; a known event in the wrong phase returns `invalid_phase`; terminal state always returns `finished`.

### 6. `Rules` owns state-dependent legality and candidate application

| Predicate or operation | Inputs | Return shape | Consumers | Failure precedence |
| --- | --- | --- | --- | --- |
| `ready_to_start?/1` | game | boolean | `Game`, `Permission` | total query |
| `participant?/2` | game, actor id | boolean | `Rules`, `Permission`, `Projection` | before status and action checks |
| `submit_allowed?/2` | game, actor id | boolean | `Permission`, `Projection` | total query |
| `require_system_actor/1` | command | result | round preparation | before payload consistency |
| `legal_origins/2` | game, player | station ids | projection and section validation | derived from line shape and switch effect |
| `legal_sections/3` | game, player, effective instruction | section candidates | projection and authoritative validation | after actor and status checks |
| `apply_section_candidate/4` | ruleset, network, section, instruction | candidate network result | compound action validation | geometry, revisit, duplicate, crossing, destination |
| `apply_power_candidate/4` | game, player, power, action | candidate player result | compound action validation | assignment and one-use checks before effect checks |
| `turn_complete?/1` | game | boolean | `Game` | every entry in `game.players` only |
| `score_line/2` | ruleset, colored line | line score | round resolution | pure calculation |
| `score_network/2` | ruleset, player | final score | game finish | after all four line scores |
| `achieved_objectives/2` | objective ids, player network | objective ids | final scoring and projection | pure calculation |

The complete validation order for player actions is phase, actor membership, pending status, payload normalization, current instruction, power availability, section count, origin, known potential edge, same-line station reuse, network edge reuse, geometric crossing, destination symbol, and compound-action consistency. All steps operate on an immutable candidate. No section or power use is committed unless the entire submitted action succeeds.

### 7. Network geometry is authoritative

Without a switch effect, the first section starts at the colored departure station and later sections start at any degree-one endpoint of the current colored line. An effective Railroad Switch allows the submitted section to start at any station already on that colored line. Future ordinary sections can extend from every degree-one endpoint created by a branch.

A candidate target cannot already belong to the same colored line. An undirected section already used by any color cannot be reused. A candidate segment cannot geometrically intersect any existing segment unless the intersection is a station that is an endpoint of both segments. Different colored lines may share stations, creating interchanges, but never share or cross sections.

The current destination must match the revealed ordinary symbol. A Joker accepts any ordinary destination symbol. The central wild station always matches. A Railroad Switch card immediately consumes the following card as its destination card. On construction turns 1 and 2, the branch privilege is disabled but the paired destination card still resolves as an ordinary endpoint extension. If that paired card is the fifth Underground card, the combined instruction is the final instruction of the round.

Alternative considered: accept client-computed polylines. That would allow clients to bypass the printed potential-section graph and make intersection validation dependent on untrusted drawing coordinates.

### 8. A custom server owns random round preparation only

`D20.NextStationLondon.Game` declares `server: D20.NextStationLondon.Server`. On entry to `preparing_round`, the server samples exactly one valid deck permutation. On round 1 it also samples the pencil cycle for every game, an explicit participant-id-to-offset assignment, two Shared Objectives when `objectives` is enabled, and a bijection from four powers to four pencil colors when `powers` is enabled. A solo assignment is exactly `%{player_id => 0}`. Multiplayer offsets are `0` through `player_count - 1` assigned after shuffling participant ids. The server dispatches one actorless `prepare_round` command through the normal Session and Game pipeline.

The aggregate commits the sampled deck before exposing its first instruction. Subsequent reveals pop from that committed deck synchronously after all participants submit, so retries cannot resample a card. A repeated `prepare_round` is rejected outside `preparing_round`. Game tests can dispatch fixed valid permutations directly; server tests assert permutation integrity, exactly-once preparation, client-actor rejection, and compatibility with idle expiry without depending on one random order.

The custom server must not silently leave a session in `preparing_round` if an internally generated payload is rejected. Its narrow preparation handler must stop with an observable invalid-random-setup reason. It inherits standard read, Presence, broadcast, client dispatch, and idle behavior for every other event.

Alternative considered: let the physical-round controller reveal cards through client commands. Card reveal contains no player decision in a digital session and would add an avoidable blocking role, authorization path, and race condition.

### 9. Pencil Powers are atomic modifiers of the current line

Each enabled power is publicly bound to one pencil color for the entire game and can be used once by the holder of that color in each round. The current line records whether its power was used.

- `double_section` requires exactly two sequentially legal sections. Both destinations match the revealed symbol. For a revealed Joker, both use one declared ordinary `chosen_symbol`; the central wild station can satisfy that symbol.
- `joker` treats the current destination as a Joker and still validates every other construction rule.
- `railroad_switch` allows the current section to originate at any station of the current line without drawing another card.
- `double_station` records one station already on the current line. That station counts twice only when finding this line's largest within-district station count. It does not duplicate tourist, interchange, objective, or later-line credit.

When a current instruction already has an effective Railroad Switch, only the first section of `double_section` receives the any-line-station origin privilege. The second section is an ordinary extension from a degree-one endpoint of the candidate line after the first section.

The station-count power can be attached to either a `draw_sections` or `pass` action on any instruction of the round. For a draw, its target is checked after the submitted sections are applied, so a station reached by the same atomic action is eligible. Other powers require `draw_sections`. Power use and all submitted sections commit atomically.

### 10. Scoring uses explicit continuous tables

For each colored line, calculate:

`district_count * maximum_station_count_in_one_district + 2 * thames_crossing_count`

Stations, not empty geometry crossed by a segment, determine district presence and within-district count. The preprinted departure station is the first node of its color and counts even when the line has no sections. The station-count Pencil Power can increase exactly one district count by one for that line. Each tourist site belongs to the line at most once. Cumulative tourist marks are capped at 10 and excess visits are ignored, producing the fixed 0 to 25 track score.

At finish, each station used by exactly 2, 3, or 4 distinct colored lines scores 2, 5, or 9 points. Final multiplayer score is four line scores plus tourist score plus interchange score plus 10 points for each achieved enabled Shared Objective. The highest total wins; tied players compare their highest single-line score; a remaining tie is shared.

The publisher's solo graphic uses strict inequality glyphs that leave boundary values visually ambiguous. The engine uses continuous bands: less than 90, 90 through 105, 106 through 120, 121 through 135, 136 through 150, and greater than 150. Before selecting the band, subtract 10 for Shared Objectives when enabled and 10 for Pencil Powers when enabled. Shared Objective bonuses remain part of the score before that module penalty.

### 11. Projection is explicit and future deck order is always hidden

`D20.NextStationLondon.Projection` renders the standard session envelope, caller id, complete permissions, top-level `objectives` and `powers`, current round and instruction, revealed cards, public pencil assignments, the participant-id-keyed `players` map, every committed colored network, statuses, line scores, final score breakdowns, objective results, winner and tie data, and solo rating when applicable. It exposes no roster-order field and does not sort or number players to reconstruct one.

It also derives caller-only legal options from `Rules`:

- base legal sections for the current instruction
- legal wildcard and switch alternatives when the caller's assigned power permits them
- legal two-section sequences for `double_section`
- eligible stations for `double_station`

The aggregate's remaining deck and future reveal order are omitted for every caller. Submitted participants and spectators receive empty legal options. Raw Session or Game serialization is not a supported Next Station: London projection.

| Caller role | Lifecycle | Visible | Hidden | Derived |
| --- | --- | --- | --- | --- |
| owner participant | waiting | objectives, powers, members, players map, readiness | no hidden deck exists | `can_start_game` |
| other participant | waiting | same public setup facts | no hidden deck exists | all permissions false except applicable setup affordances |
| pending participant | preparing or build | current and prior public facts, all committed networks and statuses | remaining deck and future card order | own legal options, `can_draw_sections`, `can_pass` |
| submitted participant | build | same public committed facts | remaining deck and future card order | empty options and submit permissions |
| spectator or late member | in progress | all public game facts | remaining deck and all participant-only options | empty options and mutation permissions |
| any existing caller | finished | full score breakdown, objectives, winners, tie data, solo rating | unused deck order | all mutation permissions false |

Permission keys are `can_start_game`, `can_draw_sections`, and `can_pass`. Power availability is represented in caller options because it is part of the same authoritative action, not a separate authorization boundary.

### 12. Shell, contract, and iframe client integration stay narrow

Implementation will keep the existing slug, BGG id, engine module, and iframe sandbox, set the registry status to `in_progress`, keep launch behind the shared non-production gate, add explicit `D20Web.Projection.render/2` routing, and add `priv/specs/next-station-london.yaml`. The catalog renders this status as `Soon`. The contract must cover the `objectives` and `powers` creation attrs, the empty start payload, top-level runtime projection fields, draw, pass, replies, stable errors, permissions, automatic preparation semantics, the unordered players map, and the hidden-deck guarantee. Creation form descriptors remain at the pre-session page boundary and are not projected at runtime because Next Station requires no game-specific start fields. The shared `SessionPanel` sends the ordinary empty `start` event through the same outer lifecycle used by every game. The developer contract index and registry, session, channel, shell start behavior, and contract-serving tests must be updated together.

The separate `/home/max/apps/next_station_london` repository consumes the post-start contract through `@rvct/d20sdk`. Its store forwards `draw_sections` and `pass` without recalculating legality. The caller-specific option sets drive interactive board overlays and power controls, including correlated Double Station section targets and complete Double Section sequences. The existing bundled board SVG remains presentation data, while stable station ids and section endpoints come from the projection. The client exposes preparing, pending, submitted, spectator, and finished states, score and outcome read models, keyboard-operable route choices, responsive layout, browser interaction tests, and a production D20 endpoint.

## Risks / Trade-offs

- [Map transcription error] -> Assert 53 stations, 13 of each ordinary symbol, 5 tourist sites, 4 departures, district counts, 155 unique edges, and the exact 24 Thames edges, then test representative long and diagonal sections against the official PDF.
- [A legal section crossing is misclassified] -> Keep integer station geometry and a single pure segment-intersection predicate with fixtures for shared-station intersections, empty-grid crossings, duplicate edges, and non-crossing neighbors.
- [A disconnected participant stalls a round] -> Preserve the frozen physical-game participant set, expose pending status, and document that reconnect is required; do not silently alter scores with an automatic pass.
- [Automatic setup is duplicated or silently rejected] -> Tie scheduling to `preparing_round` state entry, make `prepare_round` phase-idempotent, and terminate observably on invalid generated setup.
- [Projection leaks future cards through raw serialization] -> Add explicit routing and negative tests for `remaining_deck`, full deck permutations, and future instructions for participants and spectators.
- [Advanced actions create partial state] -> Apply powers and one or two sections to an immutable candidate and commit only after every predicate succeeds.
- [Solo score boundaries in the graphic are inconsistent] -> Use the continuous interpretation documented above and make every boundary a focused test.
- [Preview precedes client readiness] -> Land engine, AsyncAPI, projection, separate client integration, and their tests together before exposing the `Soon` preview outside production.

## Migration Plan

1. Add `Ruleset` data and integrity tests while the placeholder remains non-playable.
2. Add bounded `Command` parsing and pure `Rules` predicates with fixed deck and map fixtures.
3. Replace the placeholder with the embedded aggregate and full transition tests.
4. Add the custom preparation server and its exactly-once and failure-path tests.
5. Add Permission, Projection, session, channel, and negative visibility tests.
6. Add the AsyncAPI contract and developer index coverage.
7. Integrate the separate Svelte iframe client and validate projection-driven commands in a real browser.
8. Mark the registry entry `in_progress` only after all focused and broad checks pass in both repositories; keep production launch disabled through the shared gate.

Rollback reverses the registry status, contract, projection routing, namespace implementation, and any source map asset. No database or persisted-state rollback is needed. Running in-memory sessions are disposable and must be restarted across deployment.

## Open Questions

- No rule question blocks implementation. The switch behavior on turns 1 and 2, tourist cap, solo boundary bands, and automatic digital pencil assignment use the explicit interpretations above.
- The iframe client consumes complete Double Section option sequences directly and keeps only the current local selection in component state.
- Asset work must decide whether to replace the existing imposed local rulebook with the current 18-page publisher edition. Runtime rule behavior does not depend on serving either PDF.
