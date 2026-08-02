## MODIFIED Requirements

### Requirement: Session publication precedes workspace invalidation

`D20.Sessions.Server` SHALL publish a changed Session projection before delegating Workspace invalidation. Attachment-only changes MAY invalidate Workspace without publishing an unchanged Session projection.

#### Scenario: Detach also changes member status

- **WHEN** detach changes an online retained member to offline
- **THEN** SessionChannel subscribers receive the updated Session first
- **AND** Workspace is then invalidated for the detached actor

#### Scenario: Attach changes only the Registry

- **WHEN** a successful SessionChannel join creates an attachment for an already retained actor
- **THEN** Workspace is invalidated for that actor
- **AND** no unchanged Session projection is published solely for attachment

#### Scenario: Accepted transition changes discovery

- **WHEN** an accepted Session transition changes phase or retained member ids
- **THEN** SessionChannel subscribers receive `{:session, session}` through the existing topic
- **AND** affected WorkspaceChannel processes receive actor invalidation through `D20Web.Workspace`

#### Scenario: Accepted transition does not change discovery

- **WHEN** an accepted Session transition changes only game state or existing member attributes
- **THEN** SessionChannel subscribers receive the updated Session
- **AND** Workspace discovery is not invalidated
