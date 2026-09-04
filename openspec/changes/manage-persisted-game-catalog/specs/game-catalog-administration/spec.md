## ADDED Requirements

### Requirement: Catalog games are persisted with database-enforced integrity
The system SHALL persist each game in the `games` table with a stable environment-local string-backed TypeID primary key generated with prefix `game`, a required immutable external `slug`, a positive unique `bgg_id`, required `stage`, required `enabled` flag defaulting to true, and a nullable integer-backed engine enum. Slug SHALL be unique, at most 63 characters, and match `^[a-z0-9]+(-[a-z0-9]+)*$`. The database SHALL enforce TypeID, slug, BGG, stage, and engine constraints. The system MUST NOT persist BoardGameGeek names, descriptions, images, or other presentation metadata.

#### Scenario: Valid planned game is stored
- **WHEN** an administrator creates a game with slug `new-game`, a unique positive BGG id, stage `planned`, and no engine
- **THEN** the schema generates a `game` TypeID and the database accepts the record
- **AND** enabled defaults to true

#### Scenario: Slug is missing
- **WHEN** a write attempts to create any game, including a planned game, without slug
- **THEN** the changeset and database reject the write

#### Scenario: Slug is invalid or duplicated
- **WHEN** a write supplies a slug outside the canonical DNS-safe format, longer than 63 characters, or already owned by another game
- **THEN** the changeset and database reject the write

#### Scenario: Invalid game identity is written directly
- **WHEN** a database write supplies an id without the canonical `game` TypeID representation
- **THEN** the database rejects the write

#### Scenario: Launch-stage game has no engine
- **WHEN** a write attempts to store stage `in_development` or `released` with a null engine
- **THEN** the changeset and database reject the write

#### Scenario: BGG binding is invalid or duplicated
- **WHEN** a write supplies a non-positive BGG id or a BGG id already owned by another game
- **THEN** the changeset and database reject the write

#### Scenario: Provider presentation is resolved
- **WHEN** BGG returns a name, description, image, or other presentation metadata for a persisted game
- **THEN** those values remain runtime-only
- **AND** persisted slug is neither regenerated nor overwritten
- **AND** no presentation column is written to `games`

### Requirement: Persisted slug is immutable through ordinary application operations
The system SHALL accept slug when creating a game and SHALL expose it as read-only after insertion. Ordinary update changesets and Backpex edit actions MUST NOT change slug. A slug rename SHALL require a separately coordinated data and infrastructure migration with explicit compatibility handling.

#### Scenario: Administrator views an existing game
- **WHEN** an administrator opens index, show, or edit for a persisted game
- **THEN** slug is visible as read-only identity
- **AND** no ordinary edit control can change it

#### Scenario: Update payload includes another slug
- **WHEN** an ordinary game update includes a different slug
- **THEN** the update changeset ignores or rejects the slug change
- **AND** the persisted slug remains unchanged

#### Scenario: BGG or engine binding changes
- **WHEN** an administrator edits BGG id, stage, enabled, or engine
- **THEN** slug, public route, and iframe host remain unchanged

### Requirement: Engine mappings are permanent and schema-owned
The `engine` Ecto.Enum SHALL load actual engine modules from permanent integer values `{D20.Fliptown.Game, 1}`, `{D20.KoalaRescueClub.Game, 2}`, `{D20.NextStationLondon.Game, 3}`, and `{D20.Qwinto.Game, 4}`. Numeric assignments MUST NOT be changed or reused, and a module rename MUST retain its assigned integer.

#### Scenario: Persisted engine is loaded
- **WHEN** a game row stores engine integer `4`
- **THEN** Ecto loads `D20.Qwinto.Game`
- **AND** the value passes `D20.Game.ensure_engine/1`

#### Scenario: Unknown engine integer is written
- **WHEN** a database write attempts to store an engine integer outside `1` through `4`
- **THEN** the database rejects the write

#### Scenario: Admin engine options are rendered
- **WHEN** Backpex renders the engine selector
- **THEN** its values come from `D20.Games.Game.engines/0`
- **AND** no second engine list is declared in the admin resource

### Requirement: Migration preserves every configured catalog game and slug
The data migration SHALL insert all nineteen games from the former `D20.Games.Registry` configuration with their exact canonical slugs, generated environment-local `game` TypeIDs, current BGG ids, equivalent stages, enabled true, and equivalent engine bindings. Generated TypeID timestamps SHALL increase in former registry order so K-sort ordering preserves that order without hardcoded cross-environment TypeIDs.

#### Scenario: Catalog migration completes
- **WHEN** the catalog migration runs
- **THEN** the exact nineteen former slugs are present and unique
- **AND** all rows have distinct canonical `game` TypeIDs
- **AND** Koala Rescue Club and Qwinto are released
- **AND** Next Station: London is in development
- **AND** every other game is planned
- **AND** only Fliptown, Koala Rescue Club, Next Station: London, and Qwinto have engines 1, 2, 3, and 4 respectively
- **AND** a later administrator-created game requires slug and receives another autogenerated TypeID

#### Scenario: Different environments run the migration
- **WHEN** local, staging, and production databases generate different TypeIDs
- **THEN** each migrated game keeps the same canonical slug in every environment

