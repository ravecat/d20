## Context

`assets/js/pages/game.svelte` renders the `/games/:slug` detail page from Inertia props: `slug`, `game`, `module`, `connection`, and `session`. The `game` prop has runtime metadata fields in `GameMetadata`, while `SessionPanel` owns realtime session state, the `Start` command, joined players, and the module iframe.

The current page renders the preview, a clamped description, and either a standalone `Play` button or the session panel in a vertical flow. Long descriptions and session controls share the same content flow, so activation can move away from the visible part of the page.

## Goals / Non-Goals

**Goals:**

- Make the detail content below the preview a 40/60 split on desktop: activation on the left, description on the right.
- Keep long descriptions readable in a scrollable area without moving activation controls.
- Render player range, play-time, age, complexity, and rating metadata from game metadata API props.
- Keep the page-level no-session activation CTA in the left panel.
- Keep session start, joined players, and module frame behavior owned by the existing `SessionPanel`.
- Preserve existing routes, session creation, session channel commands, and module iframe contracts.
- Preserve the existing `SessionPanel` public props API.
- Preserve accessible labels, disabled states, loading states, error states, and responsive behavior.

**Non-Goals:**

- Changing game engine rules, session persistence, or the iframe module protocol.
- Adding a new metadata provider or replacing BoardGameGeek as the current metadata source.
- Adding a new frontend dependency just for metadata icons.
- Redesigning the home catalog or game module UIs.

## Decisions

1. Keep the preview hero separate from the split layout.

   The preview image, title chip, categories, and mechanics remain the first visual section. The new 40/60 layout starts below the preview, so the change is scoped to the detail content and activation area.

   Alternative considered: make the preview part of the left column. That reduces vertical height, but it weakens the current game identity treatment and makes the activation panel compete with image cropping decisions.

2. Use a CSS grid ratio rather than fixed pixel widths.

   The desktop layout should use a 2fr/3fr split, equivalent to 40/60, with `minmax(0, ...)` tracks so long text does not overflow. At narrow widths, the panels stack in source order: activation first, description second.

   Alternative considered: fixed `60%` and `40%` widths. This is less resilient with gaps, padding, and narrow desktop widths.

3. Make only the description panel scroll.

   The right description panel receives a bounded block size and internal overflow. The activation panel stays visible as one coherent block containing metadata and either the page-level no-session CTA or the existing `SessionPanel`.

   Alternative considered: clamp the description as it does today. That hides rules-context text the user explicitly wants available.

4. Keep metadata label formatting with the metadata label components.

   `game.svelte` owns the metadata row and passes the `GameMetadata` object directly into the player-count, play-time, age, complexity, and BGG rating label components. Those label components own their icons, accessible labels, chip styles, and formatting helpers. Player range uses `minPlayers` and `maxPlayers`. Play time uses `minPlayTime` and `maxPlayTime` when they define a real range, otherwise `playingTime` or whichever single value is available. Age uses `minAge`. Complexity uses the domain `complexity` field, populated from BGG `averageweight` when source statistics are available. Rating uses the domain `rating` field, populated from BGG `average` when source statistics are available. Textual unit labels are avoided so localization is not encoded in these chips. Missing provider values must not be replaced by game-specific hardcoded numbers or placeholder labels.

   Alternative considered: use engine rule limits such as Koala Rescue Club's `Ruleset.player_count_range/0`. That may become the right source for authoritative playability, but the requested page copy says the range comes from the game API, and the current API surface is `GameMetadata`.

5. Keep page-level activation scoped to session creation.

   `Play` is used on the game page only while the next action creates a new session. Once a session exists, the existing `SessionPanel` owns the `Start` action, session start permissions, processing state, joined players, and module frame behavior. The panel-owned `Start` action should visually match the page-level primary CTA.

   The no-session CTA fills the activation panel width so the primary action reads as the central action for that block, not as a small inline control.

   Alternative considered: pass the server session snapshot into `SessionPanel` and reshape the panel into page-specific `Start` and `Play` states. That creates two session sources of truth and changes the panel API for a page-layout change.

6. Keep one owner for realtime session state.

   `SessionPanel` remains the only owner of realtime session state via `createSession(...)`. The game page passes only `module` and `connection`, as before, and does not pass an additional `session` prop or initial session fallback. The joined-player area remains inside `SessionPanel`.

   Alternative considered: duplicate session presence logic in `game.svelte`. That would be faster to sketch but risks split loading, error, and permission behavior.

## Risks / Trade-offs

- Provider metadata can be missing or differ from engine limits - the UI must avoid hardcoded and placeholder fallbacks, and implementation tests should cover missing metadata. A future API change can reconcile provider metadata with engine-authoritative limits if needed.
- Complexity and rating depend on BGG statistics being requested with `stats=1`; missing or zero source values should omit the corresponding label rather than inventing a value.
- A scrollable description can create nested scroll behavior on small screens - mobile layout should stack and allow normal page scrolling unless there is enough vertical space for an internal scroll region.
- Moving session UI can break existing tests around `SessionPanel` - preserve the panel API and keep its focused tests on existing behavior.
- CTA meaning can be confused between session creation and game start - keep page-level `Play` scoped to creating a session and leave waiting-session `Start` inside `SessionPanel`.
- Failed joined-player presence can produce non-actionable copy - keep the loading state, but omit unavailable-presence text when there are no visible members.

## Migration Plan

1. Update BGG metadata parsing, Svelte layout, metadata label components, and styling for the game detail page.
2. Place the existing `SessionPanel` inside the activation panel without changing its props API or session ownership.
3. Add or update focused Vitest coverage for metadata formatting, no-session CTA, preserved `SessionPanel` API, and responsive-safe DOM structure.
4. Add backend coverage for newly exposed metadata fields.
5. Roll back by restoring the previous vertical detail flow and standalone session panel placement.

## Open Questions

- Should a later change replace provider-derived player counts with engine-authoritative player limits when both are available?
