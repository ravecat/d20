# workspace-compact-theme-contrast Specification

## Purpose
TBD - created by archiving change fix-compact-workspace-dark-theme-contrast. Update Purpose after archive.
## Requirements
### Requirement: Theme-independent Compact workspace readability
The workspace SHALL render Compact session status, session identifiers, and window controls with contrasting foreground and background roles derived from the active theme tokens.

#### Scenario: Light theme Compact presentation
- **WHEN** the active theme provides a light base surface and dark base content
- **THEN** each Compact workspace window presents readable status, session identifier, and window controls against its inverse surface

#### Scenario: Dark theme Compact presentation
- **WHEN** the active theme provides a dark base surface and light base content
- **THEN** each Compact workspace window presents readable status, session identifier, and window controls against its inverse surface

### Requirement: Non-Compact presentation remains stable
The workspace MUST preserve existing Theater and fullscreen presentation and behavior when correcting Compact theme contrast.

#### Scenario: Expand a corrected Compact window
- **WHEN** a player expands a Compact window or enters browser fullscreen
- **THEN** the game surface, window controls, focus behavior, and iframe instance continue to follow the existing workspace behavior
