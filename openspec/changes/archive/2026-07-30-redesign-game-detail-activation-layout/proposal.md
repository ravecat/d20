## Why

The game detail page currently places the description and session controls in one loose vertical flow, which makes the activation path compete with long BGG descriptions. The page needs a clearer game visualization layout where activation and game metadata stay prominent while the game description remains readable beside it.

## What Changes

- Redesign the `/games/:slug` detail content below the preview into a desktop 40/60 layout.
- Place game activation in the left panel and the runtime game description in a scrollable right panel.
- Present the metadata row with player count range, play time, age, complexity, and BGG rating at 1.125x the original visual scale.
- Render player count, play-time, age, complexity, and BGG rating labels through dedicated components that own their formatting helpers.
- Do not draw surrounding borders around the activation and description panels.
- Use player, play-time, age, complexity, and rating values from the game metadata API props rather than hardcoding game-specific values or placeholder labels.
- Keep the no-session primary CTA full-width in the activation panel and label it `Play`.
- Keep the waiting-session `Start` action inside `SessionPanel`, styled like the page primary CTA.
- Keep the module iframe overlay mounted after a session finishes so the embedded game can render its terminal state and results.
- Avoid rendering presence-unavailable copy inside `SessionPanel` when no joined players can see it.
- Render the existing `SessionPanel` in the activation panel once a session exists, without changing its public props API or session ownership.
- Preserve existing `/games/:slug`, `/games/:slug/sessions`, session channel, `SessionPanel`, and iframe module contracts.

## Capabilities

### New Capabilities

- `game-detail-activation-layout`: Defines the game detail page layout, metadata display, no-session activation CTA, and placement of the existing session panel.

### Modified Capabilities

- None. Existing active change specs define game lookup and base detail rendering, while this change adds a separate presentation capability for the detail activation layout.

## Impact

- Affected UI modules: `assets/js/pages/game.svelte`, `assets/js/components/session_panel.svelte`, metadata label components, and related Svelte tests. `SessionPanel` remains on its existing public API.
- Affected data contract: game detail props must expose `minPlayers`, `maxPlayers`, `playingTime`, `minPlayTime`, `maxPlayTime`, `minAge`, `complexity`, and `rating` when available from runtime metadata.
- Affected backend validation: BGG statistics parsing and game metadata serialization coverage.
- No database migration is required.
- No route, session creation, session channel, `SessionPanel` API, iframe module, or game engine behavior change is intended.
- Rollback impact is limited to restoring the previous detail page composition, session panel placement, and finished-session frame visibility.
