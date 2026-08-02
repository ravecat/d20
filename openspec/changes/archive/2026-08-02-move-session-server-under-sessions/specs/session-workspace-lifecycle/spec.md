## MODIFIED Requirements

### Requirement: Session and Presence publications respect their ownership boundaries

`D20.Sessions.Server` SHALL publish accepted Session transitions to SessionChannel and SHALL delegate Workspace invalidation for phase, membership, attach, and detach changes to `D20Web.Workspace`. `D20Web.Presence` SHALL continue to publish only normalized online and offline messages and SHALL NOT own attachment mutations.

#### Scenario: Accepted phase transition changes Workspace eligibility

- **WHEN** an accepted Session transition changes eligible phase or retained member ids
- **THEN** the Session server publishes the updated Session to the SessionChannel topic
- **AND** `D20Web.Workspace` publishes actor discovery invalidation for affected member ids
- **AND** joined SessionChannel processes receive the update through their existing Phoenix subscription

#### Scenario: Presence status changes

- **WHEN** Presence reports an actor meta join or final-meta leave
- **THEN** `D20Web.Presence` publishes the normalized `online` or `offline` message to its private topic
- **AND** the Session runtime receives the message through `D20Web.Presence.subscribe/1`
- **AND** Presence does not call `D20.Sessions` or WorkspaceChannel

#### Scenario: Presence status changes only

- **WHEN** an attached member changes between online and offline
- **THEN** SessionChannel subscribers receive the updated projection
- **AND** actor Workspace discovery is not invalidated

#### Scenario: Attachment changes

- **WHEN** a Session process creates or removes an actor attachment
- **THEN** `D20Web.Workspace` invalidates discovery for that actor
- **AND** Presence does not publish or mutate the attachment
