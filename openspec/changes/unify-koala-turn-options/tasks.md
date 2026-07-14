## 1. Backend Turn Projection

- [x] 1.1 Replace the turn-options array with a caller-specific die-value map covering all four primary actions
- [x] 1.2 Group options and staged selection under the projection's `turn` object
- [x] 1.3 Update focused Koala rules, server, and projection tests for option costs, action membership, legal cells, and caller isolation

## 2. Public Contract

- [x] 2.1 Update the Koala Rescue Club AsyncAPI schemas for the breaking `turn` projection contract
- [x] 2.2 Validate the OpenSpec change and AsyncAPI document with repository-supported checks

## 3. Dependent Client

- [x] 3.1 Update session types for `turn.options`, `turn.selection`, and the die-value action map
- [x] 3.2 Make the Svelte turn store and controls consume server-derived action availability and cells
- [x] 3.3 Update client browser fixtures and tests to cover server-controlled single-cell actions and unavailable die values

## 4. Validation

- [x] 4.1 Run targeted backend formatting and tests for the changed Koala projection contract
- [x] 4.2 Run dependent client formatting, type checks, and focused browser tests
- [x] 4.3 Review both dirty worktrees to confirm the implementation preserves unrelated changes and matches the OpenSpec tasks
