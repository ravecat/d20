## RENAMED Requirements

- FROM: `Catalog tile opens game detail page`
- TO: `Catalog tile opens id-based game detail page`
- FROM: `Game detail page resolves registered games`
- TO: `Game detail page resolves persisted games by id`

## MODIFIED Requirements

### Requirement: Catalog tile opens id-based game detail page
The system SHALL allow users to open a persisted game's detail page only through the local game id route `/games/:game_id`.

#### Scenario: Tile click uses only local id
- **WHEN** the user activates the Qwinto tile for its persisted `game` TypeID
- **THEN** the system navigates to `/games/:game_id` using that full TypeID
- **AND** no presentation slug is appended

#### Scenario: Tile target does not use BGG id
- **WHEN** a Qwinto `game` TypeID has BGG id `183006`
- **THEN** its tile route is based on the TypeID, not `183006`

#### Scenario: Tile has no runtime metadata
- **WHEN** Qwinto metadata is unavailable
- **THEN** the tile still navigates through its full `game` TypeID

### Requirement: Game detail page resolves persisted games by id
The system SHALL resolve only `GET /games/:game_id` by canonical `game` TypeID. The detail Inertia props SHALL expose that identity as string `id` and the current implementation stage as `stage` without a public slug field.

#### Scenario: Persisted detail is found
- **WHEN** the user opens a detail route for Qwinto's persisted `game` TypeID
- **THEN** the system loads persisted Qwinto by id
- **AND** renders the game detail page

#### Scenario: Unknown valid detail is not found
- **WHEN** the user opens a route for a well-formed `game` TypeID absent from persistence
- **THEN** the system returns not found

#### Scenario: Malformed or wrong-prefix detail id is a bad request
- **WHEN** the user opens a route with a malformed TypeID or a valid TypeID whose prefix is not `game`
- **THEN** TypeID/Ecto casting and Phoenix.Ecto exception mapping return `400 Bad Request`

### Requirement: Game detail page uses runtime metadata
The system SHALL use runtime metadata for game detail presentation fields when metadata is available without deriving or canonicalizing a public game slug.

#### Scenario: Detail page renders runtime title
- **WHEN** a persisted `game` TypeID resolves runtime title `Qwinto`
- **THEN** the detail page presents `Qwinto`

#### Scenario: Detail page renders runtime preview image
- **WHEN** runtime metadata includes a preview image URL
- **THEN** the detail page presents that image as the game preview

#### Scenario: Detail page renders runtime description
- **WHEN** runtime metadata includes a description
- **THEN** the detail page presents that description

#### Scenario: Removed slug variant is requested
- **WHEN** a client appends `/qwinto` after a valid `/games/:game_id` TypeID route
- **THEN** no game detail route matches that slug variant

#### Scenario: Runtime name is unavailable
- **WHEN** a persisted `game` TypeID has no usable runtime name
- **THEN** `/games/:game_id` using that TypeID remains the only detail URL
