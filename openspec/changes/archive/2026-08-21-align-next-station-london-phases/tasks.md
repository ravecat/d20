## 1. Backend Game Model

- [x] 1.1 Replace setup readiness phases and transitions with derived readiness and `setup -> reveal` start behavior.
- [x] 1.2 Replace round preparation and inline instruction advancement with actorless `reveal -> turn` transitions while preserving deterministic random setup.
- [x] 1.3 Rename `draw_sections` to `draw`, enforce known-command phase errors, and update rule validation and reducer tests.

## 2. Backend Public Contract

- [x] 2.1 Rename and phase-gate caller permissions and projection fields, including null active instruction and empty options during reveal.
- [x] 2.2 Update custom server, session/channel integration behavior, and focused tests for reveal scheduling and phase publication.
- [x] 2.3 Update and validate the Next Station: London AsyncAPI phase, command, permission, payload, and error contract.

## 3. Separate Svelte Client

- [x] 3.1 Update TypeScript projection and command types plus SDK command forwarding for `setup`, `reveal`, `turn`, `finished`, `draw`, and `can_draw`.
- [x] 3.2 Update XState phase classification and draft reconciliation without deriving authoritative reveal or turn advancement.
- [x] 3.3 Replace obsolete Storybook fixtures and update focused browser and state-machine tests for reveal and turn states.

## 4. Validation and Reconciliation

- [x] 4.1 Run targeted D20 Next Station: London, session, channel, projection, and contract tests plus formatting and repository checks appropriate to the changed contract.
- [x] 4.2 Run client check, focused tests, production build, and browser validation for lobby, reveal, actionable turn, submitted wait, spectator, and finished states.
- [x] 4.3 Validate OpenSpec strictly, synchronize the delta into authoritative specs, archive the completed change, and reconcile GitHub issue #220.
