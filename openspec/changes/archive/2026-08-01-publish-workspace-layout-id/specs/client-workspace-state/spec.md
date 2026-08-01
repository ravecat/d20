## MODIFIED Requirements

### Requirement: Presentation state changes through local events

The client workspace SHALL keep focus and compact layout in browser-local state updated through typed events and SHALL expose the current mode and selected session identifier together as `WorkspaceState.layout`.

#### Scenario: Player focuses a visible session

- **WHEN** the player focuses a session present in the authoritative workspace snapshot
- **THEN** `WorkspaceState.layout` has mode `focused` and its `id` is exactly that session identifier
- **AND** the workspace component presents it expanded above every other game window

#### Scenario: Player compacts the Theater session

- **WHEN** the player activates the Compact control for the session currently presented in Theater mode
- **THEN** the workspace invokes its target-free compact operation
- **AND** `WorkspaceState.layout` has mode `compact` and an undefined `id`
- **AND** every workspace session is presented in Compact mode

### Requirement: Workspace exposes one composed read-only store

The client workspace SHALL compose authoritative session values and browser-local presentation state into the existing `WorkspaceStore` contract without exposing direct state mutation. `WorkspaceState.layout` SHALL include both the current mode and its selected session identifier, and the store SHALL NOT expose a separate expanded-session field.

#### Scenario: Consumer subscribes to workspace state

- **WHEN** either the server snapshot or local presentation state changes
- **THEN** the subscriber receives a `WorkspaceState` containing the current transport status, authoritative sessions, and layout
- **AND** the subscriber can read the selected session directly from `WorkspaceState.layout.id`

#### Scenario: Last consumer unsubscribes from the workspace

- **WHEN** Svelte removes the workspace component's final store subscription
- **THEN** the derived store releases its Phoenix session and local store subscriptions
- **AND** the Phoenix session leaves its active workspace channel
- **AND** the workspace model does not retain a separate disposed lifecycle state or expose a manual disposal method

### Requirement: Workspace component owns window arrangement

The client workspace SHALL realize the global window arrangement at the workspace list boundary by comparing each authoritative session identifier directly with `$workspace.layout.id`, rather than storing an effective mode on each session or using a separate expanded-session value.

#### Scenario: Workspace opens with sessions

- **WHEN** the authoritative snapshot contains one or more sessions and layout mode is `auto`
- **THEN** the composed layout `id` is the first authoritative session identifier
- **AND** the component expands that session above the remaining compact sessions

#### Scenario: Auto workspace receives a replacement snapshot

- **WHEN** an Auto workspace receives a replacement authoritative snapshot
- **THEN** the composed layout `id` follows the first session in that snapshot

#### Scenario: Player selects another session

- **WHEN** the player compacts the Theater window and expands a different session from the restored grid
- **THEN** layout mode becomes `focused` and its `id` is exactly the selected session identifier
- **AND** the newly expanded Theater window is stacked above every other game window

#### Scenario: Workspace is fully compact

- **WHEN** layout mode is `compact`
- **THEN** layout `id` is undefined
- **AND** every session remains in the compact workspace grid

#### Scenario: Focused session disappears

- **WHEN** focused layout references a session absent from the latest authoritative snapshot
- **THEN** layout retains the exact focused `id`
- **AND** no remaining session is substituted or expanded

#### Scenario: Focused session reappears

- **WHEN** a previously absent focused session returns in an authoritative snapshot
- **THEN** its identifier still matches layout `id`
- **AND** the component expands that session again

#### Scenario: Window uses browser fullscreen

- **WHEN** the player toggles fullscreen for a game window
- **THEN** fullscreen remains local to that window and does not change the global workspace layout

#### Scenario: Workspace renders window controls

- **WHEN** the workspace renders a session window
- **THEN** the workspace owns the Compact restore surface and the complete named window-control group
- **AND** the dialog receives no global layout state or layout callbacks
- **AND** the dialog exposes synchronized fullscreen state and a toggle action without owning control markup
