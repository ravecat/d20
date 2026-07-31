## 1. Lobby Rendering Ownership

- [x] 1.1 Render Lobby directly from the game page `session` prop and remove the local dismissal state.
- [x] 1.2 Remove the Lobby callback and visibility state while preserving canonical navigation and component cleanup.

## 2. Verification

- [x] 2.1 Update the focused game page test to verify that navigation, rather than optimistic state, owns Lobby removal.
- [x] 2.2 Run the focused frontend test, lint, formatting check, and typecheck.
- [x] 2.3 Validate the OpenSpec change strictly.
