## 1. State Model and Contract

- [x] 1.1 Replace the server-owned selection model with the reviewed committed-state, stateless-preview, transition, command, predicate, and visibility tables
- [x] 1.2 Define complete `draft` request and reply shapes, full `submit`, removed commands, reconnect behavior, and coordinated client ownership
- [x] 1.3 Preserve ruleset-owned marks, shape invariants, and sheet-specific hospital identifiers

## 2. Unified Dispatch and Projected Response Boundary

- [x] 2.1 Extend `:ok` dispatch results with an unchanged-state game-specific reply, retain only `:ok` and `:error` status atoms, and remove every shared preview callback, function, OTP request, and behaviour entry
- [x] 2.2 Route every SessionChannel event through the generic `handle_in/3` and `D20.Sessions.dispatch/3` path
- [x] 2.3 Route game-specific dispatch replies through `D20Web.Projection.reply/3` and return engine-produced reply data unchanged from the caller-specific game projection's `reply/3` function
- [x] 2.4 Cover unchanged state, no publication, caller privacy, generic routing, and stable errors at the shared boundary

## 3. Koala Command, Rules, and Aggregate

- [x] 3.1 Normalize complete draft and submit candidates and remove select, deselect, reset, and direct primary events
- [x] 3.2 Remove selection from player state and all lifecycle transitions
- [x] 3.3 Route draft evaluation through `Game.dispatch/2`, compose independent Rules validations and derivations while assembling the complete reply data inline, return unchanged state plus `{:draft, data}` without duplicating the actor id or adding a status atom, and keep submit resolution on the complete payload
- [x] 3.4 Cover classification, stale candidates, atomic bonus failure, unchanged-state rejection, and concrete changeset actions

## 4. Projection and Public Contract

- [x] 4.1 Remove selection from normal projections while preserving mark-keyed initial options
- [x] 4.2 Update caller visibility, projection negative assertions, generic channel replies, and non-broadcast tests
- [x] 4.3 Update `priv/specs/koala-rescue-club.yaml` to describe unified draft dispatch and projected replies without changing the wire schemas
- [x] 4.4 Verify contract serving and server-shaped fixtures

## 5. Separate Client Coordination

- [x] 5.1 Revise the linked client OpenSpec and public TypeScript contract
- [x] 5.2 Store complete primary draft and latest preview locally, with request correlation and rollback
- [x] 5.3 Send draft after target edits, reset locally, submit the complete candidate, and clear on reconnect
- [x] 5.4 Update controls, both maps, fixtures, and focused browser tests without changing calibrated geometry

## 6. Validation and Coordinated Release

- [x] 6.1 Format touched files and run focused D20 command, rules, game, projection, session, server, channel, and AsyncAPI tests
- [x] 6.2 Run focused client store, reducer, component, reconnect, error, keyboard, responsive, and forced-colors browser tests
- [ ] 6.3 Run full relevant D20 checks, `git diff --check`, and strict OpenSpec validation; verify the unchanged client reply contract does not require a paired client code change
- [x] 6.4 Visually inspect both sheets at wide and narrow sizes
- [ ] 6.5 Deploy compatible backend and client artifacts together, restart active Koala sessions, and retain a paired rollback path
