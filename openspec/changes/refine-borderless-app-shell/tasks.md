## 1. Borderless Shell Chrome

- [x] 1.1 Remove header and footer edge borders, compact-state shadow, and obsolete edge-paint transitions while preserving their backgrounds and fixed shell positions.
- [x] 1.2 Replace the brand link's rectangular focus outline with an explicit `:focus-visible` underline on the visible label.

## 2. Explicit D20 Sizing

- [x] 2.1 Give `D20` an optional compact state with literal default, narrow, and compact dimensions in component-scoped CSS.
- [x] 2.2 Pass the compact state from `Header` to `D20` and remove size custom properties and wrapper-owned dimensions.

## 3. Regression Coverage and Validation

- [x] 3.1 Extend the app-shell component test to verify that scrolling propagates the compact state to the D20 mark.
- [x] 3.2 Run frontend formatting, linting, component tests, type checks, and the production asset build.
- [x] 3.3 Verify in a browser that header/footer borders and shadows remain absent, brand keyboard focus uses an underline without an outline, and D20 dimensions match the specified default and compact states.

## 4. Developer Entry Page

- [x] 4.1 Add the `/developers` Inertia route and thin page-controller action with focused controller coverage.
- [x] 4.2 Replace the footer source link with an internal `for developers` Inertia link and update the app-shell component test.
- [x] 4.3 Add the responsive developer index and component coverage for its heading, explanation, semantic specification list, and reference links.
- [x] 4.4 Adapt the Songy/Moda AsyncAPI Plug and expose tested interactive-reference and raw-YAML routes for both current game contracts.

## 5. Developer Page Validation

- [x] 5.1 Run strict OpenSpec validation, targeted Phoenix tests, frontend format/lint/tests/typecheck, and the production asset build.
- [x] 5.2 Verify the footer navigation, developer index, both reference pages, and raw YAML routes at desktop and mobile widths.

## 6. Compact Specification List

- [x] 6.1 Reduce the developer index to one semantic row per game containing only the game name, `Open reference`, and `YAML`, and update component coverage.
- [x] 6.2 Pin the standalone AsyncAPI renderer to the verified official `@asyncapi/react-component` 3.1.3 release and update Plug coverage.

## 7. Dynamic Specification Routing

- [x] 7.1 Replace per-game forwards with registry-validated `:slug` reference/raw routes and use `priv/specs/<slug>.yaml` as the static filename convention.
- [x] 7.2 Rename the Koala Rescue Club specification to its hyphenated registry slug and cover configured, missing-file, and unknown-slug behavior.
- [ ] 7.3 Generate the developer-page list from registered games with matching static specifications and remove the hard-coded Svelte entries.

## 8. Final Validation

- [ ] 8.1 Run strict OpenSpec, backend, and frontend validation, then verify the compact rows and reference renderer at desktop and narrow widths.

## 9. CSS Scroll Timeline

- [x] 9.1 Replace the app-shell compact-header rune, scroll handler, and prop with a feature-gated named CSS scroll timeline and expanded reduced-motion fallback.
- [x] 9.2 Add focused Chromium browser coverage for the scroll-linked header dimensions without duplicating the existing app-shell unit assertions.

## 10. CSS Timeline Validation

- [x] 10.1 Run focused browser coverage, frontend formatting, linting, type checks, the production asset build, and strict OpenSpec validation.

## 11. Global Page Scroll Correction

- [x] 11.1 Make the document root the only page-level vertical scroller, remove the main region's nested Inertia scroll boundary, and bind an out-of-flow fixed header to the root scroll timeline with a responsive expanded-height reserve.
- [x] 11.2 Add focused unit and Chromium browser coverage for the single global scrolling element, root-scroll header compaction, and fixed-header-safe root alignment.

## 12. Global Scroll Validation

- [x] 12.1 Run focused frontend tests, formatting, linting, type checks, the production asset build, strict OpenSpec validation, and Chrome DevTools validation on overflowing Account Settings content.

## 13. Modal Document Scroll Lock

- [x] 13.1 Tie document scrolling-element overflow suspension and exact restoration to the mounted `AuthDialog` lifecycle while preserving the dialog-owned viewport scroller.
- [x] 13.2 Add focused browser coverage for the scroll lock, dialog reachability, document position preservation, and cleanup over overflowing and non-overflowing pages.

## 14. Modal Scroll Validation

- [ ] 14.1 Run focused frontend tests, formatting, linting, type checks, production asset build, strict OpenSpec validation, and Chrome DevTools validation on the overflowing Home login dialog.
