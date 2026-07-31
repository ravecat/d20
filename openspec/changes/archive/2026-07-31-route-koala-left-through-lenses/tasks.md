## 1. Left Reducer

- [x] 1.1 Extend the existing Koala aggregate tests to preserve the successful no-op when an absent actor leaves before start.
- [x] 1.2 Route accepted setup and ready `left` commands through `apply_command/2`, remove the actor with strict aggregate and optional player Pathex paths, set the post-removal phase through its lens, and remove the superseded helpers.

## 2. Validation

- [x] 2.1 Format the touched Elixir files and run the focused Koala aggregate test module.
- [x] 2.2 Compile with warnings treated as errors and inspect the focused implementation diff for unintended contract changes.
- [x] 2.3 Run strict OpenSpec validation for `route-koala-left-through-lenses`.
