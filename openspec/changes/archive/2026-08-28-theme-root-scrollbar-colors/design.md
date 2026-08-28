## Context

`assets/css/app.css` registers two daisyUI themes: `light` as the default and `dark` through `prefersdark: true`. daisyUI itself emits a root scrollbar declaration equivalent to:

```css
:root {
  scrollbar-color: color-mix(in oklch, currentcolor 35%, transparent) transparent;
}
```

The thumb is themed through `currentcolor`, but the track is fully transparent. Browsers that paint classic (non-overlay) scrollbars composite the scrollbar track over the element's backdrop. Inside the Storybook preview iframe that backdrop is the white iframe element background, so a dark theme renders a light stripe where the scrollbar track is.

The same leak is possible in any embedding context whose background differs from the active theme: WebViews, embedded game frames, or a transparent page over a host surface. Linux and Windows desktop browsers commonly paint classic scrollbars; macOS and mobile platforms usually paint overlay scrollbars without a persistent track and are unaffected.

## Goals / Non-Goals

**Goals:**

- Make the active application theme the single source of truth for root scrollbar colors.
- Keep automatic `prefers-color-scheme` selection and explicit `data-theme` overrides working for both scrollbar colors and page colors together.
- Use only CSS theme tokens; no JavaScript, matchMedia, user-agent inspection, or browser branching.
- Preserve the established thumb contrast (35% `color-mix` of the theme content color).
- Keep `forced-colors` handling owned by the browser.

**Non-Goals:**

- A user-facing theme toggle; none exists in this change.
- Custom `::-webkit-scrollbar` fallback rules. `scrollbar-color` is Baseline since Chrome 121 and the repository's `browserslist` policy is the support source of truth; no repository requirement currently demands the legacy pseudo-elements.
- Styling scrollbars of individual inner containers beyond what component styles already do.
- Changing daisyUI theme values, the `prefersdark` wiring, or the dark custom variant.

## Decisions

### Override the root scrollbar declaration with theme tokens

Add a single `:root` rule in `assets/css/app.css` after the daisyUI theme definitions:

```css
:root {
  scrollbar-color:
    color-mix(in oklch, var(--color-base-content) 35%, transparent)
    var(--color-base-100);
}
```

Placed after the `@plugin` theme blocks, the rule wins the cascade over daisyUI's generated root declaration at equal specificity and later order. Both colors reference custom properties that daisyUI defines per active theme, so automatic `prefers-color-scheme` selection and explicit `data-theme` overrides re-resolve the scrollbar colors without any script.

`var(--color-base-100)` matches the page background token already used by the application shell (`js/app/layout.svelte` sets `background: var(--color-base-100)`), so the scrollbar track matches the page surface by construction rather than inheriting an arbitrary embedding backdrop.

`color-mix(in oklch, var(--color-base-content) 35%, transparent)` preserves daisyUI's own thumb formula (`currentcolor` at `:root` resolves to `--color-base-content`), keeping the established contrast in both themes.

Rejecting alternatives:

- **Storybook-only iframe background fix**: hides the symptom in one tool while leaving every other embedding context (WebView, embedded game frames, transparent hosts) with the same leak.
- **`scrollbar-width: none` or fully custom `::-webkit-scrollbar`**: removes or re-implements native controls, a larger and less accessible change than theming two colors.
- **JavaScript theme syncing**: violates the theme-as-single-source constraint and adds runtime state for a pure styling concern.
- **Opaque track via a literal color**: breaks when a future theme or `data-theme` override changes `--color-base-100`.

## Risks / Trade-offs

- [Track no longer matches a non-default page background] -> The application shell intentionally sets `background: var(--color-base-100)`, so root scrolling surfaces match the token. Any future page that scrolls a differently colored root surface owns that surface's scrollbar decision at that time.
- [Visual regression references change] -> Scrollbar pixels can enter story screenshots only where a root classic scrollbar is visible; committed Chromium references are re-reviewed and updated through the established baseline workflow if any capture them.
- [Overlay-scrollbar platforms see no change] -> Accepted; they paint no persistent track and were never affected.
- [Legacy `::-webkit-scrollbar` fallback omitted] -> `scrollbar-color` support covers the repository's resolved browser set; the fallback can be added later under `@supports not (scrollbar-color: auto)` if the support policy requires it.

## Migration Plan

1. Add the root `scrollbar-color` override to `assets/css/app.css` after the daisyUI theme definitions.
2. Validate computed scrollbar colors in a real browser for dark and light automatic selection and for explicit `data-theme` overrides, inside an embedding iframe.
3. Run the frontend formatting, lint, typecheck, and test checks; update visual references only if any committed capture includes root scrollbar pixels.
4. Archive the change. No data, deployment, or runtime migration is required.

## Open Questions

None.
