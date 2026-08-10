## MODIFIED Requirements

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
- **AND** each choice label uses the same font size as regular game-description text
- **AND** long choice labels wrap without causing horizontal overflow
