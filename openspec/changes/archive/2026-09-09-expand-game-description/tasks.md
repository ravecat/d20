## 1. Description flow

- [x] 1.1 Remove the standalone description-panel scroll rules and redundant narrow-screen override from `assets/js/pages/game/ui/game.svelte`, preserving shared panel styles, layout, markup, metadata, launch, and lobby behavior.

## 2. Prearchive validation

- [x] 2.1 From `assets/`, run `bun run test:unit -- tests/pages/game/ui/game.test.ts` and `bun run test:browser -- tests/app/layout.browser.test.ts` to verify existing game behavior and document scrolling in Chromium and Firefox.
- [x] 2.2 From `assets/`, run scoped checks with `bunx oxfmt --check js/pages/game/ui/game.svelte` and `bunx eslint js/pages/game/ui/game.svelte`, then `bun run typecheck`.
- [x] 2.3 Through Chrome DevTools, verify effective CSS behavior on the reported page at desktop, tablet, and mobile widths, including document scrolling over the full long description, reachable final text and footer, natural short and empty descriptions, preserved split/stack placement, and no clipping or horizontal overflow. Restore temporary browser-only validation changes.

## Validation evidence

- Existing game unit suite: 16 passed; app layout browser suite: 12 passed in Chromium and Firefox.
- Scoped oxfmt and ESLint checks passed; TypeScript and Svelte reported zero errors and warnings. Svelte autofixer reported no issues.
- Chrome DevTools on `/games/356080` previewed the exact CSS deletion before integration. At effective CSS viewports 1024x640, 656x640, and 413x915, description client/scroll heights matched at 571/571, 547/547, and 809/809 pixels. All used visible overflow with no maximum height or document horizontal overflow.
- Desktop retained the split layout; narrow layouts stacked. Document scrolling reached the final text and footer while panel scrollTop stayed zero. Short text and the empty fallback each sized to 24 pixels. Browser-only text and CSS changes were restored by reloading; viewport emulation was cleared.
- Actual served-source verification on local master follows the authorized transfer, as described in the design.
