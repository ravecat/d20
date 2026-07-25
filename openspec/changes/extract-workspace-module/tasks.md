## 1. Extract Workspace Web Boundary

- [x] 1.1 Add stateless `D20Web.Workspace` APIs for actor subscription, discovery invalidation, and socket-specific snapshot construction.
- [x] 1.2 Delegate workspace subscription and snapshot construction from `D20Web.WorkspaceChannel` while retaining channel callbacks, runtime monitors, replies, and pushes.
- [x] 1.3 Route `D20.Game.Server` workspace invalidation through `D20Web.Workspace` and remove workspace PubSub responsibilities from `D20.Sessions`.

## 2. Preserve And Verify Behavior

- [x] 2.1 Update focused workspace and session tests to cover phase and membership invalidation, removed actors, duplicate invalidations, unchanged discovery state, descriptors, and runtime termination through the new boundary.
- [x] 2.2 Format touched Elixir files and run the focused Sessions, SessionChannel, Presence, and WorkspaceChannel test suites.
- [x] 2.3 Run the full backend test suite and strict `extract-workspace-module` OpenSpec validation, confirming that client and AsyncAPI contracts remain unchanged.
