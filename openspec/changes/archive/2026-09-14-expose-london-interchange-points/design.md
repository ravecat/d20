## Context

`Rules.score_player/2` already computes interchange counts and their aggregate score. `Projection.render/2` obtains these scores on every projection, including reconnects and spectators. The client cannot fill printed category result boxes without duplicating rules. Issue: https://github.com/ravecat/d20/issues/285.

Official reference: English Blue Orange rulebook, scoring section, https://blueorangegames.eu/wp-content/uploads/2023/05/NextStationLondon-Rules-EN.pdf. Reuse the previously stored `assets/public/rules/next_station_london.pdf`; SHA-256 `c46e61286ce5c09fb6100f9e4132d9da5840bd9b5590dc2251ef4a7f408cd8c7`, verified 2026-09-14. Existing publisher artwork rights remain unchanged; this change neither replaces nor redistributes the asset.

## Goals / Non-Goals

**Goals:** Project complete authoritative interchange points for categories 2, 3, and 4, including zero values, and retain existing totals.

**Non-Goals:** Change scoring rules, Thames scoring rows, persistence, commands, game lifecycle, or production activation.

## Decisions

Compute `interchange_points` from counts with `Ruleset.interchange_score/1`, then sum that map for `interchange_score`. This preserves one scoring calculation. Integer Elixir map keys serialize as string JSON keys. Require all three keys and prohibit others in AsyncAPI. Scores remain derived from existing game state, so finished sessions need no migration.

Validate empty and mixed-category scores in Rules tests, caller and spectator projection fields, and channel serialization. A local HTTP request can invoke Phoenix development code reload; subsequent channel rejoin regenerates the read model without restarting the session runtime.

## Risks / Trade-offs

A client updated before its backend receives the field can still show empty values. Coordinate both repository changes and reload the backend module before checking the client. Reverting requires coordinating removal of the client binding; no stored data rollback is needed.

## Open Questions

None.
