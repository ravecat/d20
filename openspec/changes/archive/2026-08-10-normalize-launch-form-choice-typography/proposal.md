## Why

Schema-driven radio and checkbox labels currently inherit the larger application root size, so launch-form choices look oversized beside regular game-detail copy. The launch form needs one consistent regular text treatment across supported choice controls.

## What Changes

- Render schema-driven radio and checkbox choice labels at the same regular text size used by game descriptions.
- Preserve the existing choice layout, native controls, wrapping, focus treatment, disabled states, and submission behavior.
- Add browser-level regression coverage for the computed choice-label typography.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-session-creation-attrs`: Require schema-driven radio and checkbox choice labels to match regular game-detail text sizing.

## Impact

- Affects the shared SJSF stylesheet and focused game-detail browser tests under `assets/`.
- Does not change JSON Schema inputs, session APIs, persistence, game-module contracts, dependencies, or runtime behavior.
- Tracked by [GitHub issue #206](https://github.com/ravecat/d20/issues/206).
