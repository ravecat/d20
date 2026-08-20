## Context

The application currently treats implemented games as an overlap of three separate concerns:

- `D20.Games` exposes mock game metadata keyed by slug.
- `D20.Module.Manifest` maps slugs to session engines.
- `priv/modules/registry.json` maps slugs to iframe sandbox settings.

The intended model is stricter: a game is playable only when the application has a local engine for it. BGG is an external metadata provider for implemented games, not the source of which games exist in the application. The registry should therefore describe implemented games with only stable operational fields and derive display metadata at runtime.

## Goals / Non-Goals

**Goals:**

- Introduce a single registry for implemented games.
- Use the registry map key as the internal game slug.
- Keep each game entry limited to stable fields: `engine`, `bgg_id`, and `sandbox`.
- Resolve engine lookup, game listing, game page lookup, and iframe sandbox policy from the game registry.
- Resolve display metadata such as title, description, and preview image at runtime using `bgg_id`.
- Preserve public `/games/:slug` URLs and existing session lifecycle semantics.
- Make catalog tiles navigate to game detail pages by internal slug.

**Non-Goals:**

- Do not add a database-backed game catalog in this change.
- Do not require implementing all BGG games.
- Do not make BGG id the primary application identity.
- Do not store title, preview URL, description, player counts, or other provider-derived metadata in the stable registry.
- Do not require live BGG availability for session creation or engine dispatch.

## Decisions

1. The game registry owns playable game declarations.

   Use a new `D20.Games.Registry` configuration shape:

   ```elixir
   config :d20, D20.Games.Registry,
     games: [
       qwinto: [
         engine: D20.Qwinto.Game,
         bgg_id: 183_006,
         sandbox: ["allow-scripts", "allow-same-origin"]
       ]
     ]
   ```

   The key `:qwinto` is the internal slug. It is not duplicated as a `slug` field inside the entry. This keeps the stable entry focused on operational bindings.

   Alternative considered: keep `D20.Module.Manifest` and `priv/modules/registry.json`. That preserves existing code structure but keeps the source of truth split across config, JSON, and mock metadata.

2. Game display metadata is runtime-derived.

   `title`, `preview_url`, `description`, player counts, and other display fields should come from a metadata resolver, initially backed by BGG using `bgg_id`. These fields may be cached at runtime, but they must not become required stable registry fields.

   Alternative considered: store `title` and `preview_url` in config. That makes the `/games` catalog simpler, but it reintroduces manually maintained metadata and makes BGG enrichment secondary instead of authoritative for display data.

3. BGG id is required for catalog metadata, but not the application identity.

   Each registry entry binds to BGG with `bgg_id` so runtime metadata can be fetched without searching by name. The internal slug remains the route, session, and engine lookup identity.

   Alternative considered: look up games by title at runtime. That is fragile because names are localized, duplicated, and can map to multiple editions.

4. Iframe sandbox policy belongs to each game entry.

   Sandbox policy is game-specific and operationally tied to whether the local game module can run. It should live beside the engine in the registry instead of in a separate JSON registry.

   Alternative considered: keep a module registry JSON. This only pays off if the JSON becomes a build artifact registry with entrypoints, hashes, or independently generated module metadata. Current usage is only sandbox policy, so it is unnecessary split state.

5. Existing module manifest API is removed after migration.

   Code that previously called `D20.Module.Manifest.fetch/1` and `D20.Module.Manifest.fetch_engine/1` should call `D20.Games.Registry` directly. The old manifest module should not remain as a compatibility proxy because it would keep two names for the same registry boundary.

## Risks / Trade-offs

- BGG unavailable at render time -> game metadata lookup returns a source error; session creation remains independent because it uses the local registry engine.
- BGG id points to the wrong record -> the wrong display metadata appears for an implemented engine; tests and review should verify configured ids for shipped games.
- Removing `priv/modules/registry.json` too early -> any undiscovered consumer of the file breaks; implementation should search for all reads and include regression tests.
- Runtime metadata adds latency -> resolver should be isolated so caching, timeout, or stale data behavior can be added without changing registry semantics.
- Config validation becomes stricter -> invalid engines, invalid sandbox values, or missing `bgg_id` should fail clearly during lookup or boot-time validation, depending on final implementation.

## Migration Plan

1. Add `D20.Games.Registry` config with one entry for `qwinto`.
2. Implement registry accessors for listing games and fetching full entries by slug.
3. Move game list and game page lookup from mock metadata to registry-backed records enriched by runtime metadata.
4. Move session creation engine lookup from `D20.Module.Manifest` to the game registry.
5. Move iframe manifest lookup from `priv/modules/registry.json` to per-game registry sandbox policy.
6. Remove `D20.Module.Manifest` and `priv/modules/registry.json` after all call sites are migrated.
7. Add tests for registry validation, route behavior, session creation, metadata source errors, `/games` catalog rendering, and `/games/:slug` detail rendering.

Rollback is straightforward because no database migration is planned: restore the previous config, `D20.Module.Manifest` lookup, JSON registry, and mock metadata if registry resolution regresses.

## Open Questions

- Should missing or invalid `bgg_id` fail application boot, or should it fail only when metadata is resolved?
- Should runtime metadata be fetched synchronously during controller rendering, or should the page render with placeholders and fetch metadata asynchronously?
