## Why

Compact workspace windows use fixed white presentation colors that only contrast with the light-theme token ordering. In the dark theme, the status and session identifier become light-on-light and can appear missing across browsers, preventing players from identifying and restoring active sessions.

## What Changes

- Make Compact workspace status, session identifiers, and controls derive their foreground and background pairs from the active daisyUI theme tokens.
- Add browser-level regression coverage for both light and dark theme token orderings.
- Preserve existing Theater, fullscreen, layout, interaction, and iframe lifecycle behavior.

## Capabilities

### New Capabilities

- `workspace-compact-theme-contrast`: Defines readable Compact workspace presentation across supported light and dark themes.

### Modified Capabilities

None.

## Impact

- Affects the Compact presentation styles in `assets/js/widgets/workspace/ui/workspace.svelte` and their browser tests.
- Does not change Phoenix channels, public payloads, iframe module contracts, dependencies, persistence, or migrations.
- Tracked by GitHub issue [#164](https://github.com/ravecat/d20/issues/164).
