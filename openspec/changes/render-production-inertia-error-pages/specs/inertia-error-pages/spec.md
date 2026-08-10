## ADDED Requirements

### Requirement: Production Inertia failures render an application error page

The system SHALL render a D20-owned Inertia error page when a production Inertia request ends with `403 Forbidden`, `404 Not Found`, `500 Internal Server Error`, or `503 Service Unavailable`. The response MUST preserve the selected HTTP status, MUST NOT redirect through a dedicated error URL, and MUST NOT open Inertia's diagnostic response dialog.

#### Scenario: Forbidden Inertia request

- **WHEN** a production Inertia request ends with `403 Forbidden`
- **THEN** the response retains status `403` and provides the D20 error page as a valid Inertia response
- **AND** the client does not open the diagnostic response dialog

#### Scenario: Missing Inertia page or route

- **WHEN** a production Inertia `GET` request ends with `404 Not Found`
- **THEN** the response retains status `404` and renders the D20 error page for the requested URL without a redirect

#### Scenario: Unexpected application failure

- **WHEN** an exception during a production Inertia request is rendered as `500 Internal Server Error`
- **THEN** the response retains status `500` and renders the D20 error page without exposing the raw Phoenix error body

#### Scenario: Temporary service failure

- **WHEN** a production Inertia request ends with `503 Service Unavailable`
- **THEN** the response retains status `503` and renders the D20 error page without a redirect

### Requirement: Error pages expose safe public failure information

The error page SHALL identify the supported status with fixed public copy and SHALL provide a safe recovery action. It MUST NOT expose exception messages, stack traces, submitted parameters, session state, game state, or other private implementation details. Unexpected server and service failures SHALL expose the existing request correlation identifier without deriving public content from the exception.

#### Scenario: Internal failure is presented

- **WHEN** the error page renders a `500` or `503` response
- **THEN** it shows status-appropriate public language and the request correlation identifier
- **AND** the identifier can be matched to the existing server request log
- **AND** no exception-derived detail is present in the page props or rendered content

#### Scenario: Access or location failure is presented

- **WHEN** the error page renders a `403` or `404` response
- **THEN** it explains the public outcome without revealing authorization rules or internal lookup details
- **AND** it provides a safe navigation action

#### Scenario: Mutating request fails

- **WHEN** a state-changing Inertia request renders the error page
- **THEN** the page does not automatically retry or resubmit the failed request
- **AND** browser history does not use the non-navigable mutation action as a dedicated error destination

### Requirement: Error pages remain accessible on supported devices

The error page SHALL provide a status-appropriate document title, one primary heading, programmatic focus placement after the Inertia page swap, keyboard-operable recovery, visible focus treatment, and a layout usable across the supported browser and viewport policy.

#### Scenario: Assistive technology receives an error page

- **WHEN** an Inertia failure swaps the current page for the D20 error page
- **THEN** focus moves to the error page heading or main region
- **AND** the document title and primary heading identify the failure
- **AND** the recovery action is keyboard operable with a visible focus indicator

#### Scenario: Error page renders on a narrow mobile viewport

- **WHEN** the D20 error page renders at a supported narrow viewport with safe-area insets
- **THEN** its message, request reference when present, and recovery action remain visible or reachable without horizontal scrolling

### Requirement: Existing error boundaries remain compatible

The enhanced error page boundary SHALL apply only to production Inertia requests for the supported statuses. Non-Inertia requests MUST retain conventional HTML error responses with their original status, expected validation and domain failures MUST retain their existing Inertia error-prop flows, and development MUST retain actionable framework diagnostics.

#### Scenario: Conventional browser request fails

- **WHEN** a request without the Inertia header ends with a supported error status
- **THEN** Phoenix returns the conventional HTML error response with the original status
- **AND** no Inertia page envelope is added

#### Scenario: Validation fails

- **WHEN** an expected form validation or controlled domain failure is represented through Inertia error props
- **THEN** the owning form or page presents that error through its existing flow
- **AND** the application error page is not rendered

#### Scenario: Development request raises

- **WHEN** an Inertia request raises while development diagnostics are enabled
- **THEN** the existing Phoenix and Inertia diagnostic response remains available to the developer
- **AND** the production-safe page does not replace its actionable details
