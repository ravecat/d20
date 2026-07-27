## Why

The client workspace currently needs a clear boundary between authoritative Phoenix session snapshots and browser-local window state. A full XState statechart makes that small local state model substantially larger without adding statechart behavior the workspace uses. This work is tracked by GitHub issue #82.

## What Changes

- Keep `phoenix-session` as the sole owner of the authoritative workspace channel lifecycle and snapshots.
- Keep browser-local focus and compact mode in an event-driven reactive store composed with the session snapshot.
- Expose authoritative sessions and the single global layout value without enriching each session with a per-window mode.
- Let the workspace component arrange expanded and compact windows with parent-owned CSS, stacking the Theater window above every other game window and restoring the selectable grid through Compact.
- Let the persistent workspace component render application children and own workspace store construction and disposal instead of exposing that lifecycle to the application layout.
- Make the persistent workspace a Feature-Sliced Design widget with its model, types, and internal window UI colocated behind one public component API.
- Inline the pass-through game-window component into the workspace renderer so window composition and status presentation stay at their owning boundary.
- Keep the application layout in the App layer and remove workspace-specific exports from transitional Shared segments.
- Keep the default application layout route-agnostic and let each page public API declare any non-default layout presentation metadata.
- Keep the Workspace AsyncAPI document for internal verification while excluding it from the public developer catalog, reference viewer, and raw specification endpoint.
- Keep compaction on the explicit window control and remove the parent-window Escape shortcut that cannot observe keyboard input inside game iframes.
- Forward close commands without duplicating request progress or errors in workspace presentation state.
- Use the compact `@xstate/store` package instead of the full `xstate` runtime.
- Preserve the existing `WorkspaceStore` methods, workspace channel protocol, and iframe lifecycle.

## Capabilities

### New Capabilities

- `client-workspace-state`: Defines the ownership, event transitions, composition, and lifecycle of authoritative workspace snapshots and browser-local window state.

### Modified Capabilities

None.

## Impact

- Frontend implementation: the `widgets/workspace` slice, App layout composition, page public APIs, workspace model and state types, workspace layout CSS, window controls, and their mirrored focused tests.
- Frontend dependencies: replace `xstate` with `@xstate/store`.
- Web documentation boundary: remove public access to the Workspace AsyncAPI reference and raw YAML while retaining the document for internal validation.
- No workspace channel behavior or payload, database, iframe module contract, or migration changes.
- Rollback is limited to restoring the previous client state implementation and dependency.
