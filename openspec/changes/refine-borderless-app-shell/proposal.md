## Why

The Inertia game shell now keeps content between a persistent header and footer, but visible edge lines, the compact-header shadow, and the rectangular brand focus outline make those surfaces look boxed in. The D20 mark also uses size custom properties for two simple visual states, which obscures the actual dimensions. Engineers who may implement compatible game clients also need an obvious portal entry point instead of an unrelated source-code footer link.

## What Changes

- Formalize the bounded, scrollable game app shell as an explicit capability.
- Keep the header, footer, and brand free of visible surrounding borders or edge shadows in normal, compact, pointer, and keyboard states.
- Preserve a visible keyboard-focus indicator for the home brand without drawing a rectangle around the mark or label.
- Keep the sticky header, persistent footer, internal Inertia scroll region, and compact-on-scroll behavior unchanged.
- Replace D20 size custom properties with explicit component size declarations while retaining color custom properties.
- Replace the footer source link with an internal `for developers` link to `/developers`.
- Add a developer page that introduces client implementation and derives a compact reference/YAML list from registered games with matching static specifications.
- Resolve reference and raw-spec routes dynamically from a registered game slug and a matching static `priv/specs/<slug>.yaml` file.

## Capabilities

### New Capabilities

- `game-app-shell`: Defines the persistent header/footer shell, bounded content scrolling, compact brand behavior, and borderless chrome treatment for Inertia game pages.
- `developer-resources-page`: Defines the developer entry route, footer navigation, game specification index, and public AsyncAPI reference endpoints.

### Modified Capabilities

None.

## Impact

- Affected frontend files: app-shell components, a new Inertia page, its server-owned specification prop, and nearby tests.
- Adds a read-only Phoenix route for `/developers` plus two dynamic rendered/raw AsyncAPI route patterns shared by every configured specification.
- No session, persistence, or iframe module contract changes.
- No new dependencies or migrations.
- Rollback is limited to restoring the previous component styles and D20 sizing implementation, removing the developer routes and page, and restoring the previous footer link.
