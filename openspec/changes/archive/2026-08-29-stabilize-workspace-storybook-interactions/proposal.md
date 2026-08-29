## Why

The Workspace browser harness manually mounts the production component and reconstructs `phoenix-session` state even though Storybook now has the same deterministic production-component seam. Its keyboard scenario is also nondeterministic in the manual Firefox harness when the complete frontend suite runs, even though the focused file passes. Issue [#254](https://github.com/ravecat/d20/issues/254) tracks consolidating meaningful Workspace catalog and interaction coverage under a deterministic Storybook owner without changing production Workspace state or transport boundaries. This work is split from the unrelated VibeKit backend quality gate in [#179](https://github.com/ravecat/d20/issues/179) so each outcome can be reviewed independently.

## What Changes

- Add an Auto selection Workspace story whose `play` function covers initial selection, Compact restoration, keyboard activation, focus order, selection switching, and fullscreen controls through accessible queries.
- Add one ready connection-status Workspace story with three visible sessions, including two Live sessions, one Finished session, and a long-identifier case.
- Add dedicated Reconnecting and Failed stories that present the shared Workspace transport states directly.
- Add a Storybook-only `phoenix-session` fixture exposing direct snapshot, status, and cleanup controls for deterministic reactive session state.
- Keep each compact status dot and label centered and apply one smaller font size consistently to the Live and Finished states.
- Track the twelve reviewed Chromium visual references produced for the four Workspace scenarios, including the revised compact-status references.
- Remove the superseded manual Workspace browser harness while preserving lower-layer model and lifecycle tests for authoritative snapshots, frame lifetime, transport calls, and subscription cleanup. Accessibility remains a cross-cutting addon responsibility instead of receiving a dedicated catalog story.
- Keep the runtime model, transports, commands, and accessibility semantics unchanged; production code changes are limited to compact-status presentation.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `storybook-visual-regression`: Adds deterministic Storybook interaction ownership within the existing Chromium visual viewport matrix and fixes the reviewed compact-status typography.

## Impact

- Affected files are limited to the Workspace component style block, Storybook configuration, four Workspace stories and the Storybook-only fixture, twelve deterministic screenshot references, Storybook conventions, and removal of the superseded Workspace browser harness.
- Dependencies, Phoenix channels, iframe contracts, Workspace state, and runtime behavior remain unchanged.
- Chromium remains the sole Storybook behavior and visual-reference browser.
- Rollback restores the removed browser harness, reverts the compact-status style, and removes the stories, fixture, references, and Storybook convention updates.
