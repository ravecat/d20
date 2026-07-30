## Why

Firefox can defer a Compact workspace iframe indefinitely because the frame is both lazy-loaded and hidden by `content-visibility`. The workspace still reports the session as Live, but the deferred frame can first consume its short-lived module credentials only after they expire, leaving the expanded game client with unavailable state.

## What Changes

- Load every mounted workspace game iframe immediately, including while its session is Compact.
- Keep Compact game content visually and interactively hidden while allowing the iframe-owned SDK bootstrap and realtime session to become ready.
- Preserve the existing iframe node, SDK bridge, presentation transitions, and module inputs.
- Add focused browser coverage for iframe loading before Compact-to-Theater expansion and run the browser project in both Chromium and Firefox.

## Capabilities

### New Capabilities

- `workspace-game-frame-readiness`: Defines when a discovered workspace iframe must load and establish its game runtime relative to Compact, Theater, and fullscreen presentation.

### Modified Capabilities

None. There is no synchronized main specification under `openspec/specs/`; prior workspace lifecycle requirements remain unchanged.

## Impact

- Affected frontend component: `assets/js/widgets/workspace/ui/frame.svelte`.
- Affected browser coverage and test configuration: `assets/tests/widgets/workspace/ui/workspace.browser.test.ts` and `assets/vite.config.mjs`.
- Tracking issue: https://github.com/ravecat/d20/issues/165.
- No backend, route, session lifecycle, token lifetime, public protocol, iframe sandbox, module input, dependency, persistence, or migration change is required.
- Rollback restores deferred loading and therefore restores the Firefox failure window; no data or deployment-order rollback is required.
