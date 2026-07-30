## Context

`D20.Games.Registry` is already the local source of truth for catalog identity, availability, engine binding, BGG id, and iframe sandbox policy. `D20.Games`, however, currently constructs `D20.Games.Game` records only from a synchronous BGG response. `D20Web.PageController` therefore receives a provider error for a registered game and maps it to `404`, while a failed batch request makes the home controller publish an empty catalog.

This coupling is unnecessary for gameplay. Session creation, session lookup, engine dispatch, and iframe framing already use local registry data. The existing Svelte pages support absent names, images, descriptions, ratings, and numeric metadata. A nameless catalog card remains a linked generic preview with the accessible label `Open game`.

## Goals / Non-Goals

**Goals:**

- Keep every valid registry game discoverable and every launch-eligible game playable without BGG credentials or availability.
- Preserve BGG as the preferred enrichment source when it succeeds.
- Keep the registry limited to operational bindings rather than duplicate presentation metadata.
- Distinguish an unknown local slug from unavailable external metadata.
- Preserve current routes, Inertia prop shapes, session state, engine behavior, and iframe contracts.
- Make degraded operation diagnosable without leaking credentials.

**Non-Goals:**

- Do not add persistent metadata storage, a database migration, or a runtime cache.
- Do not proxy BGG through another service or introduce a second metadata provider.
- Do not copy the full BGG dataset into application configuration.
- Do not add a user-facing provider outage banner.
- Do not change catalog ordering, game availability policy, or session authorization.

## Decisions

1. Keep display metadata out of registry entries.

   The registry remains responsible for slug, BGG id, status, engine, and sandbox. When BGG metadata is unavailable, `D20.Games` uses an empty metadata map and allows `D20.Games.Game.name` and the other optional display fields to remain `nil`.

   Alternative considered: add a local display name to each registry entry. This makes degraded cards easier to identify, but duplicates presentation data solely for an outage state and makes the operational registry responsible for a second concern.

   Alternative considered: synthesize a title from the slug. This avoids configuration edits but can produce incorrect punctuation, capitalization, subtitles, and branding.

2. Select metadata attributes before constructing the game.

   `D20.Games` will pass successful BGG attributes or an empty fallback map to `D20.Games.Game.new/1` exactly once. The registry remains authoritative for slug, status, engine, and sandbox. BGG remains the only source of display fields.

   `fetch_by_slug/1` will first resolve the registry entry. An absent registry entry remains `{:error, :game_not_found}`. Once an entry is found, missing configuration, HTTP failures, timeouts, parse errors, or a missing BGG item produce an empty game rather than an error exposed to the controller.

   Alternative considered: handle provider errors in `D20Web.PageController`. That would duplicate fallback assembly between detail flows and leave catalog behavior coupled to the provider. The fallback belongs in the `D20.Games` context, where metadata and registry data are composed.

3. Preserve partial success in catalog enrichment.

   `list/0` will always begin with the ordered registry entries. A successful batch response will enrich entries by `bgg_id`; any entry omitted from the response will use empty fallback metadata. A batch-level error will use empty fallback metadata for all entries. This keeps catalog membership and ordering independent of provider behavior.

   Alternative considered: fall back the whole batch if one BGG item is missing. That discards valid metadata already returned for other games and makes one upstream data issue affect the entire catalog.

4. Treat missing credentials explicitly before HTTP execution.

   `D20.Games.Sources.BoardGameGeek` will return a stable missing-configuration error when its configured key is `nil` or empty. It will not build a `Bearer` header or call `Req` in that state. Outside production this enables local development with fallback metadata. `config/runtime.exs` will retain a fail-fast production check because a missing production credential is a deployment configuration error, not an expected degraded state.

   Alternative considered: allow production startup without the key. This would improve availability during secret provisioning failures, but it would also hide a deployment error. Upstream BGG failures still use fallback after production starts with a configured key.

5. Keep the existing client contract and fallback components.

   Backend props will continue to serialize a `GameMetadata` object with arrays and nullable optional fields. Existing home and detail components already omit an absent title, render non-image previews, hide absent labels, show an empty-description message, and give nameless catalog links the accessible label `Open game`.

6. Observe enrichment failures at the context boundary.

   `D20.Games` will log a sanitized provider failure reason when it chooses local fallback data. Logs will identify batch or single-game enrichment context without serializing adapter configuration, request headers, or the API key. The controller will no longer log catalog failure for ordinary BGG degradation because the catalog result remains successful.

## Risks / Trade-offs

- Repeated upstream failures can produce repeated warning logs because this change adds no cache. Mitigation: keep log data concise and add caching or rate-limited telemetry in a separate change if operational volume warrants it.
- Nameless degraded cards are harder to distinguish visually. Mitigation: accept this limited degraded experience so gameplay stays available without adding a second display metadata source.
- Returning fallback data changes `D20.Games` provider-error semantics. Mitigation: preserve explicit source errors at the BGG adapter boundary and update context tests to assert graceful composition rather than propagated provider failure.
- The production key requirement makes a secret provisioning mistake fail deployment. Mitigation: keep the startup message explicit while allowing local development without the key.

## Migration Plan

1. Make the BGG adapter return an explicit error without network access when the key is absent or empty.
2. Select empty fallback or enriched metadata in `D20.Games`, preserving partial batch success.
3. Retain the production startup exception for a missing BGG key and document that the key is optional only outside production.
4. Update context, source adapter, controller, and existing frontend fallback tests.
5. Deploy without persistence migration. Existing registry configuration, session records, and module connections require no transformation.

Rollback requires restoring provider-error propagation. The registry shape and strict production key check remain unchanged. No data rollback is necessary.

## Open Questions

- None. Persistent caching and additional metadata providers remain separate future changes.
