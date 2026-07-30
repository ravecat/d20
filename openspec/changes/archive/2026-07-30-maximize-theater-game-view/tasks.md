## 1. Focused Behavioral Coverage

- [x] 1.1 Keep simulated-DOM coverage focused on user-observable behavior instead of computed styles, CSS classes, or presentation-only DOM structure.
- [x] 1.2 Retain focused assertions that mode transitions, fullscreen state, iframe identity, SDK bridge initialization, control semantics, and accessible names remain unchanged.

## 2. Theater Layout

- [x] 2.1 Replace the capped and centered `.dialog--theater` dimensions in `assets/js/components/dialog.svelte` with automatic dimensions constrained by independently safe-area-aware `0.5rem` minimum edge insets.
- [x] 2.2 Remove the narrow-viewport Theater sizing override while preserving the existing narrow Compact rules and shared fullscreen wrapper behavior.

## 3. Validation

- [x] 3.1 Run `bun run test -- js/components/session.test.ts` from `assets/` and resolve any focused component regressions.
- [x] 3.2 Run `mix assets.lint` and `mix typecheck` from the repository root and verify the touched frontend files remain formatted.
- [x] 3.3 Inspect Theater and Compact behavior in a real browser at representative wide, narrow, portrait, and landscape viewports, including asymmetric safe-area emulation when available.

## 4. Test Decoupling

- [x] 4.1 Remove computed-style and CSS-class assertions from frontend tests while preserving behavioral coverage.
- [x] 4.2 Remove test-only CSS processing that is no longer required by jsdom tests.
- [x] 4.3 Run focused and complete frontend tests, formatting, linting, and type checks after the cleanup.
