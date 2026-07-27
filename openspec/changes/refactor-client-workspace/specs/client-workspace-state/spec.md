## ADDED Requirements

### Requirement: Authoritative workspace state remains transport-owned

The client workspace SHALL use the current `phoenix-session` workspace value as the sole source of session membership, descriptors, connection status, and transport error state.

#### Scenario: Server publishes a workspace snapshot

- **WHEN** the workspace session receives a join value or snapshot event
- **THEN** `WorkspaceState.sessions` reflects that complete server value without client-side payload normalization or per-session presentation fields

### Requirement: Presentation state changes through local events

The client workspace SHALL keep focus and compact layout in browser-local state updated through typed events.

#### Scenario: Player focuses a visible session

- **WHEN** the player focuses a session present in the authoritative workspace snapshot
- **THEN** the global layout identifies that session and the workspace component presents it expanded above every other game window

#### Scenario: Player compacts the Theater session

- **WHEN** the player activates the Compact control for the session currently presented in Theater mode
- **THEN** every workspace session is presented in Compact mode

### Requirement: Workspace compaction uses an explicit control

The client workspace SHALL expose compaction through the Theater window control and SHALL NOT register a parent-window Escape handler for changing the workspace layout.

#### Scenario: Game iframe owns keyboard focus

- **WHEN** keyboard input is handled inside an embedded game document
- **THEN** the parent workspace does not depend on that input to compact the Theater window

#### Scenario: Player uses the Compact control

- **WHEN** the player activates the keyboard-reachable Compact control
- **THEN** the workspace changes to Compact layout

### Requirement: Workspace exposes one composed read-only store

The client workspace SHALL compose authoritative session values and browser-local presentation state into the existing `WorkspaceStore` contract without exposing direct state mutation.

#### Scenario: Consumer subscribes to workspace state

- **WHEN** either the server snapshot or local presentation state changes
- **THEN** the subscriber receives a `WorkspaceState` containing the current transport status, authoritative sessions, and global layout

#### Scenario: Consumer disposes the workspace

- **WHEN** the consumer calls `dispose`
- **THEN** the workspace detaches its Phoenix session and resets browser-local presentation state

### Requirement: Client refactor preserves external contracts

The client workspace refactor SHALL preserve the workspace channel topic, join and snapshot payloads, close operation, `WorkspaceStore` methods, and embedded iframe lifecycle. It SHALL NOT expose close progress or errors as workspace presentation state.

#### Scenario: Existing workspace consumer uses the refactored store

- **WHEN** an existing component subscribes, focuses, compacts, closes, or disposes through `WorkspaceStore`
- **THEN** the corresponding store or transport operation occurs without creating client-owned close lifecycle state

#### Scenario: Player requests a session close

- **WHEN** the player closes a session present in the authoritative workspace snapshot
- **THEN** the workspace forwards the existing close operation and keeps the session visible until an authoritative snapshot removes it

### Requirement: Workspace AsyncAPI remains internal

The application SHALL retain the Workspace AsyncAPI document for internal contract verification and SHALL NOT publish it through the developer catalog or public AsyncAPI endpoints.

#### Scenario: Developer catalog renders

- **WHEN** a visitor opens the public developer catalog
- **THEN** it lists public game specifications without a Workspace reference or raw contract link

#### Scenario: Visitor requests the Workspace contract

- **WHEN** a visitor requests either `/developers/specs/workspace` or `/developers/specs/workspace/raw`
- **THEN** the application responds with not found

#### Scenario: Internal contract verification runs

- **WHEN** repository validation loads the Workspace AsyncAPI document
- **THEN** the internal document remains available without requiring public HTTP access

### Requirement: Workspace component owns window arrangement

The client workspace SHALL realize the global layout at the workspace list boundary rather than storing an effective mode on each session or delegating spatial arrangement to individual game windows.

#### Scenario: Workspace opens with sessions

- **WHEN** the authoritative snapshot contains one or more sessions and layout is `auto`
- **THEN** the first session is expanded above the remaining compact sessions

#### Scenario: Player selects another session

- **WHEN** the player compacts the Theater window and expands a different session from the restored grid
- **THEN** the newly expanded Theater window is stacked above every other game window

#### Scenario: Workspace is fully compact

- **WHEN** layout is `compact`
- **THEN** every session remains in the compact workspace grid

#### Scenario: Focused session disappears

- **WHEN** layout references a session absent from the latest authoritative snapshot
- **THEN** the first remaining session is expanded without storing a replacement focused session identifier

#### Scenario: Window uses browser fullscreen

- **WHEN** the player toggles fullscreen for a game window
- **THEN** fullscreen remains local to that window and does not change the global workspace layout

### Requirement: Persistent workspace component owns workspace lifecycle

The client workspace SHALL use a persistent workspace component that renders application children and owns workspace store construction and disposal.

#### Scenario: Application layout renders

- **WHEN** the persistent application layout renders its page content
- **THEN** it wraps that content with the workspace component without creating or passing a workspace store

#### Scenario: Page content changes

- **WHEN** Inertia replaces the page content under the persistent application layout
- **THEN** the workspace component and its store remain mounted without recreating the workspace channel

#### Scenario: Persistent workspace unmounts

- **WHEN** the workspace component unmounts
- **THEN** it disposes its owned workspace store and detaches the workspace channel

### Requirement: Workspace implementation has one client ownership boundary

The client workspace SHALL be exposed as a Feature-Sliced Design widget whose model, workspace-specific types, and internal window UI are colocated behind the widget public API. The application layout SHALL compose that widget from the App layer.

#### Scenario: Application composes the workspace

- **WHEN** the application layout renders the persistent workspace
- **THEN** it imports the workspace component through the widget public API without importing widget internals

#### Scenario: Workspace implementation changes internally

- **WHEN** workspace model, transport types, or window UI are maintained
- **THEN** those modules remain inside the workspace slice and are not exported from transitional Shared store, type, or component segments

### Requirement: Pages own non-default layout presentation

The client application SHALL use one route-agnostic persistent default layout and SHALL let each page public API declare its non-default layout presentation metadata.

#### Scenario: Narrow page resolves

- **WHEN** a page public API exports the narrow layout variant
- **THEN** Inertia applies that variant to the persistent default layout without application bootstrap branching on the page name

#### Scenario: Default page resolves

- **WHEN** a page public API does not export layout presentation metadata
- **THEN** the persistent application layout uses its default variant

#### Scenario: Navigation changes the layout variant

- **WHEN** Inertia navigates between pages with different layout metadata
- **THEN** the layout presentation updates while the workspace component and its store remain mounted
