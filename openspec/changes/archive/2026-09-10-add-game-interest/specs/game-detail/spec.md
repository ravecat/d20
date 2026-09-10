## MODIFIED Requirements

### Requirement: Provider-only detail pages have no local runtime identity
A resolved provider-only detail SHALL render the existing game page with `id: null`, a decimal BGG string as `slug`, `stage: null`, `playable: false`, resolved `game` Metadata, `schema: null`, and `session: null`. It SHALL also expose the game-interest contract containing the original-route action URL, the current account's saved membership, and the resolved game's request count. The former `can_launch_game` / `canLaunchGame` prop SHALL be absent. Local detail IDs SHALL retain their TypeID meaning; catalog IDs SHALL retain their numeric BGG meaning. The page SHALL display metadata and `InterestForm` with its request action or saved state without `SessionForm`, Play control, local Session, or invented Game record.

#### Scenario: Provider-only detail props are serialized
- **WHEN** BGG confirms a game without a selected local detail record
- **THEN** the response contains its normalized numeric route slug and Metadata with null local identity, stage, schema, and Session
- **AND** playable is false and interest contains the original-route action, caller membership, and request count without a BGG ID field
- **AND** canLaunchGame is not serialized

#### Scenario: Provider-only detail is displayed
- **WHEN** the client receives provider-only detail props
- **THEN** metadata and description render through the existing detail layout
- **AND** the activation panel renders `InterestForm` with `I want this game!` or persisted saved state without Play, disabled Play, `SessionForm`, or Lobby

#### Scenario: Provider-only detail fails to resolve
- **WHEN** the provider omits the requested game or configuration, HTTP, transport, parse, or Metadata validation fails
- **THEN** the context returns the error and the controller returns its existing 404 response
- **AND** the system does not invent a successful empty detail page or persist a Game
