## MODIFIED Requirements

### Requirement: Presentation state changes through local events

The client workspace SHALL keep focus and compact layout intent in browser-local state updated through typed events and SHALL expose only the effective expanded session identifier to presentation consumers.

#### Scenario: Player focuses a visible session

- **WHEN** the player focuses a session present in the authoritative workspace snapshot
- **THEN** the model retains that session identifier as focused layout intent
- **AND** `WorkspaceState.expandedId` identifies that session
- **AND** the workspace component presents it expanded above every other game window

#### Scenario: Player compacts the Theater session

- **WHEN** the player activates the Compact control for the session currently presented in Theater mode
- **THEN** the workspace invokes its target-free compact operation
- **AND** `WorkspaceState.expandedId` is undefined
- **AND** every workspace session is presented in Compact mode

### Requirement: Workspace exposes one composed read-only store

The client workspace SHALL compose authoritative session values and browser-local presentation intent into the existing `WorkspaceStore` contract without exposing direct state mutation or its raw layout representation.

#### Scenario: Consumer subscribes to workspace state

- **WHEN** either the server snapshot or local presentation state changes
- **THEN** the subscriber receives a `WorkspaceState` containing the current transport status, authoritative sessions, and effective expanded session identifier
- **AND** the subscriber does not need to reconcile layout intent with session membership

#### Scenario: Last consumer unsubscribes from the workspace

- **WHEN** Svelte removes the workspace component's final store subscription
- **THEN** the derived store releases its Phoenix session and local store subscriptions
- **AND** the Phoenix session leaves its active workspace channel
- **AND** the workspace model does not retain a separate disposed lifecycle state or expose a manual disposal method

### Requirement: Workspace component owns window arrangement

The client workspace SHALL realize the global window arrangement at the workspace list boundary using the effective expanded session identifier published by `WorkspaceStore`, rather than storing an effective mode on each session or reconciling raw layout intent inside the component.

#### Scenario: Workspace opens with sessions

- **WHEN** the authoritative snapshot contains one or more sessions and private layout intent is `auto`
- **THEN** the store publishes the first session identifier as `expandedId`
- **AND** the component expands that session above the remaining compact sessions

#### Scenario: Player selects another session

- **WHEN** the player compacts the Theater window and expands a different session from the restored grid
- **THEN** the store publishes the selected session identifier as `expandedId`
- **AND** the newly expanded Theater window is stacked above every other game window

#### Scenario: Workspace is fully compact

- **WHEN** private layout intent is `compact`
- **THEN** the store publishes an undefined `expandedId`
- **AND** every session remains in the compact workspace grid

#### Scenario: Focused session disappears

- **WHEN** private layout intent references a session absent from the latest authoritative snapshot
- **THEN** the store publishes the first remaining session identifier as `expandedId`
- **AND** it does not store that fallback as replacement focused layout intent

#### Scenario: Focused session reappears

- **WHEN** a previously absent focused session returns in an authoritative snapshot
- **THEN** the store publishes the retained focused session identifier as `expandedId`

#### Scenario: Window uses browser fullscreen

- **WHEN** the player toggles fullscreen for a game window
- **THEN** fullscreen remains local to that window and does not change the store's browser-local layout intent

#### Scenario: Workspace renders window controls

- **WHEN** the workspace renders a session window
- **THEN** the workspace owns the Compact restore surface and the complete named window-control group
- **AND** the dialog receives no global layout state or layout callbacks
- **AND** the dialog exposes synchronized fullscreen state and a toggle action without owning control markup
