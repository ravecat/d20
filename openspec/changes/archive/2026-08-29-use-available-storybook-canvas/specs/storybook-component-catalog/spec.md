## MODIFIED Requirements

### Requirement: Catalog inspection tooling

The catalog SHALL provide generated documentation, controls, viewport selection, and accessibility inspection for discovered stories while preserving a path to add Storybook browser-backed interaction tests separately. The interactive catalog SHALL use the complete available canvas by default until a contributor explicitly selects a named viewport.

#### Scenario: Open the catalog without selecting a viewport

- **WHEN** a contributor opens Storybook without a viewport selection
- **THEN** the preview uses the complete available canvas
- **AND** no Desktop, Tablet landscape, or Mobile viewport is emulated

#### Scenario: Inspect the smoke story

- **WHEN** a contributor opens the baseline story in Storybook
- **THEN** they can inspect its generated documentation and editable controls
- **AND** they can explicitly select a narrow viewport and run the configured accessibility inspection
