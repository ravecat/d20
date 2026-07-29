## ADDED Requirements

### Requirement: Workspace snapshots publish authoritative session phase

Every discoverable workspace session descriptor SHALL include the authoritative session phase as either `in_progress` or `finished`.

#### Scenario: Actor joins with an in-progress session

- **WHEN** an actor joins the workspace while a current-member session is in progress
- **THEN** the returned descriptor includes `phase: in_progress`

#### Scenario: Session finishes while workspace is connected

- **WHEN** a discoverable session transitions from in progress to finished
- **THEN** the next complete workspace snapshot retains the descriptor
- **AND** the descriptor includes `phase: finished`

#### Scenario: Actor joins with a finished session

- **WHEN** an actor joins the workspace while a current-member session is finished
- **THEN** the returned descriptor includes `phase: finished`

### Requirement: Compact sessions expose four meaningful statuses

The workspace SHALL derive each compact session's visible status from the shared workspace transport and authoritative session phase, with transport degradation taking precedence over phase.
The status MUST remain visible as uppercase text inside an outlined badge, and color or motion MUST remain supplemental.

#### Scenario: Connected in-progress session

- **WHEN** the workspace transport is ready and the session phase is `in_progress`
- **THEN** the compact bar visibly reports `Live`
- **AND** its dot is green and uses a 1.2-second opacity pulse unless the player prefers reduced motion

#### Scenario: Connected finished session

- **WHEN** the workspace transport is ready and the session phase is `finished`
- **THEN** the compact bar visibly reports `Finished`
- **AND** the Finished badge remains neutral gray
- **AND** its dot remains neutral and static

#### Scenario: Workspace transport is temporarily unavailable

- **WHEN** the workspace retains sessions while its transport is stale or otherwise reconnecting
- **THEN** every compact bar visibly reports `Reconnecting`
- **AND** the Reconnecting badge uses the warning color
- **AND** its dot uses the warning color with a 0.8-second opacity pulse unless the player prefers reduced motion
- **AND** neither Live nor Finished overrides that transport state

#### Scenario: Workspace recovery fails

- **WHEN** workspace transport recovery enters the failed state
- **THEN** every retained compact bar visibly reports `Failed`
- **AND** the Failed badge remains neutral gray
- **AND** its dot uses the error color and remains static
- **AND** neither Live nor Finished overrides that transport state

### Requirement: Workspace layout starts Compact

Each newly mounted workspace instance SHALL keep every discovered session Compact until the player explicitly activates Expand. Browser-local layout state MUST NOT infer Theater selection from session membership or synchronize presentation state across tabs or devices.

#### Scenario: Initial snapshot contains sessions

- **WHEN** a newly mounted workspace receives its first complete snapshot with one or more sessions
- **THEN** every session renders as a Compact status bar
- **AND** no session covers the surrounding site as a Theater window

#### Scenario: Snapshot adds a session before layout selection

- **WHEN** a mounted Compact workspace receives a replacement snapshot containing a newly discoverable session
- **THEN** every session remains Compact
- **AND** the snapshot does not select a Theater window

#### Scenario: Player explicitly expands a session

- **WHEN** the player activates Expand on a Compact status bar
- **THEN** that session becomes the Theater window

#### Scenario: Workspace mounts again

- **WHEN** the workspace component is unmounted and a new instance mounts for the same actor
- **THEN** the new instance starts Compact independently of the previous instance's layout selection

### Requirement: Compact mode renders a status bar instead of a game preview

Each non-expanded workspace session SHALL render as a centered 4rem compact status bar and SHALL NOT present its embedded game as an interactive preview. Its status badge and controls SHALL each have a 1.5rem block size, and every window-control SVG SHALL render as a 0.75rem square.

#### Scenario: Session becomes compact

