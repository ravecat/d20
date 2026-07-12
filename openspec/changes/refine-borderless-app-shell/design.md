## Context

The Svelte Inertia shell already uses a three-row `header / main / footer` grid, keeps only the middle region scrollable, and compacts the D20 brand after the content scrolls beyond 24 pixels. The current compact header adds a bottom border and shadow, the footer adds a top border, and the brand link uses a rectangular focus outline. The D20 component also reads its dimensions from CSS custom properties supplied by the header wrapper.

The refinement must preserve the shell geometry, Inertia scroll restoration, responsive brand dimensions, and keyboard accessibility while making the surrounding chrome visually seamless.

The footer currently links to the GitHub source repository. The product direction now treats the footer as the entry point for engineers who want to build compatible clients from game AsyncAPI contracts. Songy and Moda already establish a small Phoenix Plug pattern that serves raw YAML and renders an interactive reference with the standalone AsyncAPI React component. D20 can adapt that pattern for its two existing specifications without introducing a separate static-site build.

## Goals / Non-Goals

**Goals:**

- Remove visible edge borders and shadows from the header and footer in every scroll state.
- Remove the rectangular outline around the D20 brand while keeping keyboard focus unmistakable.
- Keep the existing default, narrow-screen, and compact brand dimensions.
- Make D20 dimensions explicit in the D20 component instead of passing them through CSS custom properties.
- Make `/developers` a clear internal destination from every game-shell footer.
- Present a polished index for the existing Qwinto and Koala Rescue Club AsyncAPI contracts.
- Publish an interactive reference and raw YAML endpoint for each listed contract.
- Keep router size constant as specifications are added by deriving endpoints from registered game slugs.
- Generate the developer index from registered games whose slug-matching static specification exists.

**Non-Goals:**

- Redesign page cards, game-detail panels, or nested scroll regions.
- Change the compact threshold or Inertia scroll contract.
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

## Risks / Trade-offs

- [The sticky chrome may blend into similarly colored content] -> This is the requested seamless treatment; the fixed grid position still communicates the shell boundary spatially.
- [Removing the outline could hide keyboard focus] -> Apply a high-contrast, non-color underline only for `:focus-visible` and verify it through keyboard interaction.
- [Adding a compact prop expands the D20 component interface] -> Keep it optional with the current default appearance, preserving existing callers.
- [The AsyncAPI reference renderer depends on unpkg at page load] -> Pin the renderer version and keep the raw YAML endpoint first-party beside every rendered reference.
- [Filesystem checks happen when the developer page is requested] -> Check only the bounded registry entries and regular slug-matching files; do not parse document contents or call external metadata providers.
- [A dynamic file-serving route could expose unintended files] -> Resolve the slug through the registry before deriving the static application-relative path, and return not found for unknown or missing specifications.

## Migration Plan

Apply the component style and read-only route changes without data or deployment migration. Rename the Koala specification file with its registry slug as part of the same deploy. Roll back the developer entry point by removing the `/developers` route/page, AsyncAPI Plug and routes, and restoring the previous footer link.

## Open Questions

None.
