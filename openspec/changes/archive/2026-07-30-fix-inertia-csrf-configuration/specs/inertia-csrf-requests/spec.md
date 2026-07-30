## ADDED Requirements

### Requirement: Inertia requests use the current CSRF cookie

The client SHALL obtain the CSRF token from the current `XSRF-TOKEN` cookie when each Inertia request is sent and SHALL submit it through the `x-csrf-token` header expected by Phoenix.

#### Scenario: Request after CSRF cookie renewal

- **WHEN** a long-lived or restored page submits an Inertia request after its `XSRF-TOKEN` cookie has changed
- **THEN** the request uses the cookie's current token rather than the token embedded in the initial HTML document

#### Scenario: Request during the original page lifetime

- **WHEN** a page submits an Inertia request without a CSRF cookie change
- **THEN** the request sends the current cookie token through `x-csrf-token`

### Requirement: Missing CSRF state remains protected

The client SHALL NOT cache, fabricate, or reuse an initial document token as a fallback when the current `XSRF-TOKEN` cookie is unavailable.

#### Scenario: Request without the CSRF cookie

- **WHEN** an Inertia state-changing request is attempted without an `XSRF-TOKEN` cookie
- **THEN** the client does not add a stale fallback token and Phoenix remains responsible for rejecting the unverified request

### Requirement: Non-Inertia transports remain compatible

The client SHALL preserve the existing initial-document CSRF bootstrap used by LiveSocket while changing how Inertia HTTP requests obtain their token.

#### Scenario: Application bootstrap

- **WHEN** the application initializes LiveSocket and Inertia
- **THEN** LiveSocket receives the initial meta token and Inertia independently reads its request token from the current cookie
