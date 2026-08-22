## Context

Next Station: London currently mixes domain phases with service milestones. `ready` caches a condition already computed from setup state, `preparing_round` names the server's randomization work, and `build` contains the shared simultaneous player turn. The generic `Session` lifecycle remains responsible for waiting, in-progress, and finished shell behavior; the game aggregate needs a separate machine whose phases explain the game itself.

The aggregate must remain deterministic. Random deck, pencil, objective, and power assignments are generated at the custom server boundary and committed through actorless commands. The separate Svelte client consumes caller-specific projections and must not infer reveal timing, legality, or round advancement.

## Goals / Non-Goals

**Goals:**

- Expose only `setup`, `reveal`, `turn`, and `finished` as game phases.
- Keep readiness derived and preserve server-owned randomization.
- Make every reveal an explicit aggregate transition before the simultaneous turn.
- Align public command and permission vocabulary around `draw` and `pass`.
- Preserve existing drawing, advanced-module, scoring, hidden-deck, and session-lifecycle behavior.

**Non-Goals:**

- Reproduce every instantaneous rulebook operation as a persistent phase.
- Add a player-controlled ready step, setup form, deadline, automatic pass, or roster change after start.
- Change deck composition, random sampling, legal section calculation, scoring, or generic session phases.
- Support compatibility with in-flight preview sessions serialized with removed phases.

## Decisions

### 1. Readiness is a setup predicate, not a phase

`Game.init/1`, setup joins, and setup leaves keep `phase: :setup`. `Rules.ready_to_start?/1` remains the single readiness query used by start validation and `can_start_game`. An accepted `start` sets round 1 and enters `:reveal`.

This avoids two aggregate states with identical legal game behavior. A separate `:ready` phase was rejected because it only mirrors roster-derived eligibility and creates transitions unrelated to the rules.

### 2. Reveal is a deterministic aggregate transition with randomness at the server boundary

Entry to `:reveal` schedules one actorless `reveal` command. At the start of a round, the server supplies a shuffled deck and, for round 1, the sampled pencil cycle, participant offsets, objectives, and powers. Between instructions in the same round, the command has an empty payload and consumes the already committed remaining deck.

An accepted reveal commits any new-round setup, exposes exactly one effective instruction, marks every frozen player pending, and enters `:turn`. Invalid generated setup terminates the session with the existing observable internal-setup failure semantics.

Keeping `reveal` explicit provides a meaningful state for a projection and for server scheduling while preserving deterministic command replay. Generating randomness inside the aggregate was rejected because the same command could produce different state. Retaining `prepare_round` was rejected because preparation is an implementation action and cannot represent ordinary between-turn reveals.

### 3. Every completed shared turn enters reveal before another instruction

During `:turn`, each frozen pending player may submit one `draw` or `pass`. If players remain pending, the aggregate stays in `:turn`. The final submission enters `:reveal` when another instruction or another round is required, and enters `:finished` after final scoring in round 4.

For a normal instruction, the aggregate preserves the remaining committed deck and reveal history. At a round boundary it scores the current line, increments the round, and clears round-only deck and draw state before entering `:reveal`. A reveal projection exposes public history but sets `current_instruction` to null and grants no mutation permission; only a turn projection exposes an active instruction and caller options.

Directly revealing the next instruction inside the last player's command was rejected because it skips the phase the public model claims exists and combines two separately explainable domain transitions.

### 4. Public action vocabulary is `draw` and `pass`

The participant event becomes `draw`; its payload still contains one or two `sections` plus the existing optional power, chosen-symbol, and target fields. The caller permission becomes `can_draw`. The server-only event is `reveal`.

Known events outside their allowed phase return `invalid_phase`; unknown events return `unknown_command`; commands after `finished` retain the terminal `finished` error. No aliases are retained because the game is a non-production preview and the requirement explicitly removes duplicate vocabulary.

### 5. Backend and client contract move atomically

The AsyncAPI phase enum, commands, permissions, examples, and error descriptions change with the Elixir aggregate. Client TypeScript types, SDK calls, XState classification, stories, mocks, and browser tests move in the same delivery outcome. The generic session lifecycle and shell start behavior remain unchanged.

## Risks / Trade-offs

- [Breaking preview sessions and clients] -> Deploy the backend contract and separate client together; no production or persisted-session compatibility is promised for this preview.
- [A transient reveal projection may retain stale presentation facts] -> Project `current_instruction` and legal options only in `turn`, while retaining reveal history as public completed history.
- [Server entry scheduling could execute twice] -> Preserve phase-gated command dispatch and existing exactly-once entry tests; a second reveal after entry to `turn` returns `invalid_phase`.
- [Round-start and instruction-advance reveal payloads differ] -> Validate each shape against aggregate state: new rounds require a full valid setup, while in-round reveals require an empty payload.

## Migration Plan

1. Change the aggregate, rules, server, permissions, projection, and focused tests.
2. Update and validate the AsyncAPI contract and session/channel integration coverage.
3. Update the separate Svelte client contract, XState mapping, stories, mocks, and browser tests.
4. Validate both repositories, synchronize the OpenSpec delta, and archive the change.

Rollback is a coordinated revert of backend, AsyncAPI, and client changes. No database rollback is required.

## Open Questions

None. The phase set, transition graph, command names, and compatibility boundary are decided.
