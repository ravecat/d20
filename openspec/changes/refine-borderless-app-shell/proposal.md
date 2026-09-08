## Why

The Inertia game shell now keeps content between a persistent header and footer, but visible edge lines, the compact-header shadow, and the rectangular brand focus outline make those surfaces look boxed in. The D20 mark also uses size custom properties for two simple visual states, which obscures the actual dimensions. Engineers who may implement compatible game clients also need an obvious portal entry point instead of an unrelated source-code footer link.

## What Changes

- Apply the 2026-09-08 header proportions review tracked by #268: reduce the complete brand and Log in button to 75 percent in each supported state, using native CSS dimensions with proportionally reduced expanded header heights and matching document reserves, plus 15 percent larger compact vertical insets.

- Formalize the document-scrolling game app shell as an explicit capability.
- Keep the header, footer, and brand free of visible surrounding borders or edge shadows in normal, compact, pointer, and keyboard states.
- Preserve a visible keyboard-focus indicator for the home brand without drawing a rectangle around the mark or label.
- Keep the header pinned and compact-on-scroll behavior while making the document root the only page-level scroll container and timeline source.
- Suspend document-root scrolling while the modal authentication dialog is open so the dialog is the only active visible scroll container, then restore the document's prior scroll state when it closes.
- Replace D20 size custom properties with explicit component size declarations while retaining color custom properties.
- Replace the footer source link with an internal `for developers` link to `/developers`.
- Add a developer page that introduces client implementation and derives a compact reference/YAML list from registered games with matching static specifications.
- Resolve reference and raw-spec routes dynamically from a registered game slug and a matching static `priv/specs/<slug>.yaml` file.

## Capabilities

### New Capabilities

- `game-app-shell`: Defines the sticky-header application shell, global document scrolling, compact brand behavior, and borderless chrome treatment for Inertia game pages.
- `developer-resources-page`: Defines the developer entry route, footer navigation, game specification index, and public AsyncAPI reference endpoints.

### Modified Capabilities

- `responsive-game-detail-spacing`: Keeps game-detail edge protection and symmetric shell insets while overflowing pages move to global document scrolling.

## Impact

- Affected frontend files: app-shell components, the shared authentication dialog, a new Inertia page, its server-owned specification prop, and nearby tests.
- Adds a read-only Phoenix route for `/developers` plus two dynamic rendered/raw AsyncAPI route patterns shared by every configured specification.
- No session, persistence, or iframe module contract changes.
- No new dependencies or migrations.
- Rollback is limited to restoring the previous component styles and D20 sizing implementation, removing the developer routes and page, and restoring the previous footer link.
- The original CSS scroll timeline correction is tracked by [GitHub issue #85](https://github.com/ravecat/d20/issues/85), and its remaining lifecycle reconciliation is tracked by [GitHub issue #153](https://github.com/ravecat/d20/issues/153).
- The global page-scroll correction is tracked by [GitHub issue #261](https://github.com/ravecat/d20/issues/261).