- **WHEN** the player compacts an expanded session
- **THEN** the session dialog presents its session identity and visible status text
- **AND** its computed block size is 4rem
- **AND** its status badge and controls each have a computed block size of 1.5rem
- **AND** its status, identifier, and controls are centered on the bar's block axis
- **AND** its status, identifier, and controls participate in one flex row with equal gaps around the flexible identifier lane
- **AND** its controls do not use absolute positioning while Compact
- **AND** its named control group visually presents Expand first, Enter fullscreen second, and Close last in horizontal order
- **AND** its DOM order remains Close, Enter fullscreen, and Expand
- **AND** Expand uses an unfilled outline-square icon
- **AND** every window-control SVG uses the same 0.75rem square rendered size

#### Scenario: Session expands again

- **WHEN** the player activates Expand from a compact bar
- **THEN** that session becomes the Theater window
- **AND** its named control group visually presents Close first, Compact second, and Enter fullscreen last in top-to-bottom order
- **AND** its DOM order remains Close, Enter fullscreen, and Compact
- **AND** its controls use absolute positioning over the Theater game surface
- **AND** the Compact control uses a lower horizontal line as its visible icon
- **AND** every window-control SVG uses the same 0.75rem square rendered size

#### Scenario: Compact session enters fullscreen

- **WHEN** the player activates Enter fullscreen from a compact bar
- **THEN** the same mounted game surface becomes visible and interactive in browser fullscreen
- **AND** the fullscreen controls contain Close and Exit fullscreen
- **AND** exiting fullscreen restores the same Compact status bar without changing the saved workspace layout

### Requirement: Compact session identifiers reveal overflow

The workspace SHALL keep the full session identifier in accessible text and SHALL move it smoothly back and forth only when its rendered text exceeds the available identifier lane.

#### Scenario: Session identifier overflows

- **WHEN** a Compact session identifier is wider than its available lane
- **THEN** the visual text moves between the lane's logical start and end without leaving the lane
- **AND** each animation iteration lasts approximately 5.833 seconds, making the motion 20% faster than its original 7-second iteration
- **AND** resizing the lane recalculates the exact travel distance

#### Scenario: Session identifier fits

- **WHEN** a Compact session identifier fits within its available lane
- **THEN** the identifier remains static

#### Scenario: Player prefers reduced motion

- **WHEN** `prefers-reduced-motion: reduce` matches
- **THEN** the identifier and every status dot remain static
- **AND** the complete identifier remains available to assistive technology

### Requirement: Compact mode preserves runtime while hiding game interaction

Changing a session between Theater, Compact, and browser-fullscreen presentation MUST preserve its iframe node and SDK bridge while game content remains unavailable visually, by pointer, by keyboard, and to assistive technology only when Compact is active outside fullscreen.

#### Scenario: Expanded session is compacted and restored

- **WHEN** a player compacts and then expands a session
- **THEN** the same iframe node and SDK bridge remain mounted throughout both transitions
- **AND** the compact game surface is not visible
- **AND** the compact game surface cannot receive pointer or keyboard interaction
- **AND** the compact game surface is absent from the accessibility tree

#### Scenario: Compact session enters and exits fullscreen

- **WHEN** a player enters and exits fullscreen from Compact
- **THEN** the same iframe node and SDK bridge remain mounted throughout both transitions
- **AND** game content is available while fullscreen is active
- **AND** game content becomes hidden and inert again after fullscreen exits

### Requirement: Compact bars remain reachable in supported viewports

The workspace SHALL stack compact status bars in a viewport-bounded single column without causing document-level horizontal overflow.

#### Scenario: Multiple sessions are compact on a narrow viewport

- **WHEN** multiple sessions are compact on a supported narrow viewport
- **THEN** every compact bar remains within the logical viewport edges
- **AND** adjacent compact bars are separated by a 0.375rem gap
- **AND** compact surfaces cast no shadow into that gap
- **AND** every Expand, Enter fullscreen, and Close control is reachable
- **AND** overflow within the stack can be scrolled without adding document-level horizontal overflow

#### Scenario: Theater window coexists with compact sessions

- **WHEN** one session is expanded and other sessions are compact
- **THEN** the Theater window remains above the compact stack
- **AND** every compact status bar remains available for selecting another session
