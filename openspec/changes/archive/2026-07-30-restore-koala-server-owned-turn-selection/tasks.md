## 1. Ruleset Types And Turn History

- [x] 1.1 Add `round`, active `turn`, and `die_value` types to `D20.KoalaRescueClub.Ruleset`, then replace duplicated literal range types in `Game`, `Rules`, and `Projection`, preserving `0 | Ruleset.turn()` for the pre-start game state
- [x] 1.2 Replace `turn_result` records with ordered adjusted die values in `Game.player.turns`, append values only after accepted shape or single-cell turns, and remove action and explicit turn-number recording
- [x] 1.3 Update focused game and projection tests for value-only turn history and ruleset-owned scalar types

## 2. Selection Command Contract

- [x] 2.1 Add `select`, `deselect`, and empty-payload `reset` normalization to `D20.KoalaRescueClub.Command`, including optional continuation context for `select`
- [x] 2.2 Change `submit_turn_selection` normalization to accept only ordered bonus actions and remove `project_turn_selection` validation
- [x] 2.3 Add command tests for initial selection context, target-only continuation, deselection, reset, malformed payloads, and the revised submit payload

## 3. Server-Owned Selection Workflow

- [x] 3.1 Add canonical optional `%{action, value, volunteers, cells}` selection state to the Koala player type, constructors, start and turn resets, and internal state assertions without storing derived projection fields
- [x] 3.2 Implement rule validation and deterministic transitions for `select`, `deselect`, and `reset`, including context replacement, idempotent repeated targets, legal-placement filtering, volunteer affordability, and unchanged committed state
- [x] 3.3 Expose rule-level option and selection analysis needed by rendering, including completion and simulated bonus derivation, without moving wire-format assembly into `Rules`
- [x] 3.4 Change atomic submission to consume and revalidate the stored complete selection, preserve it on failed submission, and clear it on success
- [x] 3.5 Route the selection events through `D20.KoalaRescueClub.Game.dispatch/2` and record only the accepted adjusted die value after successful turn resolution
- [x] 3.6 Add focused game and rules tests for selection lifecycle, invalid edits, committed-state isolation, submit failure rollback, success cleanup, and turn-transition cleanup

## 4. Regular Projection And Generic Channel

- [x] 4.1 Restore top-level caller-specific `selection` in regular Koala projections, map internal `value`, `volunteers`, and `cells` to the public field names, and derive required cells, continuation cells, completion, and bonus options from rule analysis
- [x] 4.2 Keep stored selection absent from shared rendered player data and return no active selection to other players or non-actionable callers
- [x] 4.3 Remove `project_turn_selection`, `D20Web.Projection.render_event/4`, and the Koala-specific `SessionChannel.handle_in/3` clause so every input uses the generic dispatch callback
- [x] 4.4 Update projection, server, and channel tests for ordinary command replies, broadcast-driven selection updates, reconnect recovery, caller privacy, and unchanged generic behavior for other games

## 5. Public Contract And Dependent Client

- [x] 5.1 Update `priv/specs/koala-rescue-club.yaml` to remove stateless projection messages, add `select`, `deselect`, and `reset`, restore regular caller selection, revise submit payloads, expose `turns` as adjusted values, and bump the contract version
- [x] 5.2 Validate the AsyncAPI document with the repository-compatible AsyncAPI CLI command
- [x] 5.3 Update `/home/max/apps/koala-rescue-club` transport calls and types for the three selection events, regular projected selection, stored-selection submission, and value-only turn history
- [x] 5.4 Update the client turn store, fixtures, and browser tests to consume broadcast projections, resume server-owned selections, preserve bonus behavior, and remove `project_turn_selection`

## 6. Validation And Review

- [x] 6.1 Format all touched Elixir files and run targeted command, game, rules, projection, server, and session channel tests
- [x] 6.2 Run `mix assets.lint`, `mix assets.test`, and `mix typecheck` for shell contract consumers, then run `just check` because the change crosses game, channel, and public contract boundaries
- [x] 6.3 Run the dependent Koala client check, test, and production build commands and verify that unrelated client work remains unchanged
- [x] 6.4 Review the final diff for selection privacy, absence of Koala-specific channel routing, value-only turn history, active-session restart notes, and coordinated rollback coverage
