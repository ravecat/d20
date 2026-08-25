## RENAMED Requirements

- FROM: `Client refactor preserves external contracts`
- TO: `Client workspace consumes the id-based external contract`

## MODIFIED Requirements

### Requirement: Client workspace consumes the id-based external contract
The client workspace SHALL preserve the workspace topic, join and snapshot envelopes, focus, compact and close operations, and embedded iframe lifecycle while consuming string `gameId` values containing canonical `game` TypeIDs instead of slug in every authoritative descriptor. It SHALL NOT expose close progress or errors as presentation state.

#### Scenario: Existing workspace consumer uses the revised store
- **WHEN** a consumer subscribes, focuses, compacts, or closes through `WorkspaceStore`
- **THEN** the corresponding store or transport operation occurs without client-owned close lifecycle state

#### Scenario: Player requests a Session close
- **WHEN** the player closes a Session present in the authoritative snapshot
- **THEN** the workspace forwards the existing close operation and keeps it visible until an authoritative snapshot removes it

#### Scenario: Internal controls dispatch Session commands
- **WHEN** a workspace control dispatches focus or close using its rendered descriptor
- **THEN** it forwards the command without rescanning the authoritative Session collection
- **AND** Session-local presentation still uses Session `id`
- **AND** local game association is read from `gameId` without deriving or normalizing slug
- **AND** Session state shape remains derived from the `phoenix-session` generic

#### Scenario: Focused tests substitute transport dependencies
- **WHEN** focused model, component, or browser tests require controlled Workspace snapshots
- **THEN** they substitute `phoenix-session` at the test module boundary
- **AND** `createWorkspace()` exposes no dependency options or test-only Session types
- **AND** component behavior is driven through semantic Session controls

### Requirement: Workspace connection feedback remains generic
The client workspace SHALL render transport connection feedback inline without deriving game display names from local game ids or runtime slugs.

#### Scenario: Workspace is connecting
- **WHEN** Workspace status is neither ready, stale, nor failed
- **THEN** each visible status overlay displays `Connecting to game`

#### Scenario: Workspace is reconnecting
- **WHEN** Workspace status is stale
- **THEN** each visible status overlay displays `Reconnecting to game`

#### Scenario: Workspace connection failed
- **WHEN** Workspace status is failed
- **THEN** each visible status overlay displays `Connection to game failed`
