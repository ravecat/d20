## Context

In production, Inertia mounts routed Svelte pages through `assets/js/app/layout.svelte`, which owns the persistent header, scrollable main region, footer, and workspace. Storybook currently imports the same page components but renders them directly. The preview already replaces Inertia and session dependencies with deterministic mocks, while individual story declarations distinguish route-level pages from shared components and widgets.

## Goals / Non-Goals

**Goals:**

- Reuse the production layout without copying its chrome into Storybook.
- Make the page-shell choice explicit and reusable across all complete page stories.
- Identify complete page story groups by their production route paths without changing stable story IDs.
- Supply a stable default Inertia page context while allowing each page story to keep its own component arguments.
- Preserve story IDs and component/widget isolation.

**Non-Goals:**

- Reproduce the Phoenix request lifecycle or backend navigation in Storybook.
- Apply the application shell globally to shared components and widgets.
- Change production page-layout scrolling, routes, page props, or workspace behavior.

## Decisions

### 1. Select the shell with a reusable page decorator

Storybook infrastructure will export one `withLayout` decorator factory that accepts the route URL and optional layout variant. Each full-page story meta explicitly registers the decorator, which renders the story as the `children` snippet of the production `Layout` component. This keeps one wrapper implementation, makes the page boundary visible at the story declaration, and prevents directory names or title strings from becoming implicit behavior.

Duplicating the decorator implementation in each story was rejected because it makes drift more likely. A global decorator gated by a custom parameter was rejected because it runs for unrelated stories and hides the page boundary in shared preview configuration. Wrapping every story globally was rejected because shared components and widgets require isolated canvases.

### 2. Keep layout context in the existing Storybook Inertia mock

The decorator will set deterministic page data in the existing Storybook mock before rendering the layout. The context contains the concrete route URL and the story's authentication args required by the shared header/footer boundary; page components continue receiving their normal args independently. Anonymous pages use anonymous authentication state, while authenticated route states such as magic-link reauthentication pass authenticated state through the same adapter.

Complete routed page metadata uses U+2215 DIVISION SLASH for route separators so Storybook keeps each path as one group under `Pages`; the existing manager label renderer converts every division slash to an ASCII slash for display. Explicit component IDs preserve existing story URLs. Registration Completion therefore uses `/users/register/complete` as its visible label while retaining the `pages-sign-up-registration-completion` ID.

The magic-link confirmation stories retain their stable Storybook ID but use `/users/log-in/:token` as the visible route label and `/users/log-in/storybook-login-token` as the concrete Inertia URL. Confirmation and Reauthentication remain states of that route, with anonymous and authenticated layout context respectively.

Building a second Storybook-only header/footer was rejected because it would not validate the production shell. Extending production layout props for Storybook was rejected because the context is an adapter concern, not an application contract.

### 3. Model authentication dialogs through complete Home stories

Only stories whose component is a complete Inertia page opt into the shell. Authentication-dialog states are exercised through complete Home stories rather than detached fullscreen modal examples.

Complete Home page stories open those dialogs through the production Header. Home Sign In and Home Sign Up are the canonical initial authentication scenarios, so the duplicate standalone Login Methods and Registration Methods stories and their visual baselines are removed. The Magic Link Sent outcome also becomes the Home `Sign In Sent Magic Link` interaction story, which opens the dialog through the Header before applying the deterministic success transition.

Email-backed reauthentication becomes the Home `Confirmation With Magic Link` story. Its authenticated page args carry the production reauthentication prompt, allowing the Header's existing prompt effect to open the locked-email dialog exactly as routed application context does. The remaining Provider Only Reauthentication standalone story is removed, leaving no Sign In authentication-dialog group. Its production behavior remains covered by the focused Header browser test rather than a catalog state.

Confirmation Email Sent becomes the Home `Sign Up With Email` story. It opens registration through the production Header and applies the deterministic registration success transition with local email-delivery context, preserving the confirmation outcome without a live backend. Removing its detached predecessor leaves no standalone Sign Up authentication-dialog group or authentication-dialog fixture.

Keeping duplicate or detached authentication states was rejected because they create redundant catalog navigation or omit the production page context. Title-based inclusion of every file under `stories/pages` was rejected because that folder can also contain modal content examples.

### 4. Scroll the modal layer instead of the authentication panel or background page

The native `dialog` fills the viewport as a transparent, shaded modal scroll boundary. The existing `.auth-panel` becomes the intrinsic-height visible surface, so its title and content move together when the panel is taller than the viewport. Flex auto margins center the panel when it fits and collapse to the modal safe-area padding when it overflows. The production page remains visually stationary and interaction-inert behind the layer.

Keeping `overflow-y: auto` on `.auth-panel__content` was rejected because it creates a nested scrollbar inside the visible window and leaves the title stationary. Scrolling the underlying document was rejected because the background would move under a modal. Because the full-viewport `dialog` receives clicks outside the visible panel, a target check closes it when the shaded overlay itself is clicked while preserving native Escape and close-button behavior.

## Risks / Trade-offs

- [The shared layout increases full-page screenshot area and can expose existing workspace/mock assumptions] -> Keep the mock deterministic and validate every opted-in page story through the existing visual matrix.
- [A future page story could omit the decorator] -> Add focused coverage for explicit routed-page registrations and keep the shared factory import visible in each page story.
- [Story args and layout page context can diverge] -> Limit the layout context to shell-owned shared data and let story args remain authoritative for page-specific scenarios.
- [Moving the visible surface inside the native dialog changes the responsive overflow boundary] -> Preserve the existing width and safe-area spacing on the panel, then review sign-in and sign-up at every visual-test viewport.
