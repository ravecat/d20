## Context

The Svelte Inertia shell uses a three-row `header / main / footer` grid and compacts the D20 brand after the page scrolls beyond 24 pixels. It currently fixes that grid to `100dvh`, makes only the middle region scrollable, and binds the compact animation to that nested region. When the document also overflows, long routes such as Account Settings expose two independent vertical scrollbars and the header follows only the nested one.

The refinement must preserve Inertia document scroll restoration, responsive brand dimensions, pinned-header behavior, and keyboard accessibility while making the document root the only page-level scroll container. That global page-scroll correction exposes a modal edge case on long routes: the root remains visibly scrollable behind the full-viewport authentication dialog, so Chromium paints the root scrollbar beside the dialog scrollbar even though native modal semantics make the page interaction-inert.

The footer currently links to the GitHub source repository. The product direction now treats the footer as the entry point for engineers who want to build compatible clients from game AsyncAPI contracts. Songy and Moda already establish a small Phoenix Plug pattern that serves raw YAML and renders an interactive reference with the standalone AsyncAPI React component. D20 can adapt that pattern for its two existing specifications without introducing a separate static-site build.

## Goals / Non-Goals

**Goals:**

- Remove visible edge borders and shadows from the header and footer in every scroll state.
- Remove the rectangular outline around the D20 brand while keeping keyboard focus unmistakable.
- Keep explicit default, narrow-screen, and compact brand states, applying the 25 percent size reduction requested in the 2026-09-08 visual review.
- Let the root CSS timeline drive compact interpolation; use only a reactive at-top guard to reset inactive timelines after content shrink.
- Keep the document position stable but temporarily suspend root scrolling while the modal authentication dialog owns interaction and overflow.
- Make D20 dimensions explicit in the D20 component instead of passing them through CSS custom properties.
- Make `/developers` a clear internal destination from every game-shell footer.
- Present a polished index for the existing Qwinto and Koala Rescue Club AsyncAPI contracts.
- Publish an interactive reference and raw YAML endpoint for each listed contract.
- Keep router size constant as specifications are added by deriving endpoints from registered game slugs.
- Generate the developer index from registered games whose slug-matching static specification exists.

**Non-Goals:**

- Redesign page cards, game-detail panels, or intentional component-local overflow regions.
- Change the compact threshold or add a custom replacement for Inertia's document scroll contract.
- Add a runtime scroll-timeline polyfill or retain a JavaScript fallback for the decorative compact state.
- Add a general modal manager, global dialog selector, root-state class, or nested authentication-content scroller for the single authentication dialog.
- Remove color custom properties from the D20 artwork.
- Parse AsyncAPI metadata at runtime or expose files whose slugs are not registered games.
- Add multi-version specification URLs or move `info.version` into the filename.
- Add authentication, generated SDKs, client contract code generation, or implementation tutorials.

## Decisions

### 1. Remove edge paint instead of making it transparent

The header will no longer declare a bottom border, compact-state shadow, or transitions for those properties. The footer will no longer declare a top border. Their existing background remains so content cannot paint through the sticky surfaces.

Keeping transparent borders was rejected because it retains an unnecessary visual-box model and makes future state overrides more likely to reintroduce a divider.

### 2. Indicate brand focus on the label, not around the brand box

The brand link will suppress its rectangular outline only when `:focus-visible` applies, and the visible `D20` label will gain a thicker underline with offset. This preserves a non-color keyboard cue without surrounding either the mark or the complete link with a boundary.

Removing focus indication entirely was rejected because the brand is the first keyboard-operable link in the shell.

### 3. Let D20 own explicit size states

`D20` will accept the existing compact state as an optional boolean and render a `d20--compact` modifier. Its component-scoped CSS will contain literal dimensions for desktop default, narrow default, and compact states. The header will pass `compact` directly and will no longer size the mark wrapper or define D20 size custom properties.

Sizing the SVG with a parent transform was rejected because transforms do not change layout dimensions. Keeping size custom properties was rejected because the values are local to one component and make the actual states harder to discover.

### 4. Use one internal developer entry route

The Inertia scope will expose `GET /developers`, backed by a thin `PageController.developers/2` action that renders the `developers` Svelte page. The footer will use the existing Inertia action with visible text `for developers`, without a redundant `aria-label`.

Keeping the external source link was rejected because repository code is not the promised specification index. A `/specs` route was rejected because the page is intended to grow into a broader developer area.

### 5. Keep the specification index explicit

`D20.Specifications` will intersect `D20.Games.Registry.list/0` with regular files following `priv/specs/<slug>.yaml`. The controller will pass only each available slug and a display name derived from that slug to the page; the Svelte component will derive both endpoint URLs. This keeps Registry as the allow-list, avoids BoardGameGeek network calls, and lets a new matching file appear without another router or frontend entry.

