## Why

The latest application-shell work removed the game detail shell's local inline padding and made the `wide` header and footer variants unconditionally remove theirs. Game pages therefore lost the shared visual gutter across their chrome and content, regressing the responsive spacing accepted in #166 and tracked for correction in #200.

## What Changes

- Restore symmetric `1rem` game detail shell insets at and below the existing `48rem` breakpoint.
- Restore symmetric `1.5rem` game detail shell insets above that breakpoint.
- Align the wide header and footer variants to the same `1rem` narrow and `1.5rem` wide insets without changing narrow-layout pages.
- Add focused real-browser regression coverage for the header, main content, and footer at both responsive inset values while preserving current panel alignment and gaps.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `responsive-game-detail-spacing`: Require the wide game-page header, main content, and footer to share explicit responsive page-edge insets.

## Impact

- Affected frontend files: the app header and footer, the game detail Svelte component, and their focused browser tests.
- Public routes, session creation behavior, backend APIs, iframe game contracts, dependencies, migrations, and rollback behavior remain unchanged.
