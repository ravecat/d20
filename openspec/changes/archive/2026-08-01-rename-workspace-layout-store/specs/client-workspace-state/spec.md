## MODIFIED Requirements

### Requirement: Workspace exposes one composed read-only store

The client workspace SHALL compose authoritative session values and browser-local presentation state into the existing `WorkspaceStore` contract without exposing direct state mutation. `WorkspaceState.layout` SHALL include both the current mode and its selected session identifier, and the store SHALL NOT expose a separate expanded-session field. The local `@xstate/store` instance that owns the flat `WorkspaceLayout` context SHALL be named `layout` so it is distinct from the composed workspace store.

#### Scenario: Consumer subscribes to workspace state

- **WHEN** either the server snapshot or local presentation state changes
- **THEN** the subscriber receives a `WorkspaceState` containing the current transport status, authoritative sessions, and layout
- **AND** the subscriber can read the selected session directly from `WorkspaceState.layout.id`

#### Scenario: Workspace model updates local layout

- **WHEN** the workspace model reads, subscribes to, focuses, or compacts browser-local layout state
- **THEN** it performs that operation through the local `layout` store binding

#### Scenario: Last consumer unsubscribes from the workspace

- **WHEN** Svelte removes the workspace component's final store subscription
- **THEN** the derived store releases its Phoenix session and local store subscriptions
- **AND** the Phoenix session leaves its active workspace channel
- **AND** the workspace model does not retain a separate disposed lifecycle state or expose a manual disposal method
