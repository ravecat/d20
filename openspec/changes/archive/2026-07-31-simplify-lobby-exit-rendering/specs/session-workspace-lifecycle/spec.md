## MODIFIED Requirements

### Requirement: Lobby transition does not retain a Presence lease
When Lobby observes that its Session is in progress or finished, it SHALL navigate to the canonical game detail URL while the current page session descriptor continues to own the Lobby branch. The navigation response SHALL remove that descriptor, allowing normal component cleanup to detach the Session store. Workspace discovery SHALL NOT wait for Presence overlap or a handoff flag.

#### Scenario: Waiting Session starts
- **WHEN** Lobby receives an in-progress projection
- **THEN** Lobby requests the canonical game detail URL
- **AND** the Lobby component remains mounted while that navigation is pending
- **AND** the response supplies no selected session and returns the game page to Play
- **AND** normal component cleanup detaches its SessionChannel
- **AND** Workspace mounts the reported in-progress iframe from durable membership
- **AND** no Session controller or Presence lease is transferred

#### Scenario: Selected Session is already finished
- **WHEN** Lobby receives a finished projection
- **THEN** it follows the same canonical navigation and response-owned cleanup lifecycle