Each row will contain only the game name plus direct `Open reference` and `YAML` links. Protocol metadata, versions, descriptions, numbering, a section heading, and an availability count will remain absent because the linked documents already provide those details. Parsing YAML solely for a display name was rejected because it would add a dependency and runtime failure mode; title-casing the already validated slug is deterministic and sufficient for the current names.

Enumerating `priv/specs` without the registry was rejected because a stray file should not become a public contract. Adding a separate static documentation generator was rejected because the existing Songy and Moda renderer already covers this use case with substantially less build infrastructure.

### 6. Use a restrained technical index

The page will reuse the catalog-width shell, inherit the project's existing monospace typography, use the same compact content insets as the catalog, preserve the page heading, and render a real list without a redundant visible list heading. Its explanatory copy will span the available catalog column instead of using a narrower prose measure. Every game row will keep the name and two actions on one line, with hidden game context disambiguating repeated link labels for assistive technology. It will not load or declare a page-specific font. The visual direction is a compact resource list with lightweight row separators, not a spacious landing page, dashboard cards, or decorative gradients.

### 7. Adapt the existing AsyncAPI reference Plug

A reusable `D20Web.Plugs.AsyncApi` will have two compile-time route modes. The raw mode reads a known file beneath the D20 application directory and responds as YAML. The reference mode returns a minimal HTML document that loads the verified official `@asyncapi/react-component@3.1.3` standalone bundle from unpkg and points it at the corresponding same-origin raw endpoint. The exact version will be pinned so a documentation deployment cannot change without a repository change.

The router will define only `/developers/specs/:slug` and `/developers/specs/:slug/raw`. Before constructing an application-relative path, the Plug will require the slug to resolve through `D20.Games.Registry`; it will then read only `priv/specs/<registered-slug>.yaml`. A registered game without that exact file and every unknown slug will return not found. This keeps the router constant-sized and prevents a request from selecting an arbitrary file.

Specification filenames will use the registry slug verbatim, including hyphens. The existing `koala_rescue_club.yaml` will therefore become `koala-rescue-club.yaml`. Contract versioning remains in the AsyncAPI `info.version` field because the registry has no separate version slug and this change does not introduce one.

Bundling the React renderer into the Svelte application was rejected because these reference pages are independent documents and doing so would add React-specific application dependencies. The raw YAML remains useful if the CDN renderer is unavailable.

### 8. Drive compact presentation with the root CSS scroll timeline

The layout will use normal document flow with a `100dvh` minimum block size instead of fixing a viewport-sized grid around a nested main scroller. The main region will no longer declare page-level overflow, overscroll containment, a stable scrollbar gutter, or Inertia's `scroll-region` attribute. Short pages still place the footer at the viewport end through the grid's flexible middle row; long pages expand that row and place the footer after the content. The document root becomes the only page-level scrolling element.

The header will be fixed out of document flow and the layout will reserve its expanded responsive block size (`3.75rem` normally and `3.375rem` through the existing `34rem` breakpoint). The document will use the same responsive values as block-start scroll padding so fragment navigation, focus scrolling, and `scrollIntoView()` targets remain below the fixed surface, including in the expanded fallback. This keeps the header pinned without making its animated dimensions part of the root scroll range. The static reserve prevents content jumps and initial interactive-content overlap; it scrolls away with the page instead of becoming a permanent gap after compaction. The header receives the shell background so page content can pass behind it without painting through the fixed surface. Header and footer stop reserving companion scrollbar gutters because the root scrollbar already reduces the common viewport once for every shell region.

The header will bind its component-scoped keyframes directly to `scroll(block root)` and interpolate padding, brand gap, mark dimensions, and label dimensions over the first 24 pixels of document scrolling. Feature detection will require both `animation-timeline: scroll()` and `animation-range` support. The expanded header remains the base style for unsupported browsers, and reduced-motion users retain the expanded state instead of receiving continuous scroll-linked resizing.

Keeping an in-flow sticky header was rejected because changing its layout dimensions from the root scroll timeline changes that timeline's own range; Chromium deactivates the animation to avoid the resulting layout cycle. Keeping a named timeline was rejected because it requires a nested or named scroll source when the root already expresses the application-wide contract. Keeping the JavaScript handler as a fallback was rejected because it would restore presentation state and component coupling. Adding `scroll-timeline-polyfill` was rejected because the cosmetic enhancement does not justify a runtime CSS parser and its compatibility risks.

### 9. Let the authentication dialog own a scoped document scroll lock

`AuthDialog` is mounted only while the authentication store is open. Its existing synchronous `onMount` lifecycle will capture the document scrolling element's current inline `overflow`, set it to `hidden`, and open the native modal dialog. The lifecycle teardown will restore that exact inline value when the dialog closes and the component unmounts. The document keeps its scroll position while the full-viewport dialog retains `overflow-y: auto`, so short pages receive no visual change and long pages expose only the active dialog scrollbar.

