## 1. Static Ruleset and Map Data

- [x] 1.1 Add `D20.NextStationLondon.Ruleset` types and query functions for colors, symbols, cards, Shared Objectives, Pencil Powers, and fixed scoring tables.
- [x] 1.2 Encode the exact 53-station inventory, 13 district memberships, 5 tourist sites, central wild station, and 4 departure stations from the reviewed official map.
- [x] 1.3 Encode the canonical 155-edge potential-section graph with integer geometry and the exact 24 Thames crossing flags.
- [x] 1.4 Add static integrity validation for station ids, symbol balance, district counts, special references, canonical nearest-station edges, deck permutations, and scoring-table coverage.
- [x] 1.5 Add focused Ruleset tests for every station row, district and symbol counts, special station ids, representative short and long edges, all Thames edges, and invalid static fixtures.
- [x] 1.6 Add focused Ruleset tests for the 11-card deck, fifth-Underground detection, tourist track, interchange values, objective values, solo bands, and module penalties.

## 2. Command Boundary and Dynamic Rules

- [x] 2.1 Add `D20.NextStationLondon.Command` validation and finite normalization for `join`, `leave`, empty `start`, actorless `prepare_round`, `draw_sections`, and `pass` payloads without accepting identity attrs or creating unbounded atoms.
- [x] 2.2 Add Rules predicates for readiness, setup capacity, frozen participation, pending submission, system-only preparation, automatic pencil setup, and deliberate error precedence.
- [x] 2.3 Add round-setup validation for exact deck permutations, multiplayer pencil cycles, participant-id-keyed distinct pencil offsets, enabled objective selection, and enabled power bijections.
- [x] 2.4 Add pure instruction derivation for normal cards, Jokers, paired Railroad Switch cards, first-two-instruction switch suppression, reveal history, and fifth-Underground round end.
- [x] 2.5 Add legal-origin, destination-symbol, central-wild, static-edge, same-line revisit, and network edge-reuse predicates.
- [x] 2.6 Add pure segment-intersection validation that allows common station endpoints and rejects empty-grid crossings, duplicate edges, and overlaps across every color.
- [x] 2.7 Add immutable candidate application for ordinary sections, passing, Double Section, Joker, Railroad Switch, and Double Station so all compound actions commit atomically or not at all.
- [x] 2.8 Add frozen-participant completion, line scoring, tourist capping, interchange scoring, Shared Objective evaluation, multiplayer outcome, and solo rating functions.
- [x] 2.9 Add Command and Rules tests for malformed containers and fields, unknown finite values, conflicting failures, stale or repeated submissions, every stable error, and unchanged candidates on failure.

## 3. Game Aggregate and State Machine

- [x] 3.1 Replace the placeholder with a typed JSON-encodable Ecto embedded aggregate, top-level `objectives` and `powers` state fields without a variants wrapper, and a creation changeset for their boolean attrs.
- [x] 3.2 Implement `players` as the sole participant-id-keyed roster, setup join, setup leave, readiness, owner-player start validation, frozen map membership, automatic pencil rotation, and in-progress reconnect and spectator behavior without introducing a roster order or changing generic Session contracts.
- [x] 3.3 Implement actorless round preparation that commits sampled pencil cycles, participant-id-keyed pencil offsets, enabled objective and power assignments, and the hidden deck exactly once, reveals the first effective instruction, and marks frozen players pending.
- [x] 3.4 Implement phase-gated `draw_sections` and `pass` transitions, immediate committed network updates, per-instruction statuses, and synchronous next-instruction reveal after the final participant submits.
- [x] 3.5 Implement fifth-Underground round resolution, line and tourist scoring, round increment, four-color rotation, round-only power cleanup, and transition back to preparation for rounds 2 through 4.
- [x] 3.6 Implement round 4 final scoring, objectives, solo penalties and bands, multiplayer winners and tie breakers, explicit finished phase, and `finished?/1` propagation.
- [x] 3.7 Add Game tests for the complete transition graph, fixed deck sequences, 1 through 4 players, pass-only and branched rounds, all scoring boundaries, every terminal outcome, and old-state preservation for all rejected commands.

## 4. Automatic Round Preparation Server

- [x] 4.1 Add `D20.NextStationLondon.Server` with narrow `preparing_round` state-entry scheduling and one actorless `prepare_round` dispatch using valid sampled static values.
- [x] 4.2 Make invalid internally generated setup terminate with an observable reason while preserving inherited get, client dispatch, Presence, broadcast, and idle-expiry behavior for every other event.
- [x] 4.3 Add custom-server tests for selected engine module, exact deck permutation, first-round assignments, client actor rejection, exactly-once scheduling, duplicate prevention, internal failure, publication, and idle-timeout coexistence.

## 5. Permission and Projection

