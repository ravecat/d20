## 1. Backend Projection

- [x] 1.1 Move caller-specific `options` and `selection` from the nested `turn` map to the root map returned by `D20.KoalaRescueClub.Projection.render/2`
- [x] 1.2 Update focused projection tests for active options, empty non-actionable values, selection-owner recovery, other-player privacy, and absence of `turn`, `turn_options`, and `turn_selection`
- [x] 1.3 Keep legality calculations in `Rules`, return domain-native die-value keys there, and render the complete public `options` and `selection` maps in `Projection`; update focused rules and server tests

## 2. Public Contract

- [x] 2.1 Require top-level `options` and `selection` in the Koala Rescue Club AsyncAPI session schema and remove the standalone `turn` schema without changing the nested option or selection schemas
- [x] 2.2 Validate `priv/specs/koala-rescue-club.yaml` with `npx -y @asyncapi/cli@latest validate priv/specs/koala-rescue-club.yaml`

## 3. Dependent Client

- [x] 3.1 Remove the session `Turn` wire type and add top-level `options` and `selection` fields in `/home/max/apps/koala-rescue-club/src/types/session.ts`
- [x] 3.2 Update only session-projection reads in `/home/max/apps/koala-rescue-club/src/store/turn.svelte.ts` and `/home/max/apps/koala-rescue-club/src/components/turn_controls.svelte` while preserving the local `turn` store API
- [x] 3.3 Flatten session fixtures and browser-test mutations from `session.turn.*` to `session.*` in `/home/max/apps/koala-rescue-club/tests/components/app.browser.test.ts`, preserving all existing turn behavior assertions
- [x] 3.4 Run `just check`, `just test`, and `just build` in `/home/max/apps/koala-rescue-club`

## 4. Validation And Review

- [x] 4.1 Run `mix format --check-formatted lib/d20/koala_rescue_club/projection.ex lib/d20/koala_rescue_club/rules.ex test/d20/koala_rescue_club/game_test.exs test/d20/koala_rescue_club/server_test.exs test/d20_web/projection_test.exs` and the corresponding focused tests
- [x] 4.2 Run `openspec validate flatten-koala-turn-projection --strict`
- [x] 4.3 Review both worktrees to confirm unrelated dirty client changes are preserved and no session consumer still requires the removed `turn` envelope
