## Why

The embedded game frame currently has presentation behavior that is not captured by an OpenSpec requirement, leaving its default size, dismissal behavior, fullscreen semantics, and iframe continuity open to accidental regression. The shell needs an explicit display-mode contract before that interaction is refined further.

## What Changes

- Present an active or finished embedded game in Theater mode by default as a centered modal surface over the game page.
- Let a user move from Theater mode to a non-modal Compact window through native dialog light dismiss, Escape, or the compact control.
- Let a user restore Theater mode from the Compact window.
- Offer native browser fullscreen for the complete embedded game player with an exit control, while leaving the current display mode unchanged when the browser cannot fulfill the request.
- Keep the same iframe and D20 SDK bridge mounted while changing between Theater, Compact, and fullscreen presentation.
- Separate display-mode and fullscreen behavior from the iframe and SDK bridge component.
- Use the module identifier as the embedded game dialog's accessible name.
- Preserve the existing session lifecycle, module configuration, sandbox policy, bootstrap payload, routes, and public protocols.

## Capabilities

### New Capabilities

- `embedded-game-display-modes`: Defines Theater, Compact, and native fullscreen presentation for the shared embedded game surface, including transitions, accessibility, responsive behavior, and iframe continuity.

### Modified Capabilities

- None. No capability has been archived under `openspec/specs/`; this change adds display modes without changing the iframe lifecycle requirements already documented by the active game detail layout change.

## Impact

- Affected frontend modules: `assets/js/components/dialog.svelte`, `assets/js/components/frame.svelte`, `assets/js/components/session.svelte`, and focused component tests.
- Affected browser APIs: HTML `dialog`, including `closedby` light dismiss, and the Fullscreen API. Backdrop activation depends on `closedby` support, while native fullscreen availability and final system-level presentation remain browser controlled.
- No backend, route, persistence, migration, session channel, game engine, iframe sandbox, or iframe module contract changes are required.
- Rollback restores the fixed overlay presentation while leaving session and embedded game contracts unchanged.