- [x] 5.1 Add `D20.NextStationLondon.Permission` with complete caller-specific `can_start_game`, `can_draw_sections`, and `can_pass` booleans derived from Rules in waiting, preparing, build, submitted, spectator, disconnected, and finished states.
- [x] 5.2 Add an explicit `D20.NextStationLondon.Projection` session envelope with top-level objectives and powers, current public instruction history, public pencil assignments, the participant-id-keyed players map without roster order, networks, statuses, score breakdowns, outcomes, and solo result.
- [x] 5.3 Add caller-only derived base sections, wildcard alternatives, switch alternatives, Double Section sequences, and Double Station targets from the same authoritative Rules predicates.
- [x] 5.4 Add projection and permission tests for owners, participants, submitted players, late spectators, reconnects, and terminal callers, including negative assertions for remaining deck, full permutations, future cards, and other callers' options.
- [x] 5.5 Route Next Station: London explicitly through `D20Web.Projection.render/2` and prove the generic raw-Session fallback is never used for this engine.

## 6. Runtime, Contract, and Catalog Integration

- [x] 6.1 Add `priv/specs/next-station-london.yaml` covering `objectives` and `powers` creation attrs, top-level runtime fields, the unordered players map, start, draw, pass, automatic preparation semantics, replies, stable errors, permissions, projections, scoring, advanced modules, and hidden future cards.
- [x] 6.2 Add Next Station: London to the developer contract index, use the shared `SessionPanel` without game-specific start fields, and update focused frontend tests without adding game-specific shell branches.
- [x] 6.3 Add Session and channel tests for creation, join, start ownership, automatic preparation, accepted storage and broadcast, rejected non-broadcast, simultaneous completion, reconnect, spectator projection, and game-to-session finish.
- [x] 6.4 Add registry and contract-serving tests while retaining slug `next-station-london`, engine module, BGG id `353545`, and existing sandbox policy.
- [x] 6.5 Set the existing registry entry to `in_progress` only after the engine, explicit projection, AsyncAPI contract, and integration tests are complete; render it as `Soon` and keep launch available only outside production through the shared gate.
- [x] 6.6 Confirm the official publisher map does not need to be served because the game client bundles its own board asset; leave generated and user-provided static output untouched.

## 7. Separate Game Client

- [x] 7.1 Add `@rvct/d20sdk` integration, exact post-start projection and command types, caller-specific session reducers, action errors, and spectator network selection in `/home/max/apps/next_station_london`.
- [x] 7.2 Render committed colored lines, doubled stations, current selections, and keyboard-operable legal section overlays over the bundled official board asset without calculating legality in the client.
- [x] 7.3 Add instruction history, automatic preparation, simultaneous submission states, pass and draw controls, all four Pencil Power workflows, objectives, scoring, outcomes, reconnect feedback, and responsive layouts.
- [x] 7.4 Add browser tests for post-start SDK command forwarding, spectator network selection, ordinary section submission, keyboard interaction, and correlated Double Station targets.
- [x] 7.5 Configure the standalone and production D20 endpoint, production build argument, Compose development value, CI Docker build argument, client validation commands, and source documentation.

## 8. Validation

- [x] 8.1 Run `mix format` on every touched Elixir and test file and verify no unrelated formatting churn.
- [x] 8.2 Run `mix test test/d20/next_station_london/` for static data, command, rules, reducer, server, permission, and projection behavior.
- [x] 8.3 Run `mix test test/d20/sessions/session_test.exs test/d20/sessions_test.exs test/d20_web/projection_test.exs test/d20_web/channels/session_channel_test.exs` for session and public event integration.
- [x] 8.4 Run `mix test test/d20/games/registry_test.exs test/d20_web/plugs/async_api_test.exs` for activation and contract serving.
- [x] 8.5 From `assets/`, run `bun run test -- js/pages/game_pages.test.ts` after changing the developer contract index.
- [x] 8.6 Run `mix assets.lint`, `mix assets.test`, and `mix typecheck` for changed public contract and developer-page types.
- [x] 8.7 In `/home/max/apps/next_station_london`, run `pnpm run check`, `pnpm run test`, and a production `pnpm run build` with `VITE_D20_ENDPOINT` configured.
- [x] 8.8 Run `openspec validate implement-next-station-london-rules --strict` and resolve every artifact error.
- [x] 8.9 Run D20 `just check` before activation and record any unrelated pre-existing blocker with the exact failing command.

## 9. Automatic Pencil Assignment Follow-up

- [x] 9.1 Remove the solo pencil-order start form and payload, sample and commit the pencil cycle and participant offsets for every game during round-one preparation, update the public contract, client types, game-creation skill documentation, and focused tests, and validate the complete launch flow.

## 10. Runtime Projection Cleanup

- [x] 10.1 Omit declarative `attrs` from the Next Station: London runtime projection because its `start` payload is empty, retain creation attrs only in the pre-session form boundary, update the public contract, standalone client, game-creation skill guidance, and focused tests, and validate both repositories.
