## Why

The prepared Home page stretched the footer, leaving unused space below its navigation on a short page. Make main content explicitly own spare viewport height so the footer remains naturally sized at the page bottom.

## What Changes

- Use a vertical flex layout with a growing main region and the existing dynamic viewport minimum height.
- Preserve document scrolling, fixed header spacing, footer disclosures, safe-area padding, and Workspace overlays.
- Verify short and overflowing pages in the existing browser page and run focused shell checks.

## Capabilities

### New Capabilities

- `app-footer-placement`: Natural footer sizing and bottom placement across short and overflowing App-layout pages.

### Modified Capabilities

None.

## Impact

- Tracking: [#271](https://github.com/ravecat/d20/issues/271), in the D20 Project.
- Author in clean `master` as explicitly requested. The separate informative-footer worktree owns uncommitted page briefs, not this shell-sizing outcome.
- Related #268 retains its Help/legal content and publication gates. This change has an independent local acceptance boundary and does not depend on those editorial changes.
- Implementation is limited to `assets/js/app/layout.svelte`; no packages, migrations, backend, session, or iframe contracts change.
- Rollback restores the previous layout CSS.