### Requirement: Authorized operators can create and edit game records
The system SHALL expose a Backpex game resource rooted directly at `/dashboard` where authorized administrators can create games with required slug and BGG binding, list and inspect games, view generated TypeID and persisted slug, and edit only `bgg_id`, `stage`, `enabled`, and `engine` after creation. Mutable fields MAY support independent inline updates through the update changeset and `:edit` authorization. The resource MUST NOT offer deletion, slug rename, persisted presentation metadata, or user administration.

#### Scenario: Administrator opens the dashboard root
- **WHEN** an authenticated administrator requests `/dashboard`
- **THEN** the Backpex game index mounts directly at that route
- **AND** no controller proxy or redirect is involved

#### Scenario: Administrator opens new game
- **WHEN** an authenticated administrator chooses the new action
- **THEN** Backpex renders required slug and BGG fields
- **AND** defaults stage to planned and enabled to true
- **AND** permits engine to remain empty

#### Scenario: Administrator creates a valid game
- **WHEN** an administrator submits a unique canonical slug and valid required fields
- **THEN** D20 persists the game with an autogenerated TypeID
- **AND** the slug becomes read-only

#### Scenario: Administrator edits a game
- **WHEN** an authenticated administrator submits a valid mutable-field change
- **THEN** Backpex persists the change
- **AND** TypeID and slug remain unchanged

#### Scenario: Administrator edits a table cell inline
- **WHEN** an authenticated administrator changes BGG id, stage, enabled, or engine from the index table
- **THEN** Backpex authorizes the operation as `:edit`
- **AND** persists that field independently through the update changeset
- **AND** does not expose slug as an inline-editable field

#### Scenario: Administrator submits an invalid combination
- **WHEN** an administrator duplicates slug or BGG id, supplies invalid slug or BGG id, or selects released or in-development stage with no engine
- **THEN** the form presents the constraint error
- **AND** the invalid write is not persisted

#### Scenario: Administrator opens resource actions
- **WHEN** an administrator views the game resource
- **THEN** new, index, show, and edit actions are available
- **AND** delete is unavailable

### Requirement: Administration entry requires an administrator and resources authorize their own actions
Every `/dashboard` route SHALL authenticate an existing `D20.Accounts.User` and require its persisted role to be `admin` at the HTTP boundary. One `live_session :dashboard` SHALL wrap the administrative scope and invoke the `D20Web.Auth` `:admin` hook, which re-resolves the persisted user before requiring the same role at each LiveView mount, reconnect, or live navigation. Resource actions SHALL remain independently authorized by their owning Bodyguard policies, with the Backpex game resource delegating new, create, index, show, and edit to `D20.Games.Policy/:manage_games`. The role SHALL be a persisted string-backed enum allowing only `user` and `admin`, defaulting to `user`, and MUST NOT be cast by ordinary account changesets.

#### Scenario: Anonymous visitor requests admin
- **WHEN** an unauthenticated visitor requests `/dashboard`
- **THEN** the existing authentication-required flow is used
- **AND** no admin content is exposed

#### Scenario: Ordinary authenticated user requests admin
- **WHEN** an authenticated user with role `user` requests an admin route
- **THEN** the shared administrator requirement returns forbidden

#### Scenario: Inertia authentication completes
- **WHEN** an Inertia authentication request succeeds with any safe return path
- **THEN** the response forces full-page browser navigation to that destination
- **AND** a non-Inertia destination such as Backpex is not parsed as an Inertia response

#### Scenario: Administrator connects or reconnects LiveView
- **WHEN** a user with role `admin` mounts, reconnects, or live-navigates within admin
- **THEN** the LiveView hook re-resolves that persisted user
- **AND** authorizes the mount before Backpex initializes

#### Scenario: Backpex evaluates a catalog action
- **WHEN** Backpex asks whether the caller may create, list, show, or edit a game
- **THEN** `can?/3` delegates to `D20.Games.Policy/:manage_games`
- **AND** it does not inspect the account role directly

#### Scenario: Another administrative resource is introduced
- **WHEN** a future administrative resource performs another privileged capability
- **THEN** shared HTTP and LiveView boundaries continue checking only administrator role
- **AND** that resource delegates actions to its own policy

#### Scenario: Account submits an administrator role
- **WHEN** registration, settings, provider completion, or another ordinary account request includes `role = admin`
- **THEN** the value is ignored
- **AND** the account retains role `user`

#### Scenario: Database write uses an unknown account role
- **WHEN** a database write attempts to store a role other than `user` or `admin`
- **THEN** the database rejects the write

### Requirement: Administrator assignment stays outside application interfaces
The system SHALL rely on explicit trusted database operations to assign or revoke the `admin` role for an existing account in each target environment. Application and release code MUST NOT expose a role-assignment function, command, HTTP endpoint, email input, environment variable, or automatic promotion rule.

#### Scenario: Operator assigns an existing account
- **WHEN** an operator with trusted database access assigns `admin` to one already registered account and verifies the affected row
- **THEN** that account can use administrator routes
- **AND** no application-level promotion interface is involved

#### Scenario: Development needs an administrator
- **WHEN** administrator access is needed in development
- **THEN** the role is assigned explicitly in the development database
- **AND** no production assignment or environment setting is reused

#### Scenario: Administrator access is revoked
- **WHEN** an operator with trusted database access changes an administrator back to `user`
- **THEN** subsequent authorization checks reject that account from administrator routes

#### Scenario: Application receives promotion input
- **WHEN** application configuration, a release invocation, or an HTTP request supplies an account email or requested administrator role
- **THEN** no role assignment occurs
