## Why

`D20.KoalaRescueClub.Game` currently spreads accepted-command state changes across `apply_command/2`, `apply_command/3`, and nested helpers that each return a modified aggregate. Separating command decisions from one private state-application seam will make each transition discoverable without changing any observable game or runtime behavior.

## What Changes

- Keep public `dispatch/2` as a thin adapter that reduces transitions returned by private `execute/2` and preserves the existing result contract.
- Move phase routing, command normalization, rule validation, dice resolution, and derivation of already-resolved internal transitions into private `execute/2` clauses that never transform `Game.t()`.
- Replace `apply_command/2`, `apply_command/3`, and nested aggregate-transforming helpers with private `apply/2` clauses as the only functions that transform `Game.t()`.
- Express join, pre-start leave, start, roll, submit, badge award, round score, turn advance, and finish mutations through Pathex inside the matching `apply/2` clauses.
- Inline one-use command decisions and transition orchestration, retaining only leaf badge, round-score, and final-score calculations that do not call other local helpers.
- Remove the non-contractual public `Game.fetch_player/2` proxy and let `Rules` use `Map.fetch/2` directly against the aggregate's players map.
- Preserve the public `D20.Game.dispatch/2` result contract, string `D20.Command` event names, aggregate shape, errors, projections, Session/server/channel behavior, and all gameplay outcomes.
- Remove the obsolete test dedicated to the deleted proxy, then validate formatting and compilation without running tests.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `koala-pathex-state-mutations`: Separate the existing public dispatch adapter from private command execution and apply already-resolved internal transitions through one private Pathex `apply/2` seam, while retaining every existing behavioral guarantee.

## Impact

- Affects `lib/d20/koala_rescue_club/game.ex`, its internal consumer `lib/d20/koala_rescue_club/rules.ex`, and removal of the obsolete proxy test in `test/d20/koala_rescue_club/game_test.exs`.
- Uses the existing Pathex dependency and does not change manifests, shared game-engine modules, persistence, Commanded, or event-store integration.
- Removes `Game.fetch_player/2`, which is public at the Elixir module level but is not a `D20.Game` callback or runtime boundary; no AsyncAPI, iframe client, projection, Session, server, channel, command payload, error, migration, or deployment compatibility change is expected.
- Rollback restores the current reducer/helper structure and lookup proxy; no data rollback or coordinated client/runtime deployment is required.
- Tracked by GitHub issue [#265](https://github.com/ravecat/d20/issues/265).
