## Context

Koala Rescue Club is already present in the game registry, and `D20.KoalaRescueClub.Ruleset` already contains stable facts for turns, rounds, die values, volunteer adjustment, action kinds, hospital scoring helpers, and solo ratings. `D20.KoalaRescueClub.Game` is still a placeholder and returns `:not_implemented`, so the generic session shell cannot run the registered game.

The supplied map PDFs describe the rules in prose and images. They do not currently give the repository a machine-readable representation of areas, tree cells, printed koala cells, rows, columns, bonuses, hospitals, skybridge edges, or badge predicates. Full rule implementation depends on that data. The implementation must therefore treat map data as a first-class prerequisite instead of inferring placement legality from hand-waved assumptions.

## Goals / Non-Goals

**Goals:**

- Implement a session-compatible Koala Rescue Club game reducer.
- Encode reviewable map data for the supported maps before validating placement-dependent rules.
- Preserve the existing generic session command flow and registry entry.
- Validate known game rules from local rules PDFs and existing ruleset tests.
- Add tests that cover setup, turn flow, action validation, scoring, permissions, and projection behavior.

**Non-Goals:**

- Do not change routes, game registry identity, iframe sandbox policy, or generic session protocol.
- Do not add persistence for game state.
- Do not implement OCR or runtime parsing of PDF rule sheets.
- Do not guess map geometry, badge predicates, or skybridge connectivity that cannot be reviewed from encoded data.
- Do not build Koala-specific frontend UI in this change.

## Decisions

1. Represent map sheets as explicit data modules.

   `D20.KoalaRescueClub.Ruleset.Dharug` and `Yugambeh` should expose data for areas, cells, row and column groups, bonus bindings, hospitals, skybridges, and badges. This keeps validation deterministic and testable.

   Alternative considered: keep `sheet: :not_encoded` and implement only non-placement rules. That would make sessions technically startable but would leave the core game invalid, because almost every action depends on sheet geometry.

2. Use selected map data as the runtime rules context.

   At `start`, the owner chooses `dharug` or `yugambeh`. From that point, every placement, accessibility, bonus, hospital, badge, solo rating, round scoring, and final scoring decision should read from that selected map structure. Shared ruleset facts cover only the rules that are common to all maps.

   Source priority for implementation should be:

   - encoded selected-map data derived from local rule assets under `assets/public/rules/koala_rescue_club`
   - shared `D20.KoalaRescueClub.Ruleset` facts for non-map-specific rules
   - tests that document reviewed examples and edge cases

   BGG metadata, catalog metadata, route slugs, and display names are not rules sources.

   Alternative considered: branch on map name in the reducer. That spreads map-specific behavior through game logic and makes it harder to review which rules came from which map.

3. Model game state with an Ecto embedded schema.

   Follow the local Qwinto pattern: the game aggregate stores phase, player order, selected map, turn number, current roll, per-player sheets, round scores, badge awards, and final scores. Embedded schemas give predictable JSON encoding and fit the existing session projection style.

   Alternative considered: use plain maps only. That is smaller initially, but less consistent with existing game reducers and easier to drift in projections and tests.

4. Keep command validation separate from rule validation.

   Add a Koala command module to validate event names and payload shape. Add a rules module to validate phase, identity, player membership, placement, bonus use, scoring, and completion. This mirrors Qwinto and keeps malformed payload handling distinct from legal move handling.

   Alternative considered: validate directly inside `Game.dispatch/2`. That would make the first reducer faster to write but harder to test and reason about as placement rules grow.

5. Use a simultaneous-turn model.

   One accepted `roll` creates a shared die result for the current turn. Each player then submits a private resolution using the raw die or a volunteer-adjusted value. The game advances only after every pending player has submitted.

   Alternative considered: active-player turns. That does not match Koala Rescue Club classroom and simultaneous play rules.

6. Keep projection and permissions Koala-specific.

   Add `D20.KoalaRescueClub.Projection` and `Permission`, then route Koala sessions through `D20Web.Projection`. The public session envelope stays generic, while Koala-specific fields remain in the game projection and permission map.

   Alternative considered: return raw aggregate state. That leaks implementation details and does not provide caller-specific permissions or legal-action hints.

## Risks / Trade-offs

- Map data transcription errors -> Add focused tests that assert counts, connectivity, scoring fixtures, and representative legal and illegal placements for each map.
- Badge ambiguity -> Encode each badge predicate as named data with tests from example board states; leave any unresolved badge out of implementation until clarified.
- Shape geometry mismatch -> Define one coordinate system for cells and shape offsets, then test every die value under rotations and flips against known legal and illegal placements.
- Large first implementation -> Sequence work so map data validation lands before reducer placement logic.
- Runtime behavior changes from `:not_implemented` to rule errors -> Add session tests around creating and starting Koala sessions to document expected new behavior.

## Migration Plan

1. Add map data and tests while keeping the placeholder engine behavior unchanged.
2. Add command and rules modules with unit tests.
3. Replace the placeholder game reducer and add game-level tests.
4. Add projection and permission support, then update session tests.
5. Run targeted Koala tests first, then `mix test` or `just check` as risk requires.

Rollback is a code revert only. No database or persisted game-state migration is involved.

## Open Questions

- Are both `dharug` and `yugambeh` required in the first playable implementation, or should implementation land map by map?
- Which reviewer-approved interpretation should be encoded when a local PDF image is ambiguous?
- Should clients submit explicit cell ids only, or should they submit an anchor plus transform and let the server derive covered cells?
- Should legal-action previews be required in the first backend implementation, or can projection expose only permissions and authoritative state initially?
