## MODIFIED Requirements

### Requirement: Browser-derived production build
The Vite 8 production build SHALL derive its JavaScript target from the shared Browserslist policy. Development and production CSS transformation SHALL use LightningCSS targets derived from the same policy and SHALL explicitly lower CSS nesting while preserving the existing theme cascade and production entry records.

#### Scenario: Build with the shared policy
- **WHEN** a developer runs `mix assets.build`
- **THEN** Vite 8 lowers and minifies JavaScript for the resolved browser targets
- **AND** LightningCSS transforms and minifies CSS for its target representation of the same Browserslist policy
- **AND** CSS nesting is lowered without introducing an independent supported-browser query
- **AND** the production manifest retains the existing application entry records

#### Scenario: Serve CSS during development
- **WHEN** the Vite development server serves application CSS
- **THEN** LightningCSS uses the same browser-policy-derived targets and explicit nesting transformation
- **AND** the authored light and dark theme values, selection semantics, and existing hot-reload behavior remain intact
