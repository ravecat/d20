## ADDED Requirements

### Requirement: Page catalog distinguishes public and authenticated surfaces

The Storybook catalog SHALL organize complete routed page stories under `Pages/Public` or `Pages/Authenticated` according to the authentication state required to display each scenario. A complete page metadata group MUST NOT mix public and authenticated scenarios. Shared component and widget stories SHALL remain outside this page access hierarchy.

#### Scenario: Browse public pages

- **WHEN** a contributor expands `Pages/Public`
- **THEN** Home's anonymous catalog, sign-in, sign-up, and email-completion scenarios are available under `/`
- **AND** signed-out Magic Link confirmation is available under `/users/log-in/:token`
- **AND** registration completion is available under `/users/register/complete`
- **AND** Account Settings and reauthentication scenarios are absent

#### Scenario: Browse authenticated pages

- **WHEN** a contributor expands `Pages/Authenticated`
- **THEN** Account Settings is available under `/settings`
- **AND** Home's email-backed confirmation scenario is available under `/`
- **AND** tokenized reauthentication is available under `/users/log-in/:token`
- **AND** sign-in, sign-up, signed-out confirmation, and registration completion scenarios are absent

#### Scenario: Browse non-page stories

- **WHEN** a contributor opens a shared component or widget story
- **THEN** its existing catalog hierarchy remains unchanged
- **AND** it is not duplicated under `Public` or `Authenticated`
