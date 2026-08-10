## ADDED Requirements

### Requirement: Behavior-focused frontend tests

Frontend unit, component, integration, and browser tests SHALL prioritize application logic and user-observable behavior such as content, accessibility semantics, state transitions, permissions, focus, enabled state, and interaction outcomes. Frontend test sources MUST NOT directly read computed styles, element rectangles, or element width and height dimension properties to assert visual presentation. The frontend lint command SHALL enforce this test boundary without restricting production source code.

#### Scenario: Verify application behavior

- **WHEN** a frontend test covers an authentication, application shell, game launch, or workspace workflow
- **THEN** it asserts the relevant content, semantic state, focus, permission, or interaction outcome without reading computed styles or element geometry

#### Scenario: Reject computed-style presentation assertions

- **WHEN** a frontend test source directly calls `getComputedStyle`
- **THEN** the frontend lint command returns a non-zero status with a diagnostic for the restricted global

#### Scenario: Reject geometry presentation assertions

- **WHEN** a frontend test source directly calls an element rectangle method or reads an element width or height dimension property
- **THEN** the frontend lint command returns a non-zero status with a diagnostic for the restricted property

#### Scenario: Preserve production measurement APIs

- **WHEN** production frontend code requires a browser measurement API to implement application behavior
- **THEN** the test-scoped lint restriction does not reject that production source solely for using the measurement API
