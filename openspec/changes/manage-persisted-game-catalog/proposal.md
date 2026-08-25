## Why

The catalog currently couples local game identity, BoardGameGeek bindings, engine selection, and launch stage in application configuration, so an operator must change code and redeploy to correct or disable a game. A persisted local identity and a protected operator surface let D20 manage those operational bindings without making external metadata authoritative or introducing a second public slug identity.

Owning issue: [#223 - Operators Can Manage Game Catalog Records](https://github.com/ravecat/d20/issues/223)

## What Changes

- Replace the hardcoded `D20.Games.Registry` configuration with persisted `games` rows and migrate all nineteen current entries.
- Make `games.id` a string-backed TypeID with the `game` prefix and the stable local game identity across catalog, detail, session runtime, Workspace, module HTTP, module socket token, and iframe-host boundaries.
- Keep BoardGameGeek-derived names runtime-only and omit public game slugs from this change. Use the stable `game_...` local id exclusively for public catalog, detail, and Session-creation URLs.
- Store an editable positive unique `bgg_id`, `stage` (`planned`, `in_development`, or `released`), `enabled` flag, and nullable integer-backed engine enum with permanent module mappings.
- Require a valid engine for in-development and released records while allowing planned records to omit one.
- Make `enabled` an independent gate for new session creation only. Disabled games remain discoverable, expose no launch action, and reject direct creation through both existing HTTP boundaries without affecting live sessions or channels.
- Add a Backpex game resource rooted directly at `/dashboard` for listing and inline-editing only the four operator-managed fields, using the schema enums as the single source for select values and no proxy controller or redirect.
- Protect the administration area with existing D20 account authentication and one shared persisted `admin` role requirement across HTTP and LiveView, while keeping the Bodyguard `D20.Games.Policy/:manage_games` capability check inside the Backpex game resource; treat successful Inertia authentication as a full-page navigation so it can return to non-Inertia destinations without path-specific authentication coupling; keep the non-self-service string-backed `users.role` enum (`user` or `admin`), and assign or revoke administrator access only through explicit trusted database operations outside application and release interfaces.
- **BREAKING:** Replace slug-based game routes and module endpoints with stable `game` TypeIDs; update session state, scope, token claims, DNS-safe module hosts, Workspace payloads, AsyncAPI, Inertia props, Svelte types, and navigation accordingly.
- **BREAKING:** Replace the optional `status` catalog contract with required `stage`; engine changes affect only sessions created after the edit.

## Capabilities

### New Capabilities

- `game-catalog-administration`: Defines persisted game integrity, operator-editable fields, protected Backpex access, and trusted database-managed administrator assignment.

### Modified Capabilities

- `playable-game-registry`: Replace the configured slug registry with persisted id-keyed game records and permanent engine mappings.
- `game-catalog`: Populate and link catalog entries exclusively by persisted local game id.
- `game-catalog-availability`: Replace optional status with implementation stage and preserve the migrated catalog and ordering.
- `runtime-game-metadata`: Resolve presentation metadata by persisted `bgg_id` without deriving a public game slug.
- `game-metadata-fallback`: Keep id-based catalog and detail access independent of runtime metadata availability.
- `game-detail`: Resolve details only by local game id without slug variants or canonicalization.
- `game-detail-activation-layout`: Move the detail and launch URL contract from slug identity to id-only lookup.
- `game-session-launch-policy`: Combine implementation-stage policy with the independent enabled gate at both HTTP creation boundaries.
- `game-session-creation-attrs`: Submit creation attributes and redirect lobby navigation through id-based routes.
- `game-server-runtime`: Carry immutable local game id, rather than slug, in live Session server state and APIs.
- `koala-server-runtime`: Carry local game id through the custom Koala Session server contract.
- `session-actor-registry`: Return attached runtimes associated with local game id rather than slug.
- `multi-session-game-workspace`: Discover, authorize, frame, and reconnect sessions by local game id and update descriptor contracts.
- `session-workspace-lifecycle`: Keep Workspace and SessionChannel scope association id-based while preserving attachment and Presence behavior.
- `workspace-web-boundary`: Resolve persisted games by id when building complete Workspace snapshots.
- `finished-session-workspace-access`: Preserve finished-session access with id-based descriptors.
- `client-workspace-state`: Consume the revised id-based authoritative Workspace descriptor without client-owned normalization.
- `embedded-module-sandbox-policy`: Preserve the shared sandbox policy while making persisted game id the descriptor prerequisite.
- `game-module-frame-overlay`: Preserve frame behavior and bootstrap data under the revised id-based game URL and module identity contract.
- `next-station-london-gameplay`: Preserve the game activation binding in the migrated persisted record instead of a slug-keyed configuration entry.

## Impact

- Persistence: new `games` table with generated `game` TypeID primary keys and constraints/indexes; string-backed `users.role` enum with `user` default and `admin` elevation; complete backfill of all current game bindings; no BGG presentation columns.
- Backend: `D20.Games` schemas/context, removal of the configured registry seam, Session and custom-server state, scopes, channels, controllers, router, Workspace, module framing/token code, authentication, and developer-spec registry coupling.
- Frontend/contracts: string TypeID-based catalog/detail/lobby navigation, Workspace types and fixtures, module HTTP/token fields and DNS-safe TypeID-derived subdomains, and `priv/specs/workspace.yaml` plus affected public protocol tests.
- Dependencies/assets: Backpex 0.20 integration with the existing Phoenix 1.8, LiveView 1.1, Tailwind 4, daisyUI 5, Heroicons, Vite, and Bun setup.
- Runtime compatibility: existing in-memory sessions keep their captured engine and continue operating after game edits; no disable checks are added to channel or network paths.
- Deployment: migrate before serving the new release, assign the first administrator through trusted direct database access, and coordinate consumers of the breaking game-id module contract.
- Rollback: stop new-code traffic before rolling schema/code back; the down migration removes catalog/admin data, so retain a database backup or export current bindings before rollback. Runtime BGG metadata requires no migration.