This is an external DOM side effect because the standards-mode document scrolling element is outside the Svelte component tree. Tying it to `onMount` teardown keeps ownership local and SSR-safe without introducing reactive state synchronization. A global `:has(dialog:modal)` selector, root-state class, and reusable lock manager were rejected because the application currently mounts one authentication modal and does not need global modal coordination. Hiding the dialog scrollbar was rejected because it would leave the inactive page scrollbar visible while concealing the active scroll position.

## Risks / Trade-offs

- [The sticky chrome may blend into similarly colored content] -> This is the requested seamless treatment; the fixed grid position still communicates the shell boundary spatially.
- [Removing the outline could hide keyboard focus] -> Apply a high-contrast, non-color underline only for `:focus-visible` and verify it through keyboard interaction.
- [Adding a compact prop expands the D20 component interface] -> Keep it optional with the current default appearance, preserving existing callers.
- [The AsyncAPI reference renderer depends on unpkg at page load] -> Pin the renderer version and keep the raw YAML endpoint first-party beside every rendered reference.
- [Filesystem checks happen when the developer page is requested] -> Check only the bounded registry entries and regular slug-matching files; do not parse document contents or call external metadata providers.
- [A dynamic file-serving route could expose unintended files] -> Resolve the slug through the registry before deriving the static application-relative path, and return not found for unknown or missing specifications.
- [Firefox and Safari before 26 do not apply the compact enhancement] -> Keep the expanded header as the complete functional fallback and gate every timeline declaration with feature detection.
- [The footer is no longer persistently visible on long pages] -> Keep it after the main region in ordinary document order and at the viewport end on short pages; the request preserves pinned-header behavior, not a second bounded scrollport.
- [The expanded header reserve could leave empty space after compaction] -> Keep the reserve in document flow so ordinary scrolling consumes it, and verify the first interactive content meets the compact header without a persistent gap or jump at desktop and mobile widths.
- [Animating layout dimensions can require layout work during the first 24 pixels of scrolling] -> Keep the fixed header outside the root scroll range, limit the range to the small pinned surface, and keep interpolation in CSS; the reactive guard only changes the header class when crossing the top boundary.
- [Mobile Safari can differ in viewport and root-scroll behavior around the virtual keyboard] -> Use the standards-mode `document.scrollingElement`, keep the dialog as the independent `100dvh` scroller, and validate supported desktop browsers plus the available mobile viewport while retaining real-device iOS verification as a residual risk.

## Migration Plan

Apply the component style and read-only route changes without data or deployment migration. Rename the Koala specification file with its registry slug as part of the same deploy. Roll back the developer entry point by removing the `/developers` route/page, AsyncAPI Plug and routes, and restoring the previous footer link.

## Open Questions

None.


## Header proportions review - 2026-09-08 (#268)

This contract update supports the ongoing `add-informative-home-footer` visual review in its owning worktree. Reduce all brand mark dimensions, label font sizes, letter spacing and brand gaps to 75 percent. Mark sizes become 1.959rem by 2.25rem on desktop, 1.63275rem by 1.875rem at 34rem and below, and 1.3065rem by 1.5rem when compact. Label sizes become 0.65625rem expanded and 0.5625rem compact. Log in uses 1.875rem expanded/1.5rem compact minimum height, 0.75rem inline padding, 0.6rem type and 75 percent of the existing corner radius. Keep native sizes rather than a visual transform.

The follow-up spacing correction reduces header minimum block sizes to 3.75rem desktop, 3.375rem narrow and 2.3625rem compact. Remove stacked block padding and use the existing flex alignment to center the contents, leaving 0.75rem around the expanded mark and 0.43125rem when compact, a 15 percent increase from the prior 0.375rem inset. The minimum interpolates with the existing root-scroll keyframe; update both layout reserve and root scroll padding to the expanded heights. Catalog/footer intervals, edge alignment and reduced-motion/unsupported-browser behavior remain intact. Existing focus indicators, brand/login dimensions and authenticated account-link dimensions are preserved; the account controls fit inside the centered row. Validate root-aligned targets and initial content against the smaller fixed header. Rollback restores the preceding height/reserve declarations and matching references.

Validate size ratios and fixed header heights in desktop, narrow and compact states, login opening/closing, existing header/layout browser tests, affected page screenshots, scoped formatting/lint and type checks. #268 owns this styling increment; existing developer-list and lifecycle tasks remain open.


## Inactive scroll timeline correction - 2026-09-08

At 697x807, opening both footer disclosures allows scrolling. After compaction, closing them can remove overflow and clamp root scrolling to zero while Chromium retains animation progress at one. The 37.8px header then leaves a 22.2px blank region inside the 60px expanded reserve. Use Svelte's reactive window scroll offset to disable the existing CSS animations at zero; CSS continues to interpolate the scrolled state. This changes no reserve or viewport breakpoint and introduces no dimensions observer or custom scroll listener. Verify the actual content-shrink transition, restored expanded geometry, existing 12px/24px scroll progress, reduced motion and keyboard behavior.
