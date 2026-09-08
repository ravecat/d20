# Footer placement verification

Verified on 2026-09-08 against master `5548458` plus this CSS correction, for [#271](https://github.com/ravecat/d20/issues/271).

## Implementation

The shared App layout uses a vertical flex container and `flex: 1` on main. Responsive header offsets, footer content and padding, document scrolling, and Workspace markup are unchanged.

## Automated checks

From `assets/`:

- `bun run test:browser -- tests/app/layout.browser.test.ts tests/app/ui/footer.browser.test.ts`: 32 tests passed across Chromium and Firefox, including existing scrolling/focus and footer disclosure coverage.
- `bun x oxfmt --check js/app/layout.svelte`: passed.
- `bun x eslint js/app/layout.svelte`: passed.
- `bun run typecheck`: passed, with zero Svelte errors or warnings.

## Existing development page

Used only the selected `http://localhost:5000/` page through Chrome DevTools. Confirmed Vite loaded the primary checkout's layout before final inspection.

- 1280x1200 CSS pixels: footer and inner content ended at 1200px; main took spare height.
- 400x1000 CSS pixels: collapsed footer and inner content ended at 1000px. Expanding both native disclosures increased the footer's natural height while its bottom stayed at 1000px.
- 400x400 CSS pixels with both disclosures open: the document grew to approximately 780px; scrolling reached the full legal strip without a nested main scroller.
- 1280x400 CSS pixels: the document grew to approximately 831px; the footer followed main and remained reachable through document scrolling.
- No horizontal overflow was observed on the short-page checks. No console warnings or errors were reported.
- Reviewed desktop, mobile, expanded, and overflowing screenshots. Restored the approximately 697x807 CSS-pixel viewport, top scroll position, and closed disclosures. Route and authentication stayed unchanged; the existing carousel continued its automatic rotation.

## Scope

This local shell correction does not complete #268's pending public information or publication gates. No deployment or backend validation is required for this CSS-only correction.

## Lifecycle

Archived with `openspec archive keep-footer-at-page-bottom --yes`, synchronizing both requirements into `openspec/specs/app-footer-placement/spec.md`. `openspec validate --all --strict --no-interactive` passed all 82 items after archival, and `openspec list --json` no longer included this change.
