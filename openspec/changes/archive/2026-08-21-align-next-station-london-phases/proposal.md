## Why

Next Station: London currently exposes service-oriented phases (`ready`, `preparing_round`, and `build`) that obscure the game's actual progression and duplicate readiness already derived from the player roster. Aligning the aggregate, public contract, and client with meaningful game phases makes each reachable state explainable by the rules and removes an unnecessary state split.

## What Changes

- **BREAKING** Replace the public game phase set with `setup`, `reveal`, `turn`, and `finished`.
- Keep the game in `setup` until an eligible owner starts it; readiness remains a derived permission rather than a phase.
- Replace actorless `prepare_round` with actorless `reveal`; `reveal` prepares a new round when needed or advances the committed deck, then enters `turn`.
- **BREAKING** Rename the participant command `draw_sections` to `draw` and permission `can_draw_sections` to `can_draw`; keep the existing one-or-more-section payload semantics.
- Return `invalid_phase` for known game commands received outside their valid phase.
- Update projections, AsyncAPI, the separate Svelte client, Storybook states, and automated coverage to use the new vocabulary and transition graph.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `next-station-london-gameplay`: Replace readiness and preparation service states with the rule-aligned setup, reveal, turn, and finished transition graph and rename the draw command and permission.
- `next-station-london-client`: Consume and present the new phases, command, and permission without deriving authoritative game progress.

## Impact

- Backend game aggregate, rules, command validation, custom server scheduling, permissions, projection, session/channel integration tests, and `priv/specs/next-station-london.yaml`.
- Public breaking changes to game phase enum, participant draw command name, and draw permission name.
- `/home/max/apps/next_station_london` types, SDK adapter, XState classification, Storybook fixtures, and browser/state-machine tests.
- No database migration or dependency change. Existing persisted or in-flight Next Station: London sessions using removed phases are not compatible; rollback is a coordinated code and contract revert while the game remains a non-production preview.
- Tracked by [ravecat/d20#220](https://github.com/ravecat/d20/issues/220).
