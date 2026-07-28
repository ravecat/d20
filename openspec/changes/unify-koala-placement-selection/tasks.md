## 1. State Model and Contract

- [x] 1.1 Replace the server-owned selection model with the reviewed committed-state, stateless-preview, transition, command, predicate, and visibility tables
- [x] 1.2 Define complete `draft` request and reply shapes, full `submit`, removed commands, reconnect behavior, and coordinated client ownership
- [x] 1.3 Preserve ruleset-owned marks, shape invariants, and sheet-specific hospital identifiers

## 2. Shared Stateless Preview Boundary

- [x] 2.1 Add a default unsupported preview callback to the D20 game contract
- [x] 2.2 Add read-only preview calls through Sessions, Session, and Game.Server without publication or state change
- [x] 2.3 Add SessionChannel draft reply handling and focused shared-boundary tests

## 3. Koala Command, Rules, and Aggregate

- [x] 3.1 Normalize complete draft and submit candidates and remove select, deselect, reset, and direct primary events
- [x] 3.2 Remove selection from player state and all lifecycle transitions
- [x] 3.3 Evaluate draft details as a pure Rules candidate and resolve submit from the complete payload once
- [x] 3.4 Cover classification, stale candidates, atomic bonus failure, unchanged-state rejection, and concrete changeset actions

## 4. Projection and Public Contract

- [x] 4.1 Remove selection from normal projections while preserving mark-keyed initial options
- [x] 4.2 Update caller visibility, projection negative assertions, channel replies, and non-broadcast tests
- [x] 4.3 Update `priv/specs/koala-rescue-club.yaml` for draft replies, full submit, removed commands, and projection shape
- [x] 4.4 Verify contract serving and server-shaped fixtures

## 5. Separate Client Coordination

- [x] 5.1 Revise the linked client OpenSpec and public TypeScript contract
- [x] 5.2 Store complete primary draft and latest preview locally, with request correlation and rollback
- [x] 5.3 Send draft after target edits, reset locally, submit the complete candidate, and clear on reconnect
- [x] 5.4 Update controls, both maps, fixtures, and focused browser tests without changing calibrated geometry

## 6. Validation and Coordinated Release

- [x] 6.1 Format touched files and run focused D20 command, rules, game, projection, session, server, channel, and AsyncAPI tests
- [x] 6.2 Run focused client store, reducer, component, reconnect, error, keyboard, responsive, and forced-colors browser tests
- [x] 6.3 Run full checks, builds, `git diff --check`, and strict OpenSpec validation in both repositories
- [x] 6.4 Visually inspect both sheets at wide and narrow sizes
- [ ] 6.5 Deploy compatible backend and client artifacts together, restart active Koala sessions, and retain a paired rollback path
