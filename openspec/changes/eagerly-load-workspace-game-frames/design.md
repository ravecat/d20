## Context

The persistent workspace renders one `Frame` for every authoritative in-progress or finished session descriptor, even when the browser-local layout presents that session as Compact. Compact mode hides the frame wrapper with `content-visibility: hidden` where supported and otherwise with `display: none`, while `inert` prevents interaction.

`Frame` currently adds `loading="lazy"` to the iframe. Firefox was observed leaving such a Compact iframe at `about:blank` until the player expands it, even though the shell workspace is ready and labels the session Live. Each descriptor already contains a signed module token, and `D20.Module.Token` verifies it with the configured 600-second maximum age. A frame first loaded after that interval attempts its module socket connection with expired credentials and the embedded client reports unavailable game state.

Existing tests prove that Svelte preserves the iframe DOM node and creates one SDK bridge across layout transitions. They do not prove that the iframe document loads or that its iframe-owned Phoenix session starts while Compact.

## Goals / Non-Goals

**Goals:**

- Start iframe navigation, SDK bootstrap, and iframe-owned realtime setup as soon as an authoritative workspace session is mounted.
- Keep Compact content visually hidden, non-interactive, and absent from sequential focus and assistive-technology workflows.
- Preserve one iframe node and SDK bridge across Compact, Theater, and fullscreen.
- Add a browser regression that fails when a Compact iframe remains deferred and can be run with Firefox.

**Non-Goals:**

- Change module token claims, maximum age, renewal, or socket authentication.
- Add iframe readiness to the workspace descriptor or public workspace protocol.
- Redefine the Compact Live badge, add a second per-game controller to the shell, or expose embedded game content in Compact.
- Change iframe URLs, allowed origins, sandbox policy, presentation geometry, or separately delivered game clients.
- Keep an iframe mounted after its authoritative workspace descriptor is removed.

## Decisions

1. Explicitly mark workspace game frames as eager.

   `Frame` will render `loading="eager"`. The HTML default is eager when the attribute is omitted, but the explicit value makes the credential-lifetime requirement visible and prevents a later performance edit from reintroducing deferred runtime startup.

   Alternative considered: extend the module token lifetime. This only widens the failure window and still lets Compact report a game as Live before its iframe runtime exists.

2. Keep the existing Compact hiding and lifecycle model.

   The iframe remains mounted under the current wrapper and continues to be hidden with `content-visibility` or the `display: none` fallback plus `inert`. Eager navigation is independent of whether the browser chooses to render the subtree, so the iframe-owned connection can start without making the game visible or interactive.

   Alternative considered: move the Compact iframe offscreen or replace `content-visibility`. That expands layout and accessibility risk without addressing the actual lazy-loading instruction.

3. Verify loading before expansion in a real browser.

   Focused browser coverage will mount a Compact workspace session whose iframe uses a deterministic data document, subscribe to the iframe load event before yielding, and require the load to complete before activating the restore surface. It will then assert that expansion retains the same iframe element and SDK bridge. The Vitest browser project will declaratively run every browser test in both Playwright-managed Chromium and Firefox.

   Alternative considered: assert only the `loading` attribute in a simulated DOM. That checks markup but does not prove the Firefox interaction between iframe lazy loading and a skipped rendering subtree.

## Risks / Trade-offs

- [Every active session now loads its game module and opens its iframe-owned socket even while Compact] -> This matches the existing architecture and Live semantics; the workspace only mounts authoritative active or retained finished sessions and already promises runtime continuity for each mounted frame.
- [More simultaneous active sessions increase network and memory use] -> Preserve authoritative workspace removal and Close behavior so inactive sessions still unmount; do not add speculative frames.
- [A data-document load test may pass without exercising production networking] -> Keep the test focused on the browser scheduling boundary and separately assert stable iframe and bridge identity; existing channel and module tests continue to cover credentials and realtime contracts.
- [Running every browser test in Chromium and Firefox increases suite duration] -> Keep both instances in one Vitest browser project so they share the Vite server and make the supported-browser coverage explicit.
- [Existing browser tests may target progressive enhancements unavailable in Firefox] -> Gate those assertions with the same runtime capability query used by the production `@supports` fallback.
- [Browser execution depends on installed Playwright browser binaries] -> Install the version-matched Chromium and Firefox binaries through Playwright instead of configuring machine-specific executable paths.

## Migration Plan

1. Deploy the frontend change without backend coordination or data migration.
2. Existing workspaces receive eager behavior after their next full page load; newly mounted descriptors begin loading immediately.
3. Roll back the frontend attribute and test configuration if necessary. No stored data, token format, or protocol rollback is required.

## Open Questions

None.
