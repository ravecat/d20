## MODIFIED Requirements

### Requirement: Game creation forms use a JSON Schema transport
The system SHALL represent launchable game creation controls with JSON Schema generated from the game changeset at the game page boundary.

#### Scenario: Enum creation field is described
- **WHEN** a game changeset contains a supported `Ecto.Enum` field
- **THEN** the form schema describes the field with its dumped enum values
- **AND** SJSF renders the available values as native radio choices by default
- **AND** the field submits the selected typed enum value

#### Scenario: Boolean creation fields are described
- **WHEN** a game changeset contains supported boolean fields
- **THEN** the form schema describes those fields as booleans
- **AND** SJSF renders boolean controls that submit typed values

#### Scenario: Required fields are described
- **WHEN** a supported changeset field is present in the changeset required metadata
- **THEN** the form schema includes that property name in its required array
- **AND** SJSF applies the corresponding required constraint

### Requirement: Game creation forms integrate with the shell visual language
The client SHALL present SJSF-generated game creation controls with the shell's shared form styling while preserving their native semantics and accessible states.

#### Scenario: Launch form is ready for interaction
- **WHEN** SJSF renders a launchable game's creation form
- **THEN** the form initializes with a working ID builder and renders without a client error
- **AND** generated controls use the shell's theme colors, borders, typography, and focus treatment
- **AND** the primary submit action spans the available form width
- **AND** the primary submit action is labeled `Play`

#### Scenario: Launch form is displayed on a narrow viewport
- **WHEN** the game page is displayed on a supported narrow viewport
- **THEN** the generated form remains within the activation panel without horizontal overflow

#### Scenario: Multiple-choice controls adapt to available space
- **WHEN** SJSF renders a group of radio or checkbox choices
- **THEN** each choice occupies a separate full-width row
- **AND** each choice row uses the same minimum interaction height as the submit action
- **AND** long choice labels wrap without causing horizontal overflow
