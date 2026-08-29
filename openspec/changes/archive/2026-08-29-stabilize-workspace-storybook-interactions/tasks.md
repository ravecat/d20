## 1. Add Deterministic Story State

- [x] 1.1 Add a Storybook-only `phoenix-session` fixture exposing direct snapshot, status, cleanup, and minimal session controls consumed by Workspace.
- [x] 1.2 Keep initial, ready, and cleared state literals inline with fresh nested records instead of introducing rendering, descriptor, or empty-state helpers.
- [x] 1.3 Alias `phoenix-session` to the fixture only in Storybook and keep production Workspace and runtime session modules unchanged.

## 2. Consolidate Workspace Browser Coverage

- [x] 2.1 Add an Auto selection story whose `play` function covers initial selection, Compact restoration, Enter and Space activation, source-order focus movement, selection switching, and fullscreen controls through accessible queries.
- [x] 2.2 Add one ready connection-status story with three sessions that displays two Live statuses, one Finished status, and a long identifier.
- [x] 2.3 Add dedicated Reconnecting and Failed stories that present the shared Workspace transport overlays directly.
- [x] 2.4 Return `clear` from each story's `beforeEach` and keep complete branch-driving data inline.
- [x] 2.5 Avoid separate authoritative-snapshot, frame-preservation, Compact-accessibility, and keyboard-only catalog stories.
- [x] 2.6 Remove the superseded manual Workspace browser harness while preserving lower-layer model and presentation coverage for snapshots, transport calls, SDK and frame lifecycle, subscription cleanup, and model contracts.

## 3. Preserve Visual Coverage

- [x] 3.1 Keep the existing Chromium desktop, tablet, and mobile projects and review the twelve generated Workspace references.
- [x] 3.2 Rely on the configured accessibility addon across retained stories rather than creating a dedicated accessibility story.
- [x] 3.3 Document Storybook interaction ownership, deterministic connected-state setup, cleanup, and Chromium execution.

## 4. Stabilize Compact Status Presentation

- [x] 4.1 Keep the compact status dot and label centered and apply one shared `0.6875rem` font size to Live and Finished without changing markup or accessibility semantics.
- [x] 4.2 Regenerate and review every affected desktop, tablet, and mobile Chromium reference.

## 5. Validate and Finalize

- [x] 5.1 Run the remaining Workspace unit and presentation tests and Chromium visual story projects.
- [x] 5.2 Run frontend formatting, linting, tests, type checks, Storybook build, and strict OpenSpec validation.
- [x] 5.3 Sync and archive the OpenSpec change and confirm it leaves the active list.
