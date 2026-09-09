## MODIFIED Requirements

### Requirement: Game detail content uses a 40/60 activation layout
The system SHALL render the game detail content below the preview as a split layout on viewports that can support two columns. The left panel SHALL contain activation controls and the right panel SHALL contain the game description. The description panel SHALL size to its full content and participate in document scrolling without an independent vertical scroll area.

#### Scenario: Wide viewport renders split panels
- **WHEN** a user opens `/games/qwinto` on a viewport wide enough for the desktop detail layout
- **THEN** the content below the preview is arranged in two columns
- **AND** the activation panel uses 40 percent of the available content width
- **AND** the description panel uses 60 percent of the available content width

#### Scenario: Long description extends the game page
- **WHEN** the runtime game metadata includes a description longer than the available viewport height
- **THEN** the description panel expands to contain the complete description
- **AND** the user reaches its final text by scrolling the document
- **AND** the description panel has no independent vertical scroll area
- **AND** the activation panel remains beside the description in the desktop layout and scrolls with the document

#### Scenario: Split panels have no surrounding borders
- **WHEN** the activation and description panels render below the preview
- **THEN** neither panel draws a surrounding border

#### Scenario: Narrow viewport stacks panels
- **WHEN** a user opens the game detail page on a viewport too narrow for the desktop split
- **THEN** the description panel and activation panel stack in a single column
- **AND** text, controls, icons, and joined-player entries do not overlap
- **AND** the description retains its full content height within the document flow
