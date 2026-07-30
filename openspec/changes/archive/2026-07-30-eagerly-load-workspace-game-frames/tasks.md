## 1. Frame Runtime

- [x] 1.1 Make each mounted workspace game iframe load eagerly without changing its URL, sandbox, bootstrap payload, or bridge lifecycle.

## 2. Browser Regression Coverage

- [x] 2.1 Configure the existing Vitest browser project to run declaratively in both Playwright-managed Chromium and Firefox.
- [x] 2.2 Add a focused browser test that requires a Compact iframe to load before expansion and preserves the same iframe and SDK bridge through expansion.
- [x] 2.3 Gate existing browser assertions for progressive enhancements on the same runtime capability used by their production fallback.

## 3. Validation

- [x] 3.1 Run the Svelte autofixer, focused unit and browser tests in Chromium and Firefox, frontend formatting, linting, and type checks.
- [x] 3.2 Run strict OpenSpec validation for `eagerly-load-workspace-game-frames`.
