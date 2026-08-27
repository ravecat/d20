## MODIFIED Requirements

### Requirement: Google results normalize to minimal trusted identity data
The Google web adapter SHALL accept the subject extracted by the configured Ueberauth Google strategy without imposing another provider-format validation and SHALL use it as the opaque provider UID. Provider-independent identity persistence constraints remain authoritative when the subject is stored. For unknown-identity registration, a syntactically valid email whose transient Google `email_verified` value is true MAY be retained as an optional account-email candidate. Missing, malformed, or unverified email SHALL normalize to no candidate and MUST NOT block provider-only registration. A browser-submitted email MUST NOT override the verified Google candidate. The adapter MUST NOT pass Ueberauth structures into `D20.Accounts` or persist access tokens, refresh tokens, ID tokens, authorization codes, raw claims, email verification claims, names, or avatars.

#### Scenario: Valid Google result includes verified email
- **WHEN** the configured Google strategy returns a subject and valid verified email for an unknown identity
- **THEN** the adapter returns only provider `google`, the opaque subject, and the optional verified email candidate
- **AND** the adapter does not impose an additional subject format check
- **AND** provider credentials and all unrelated claims are discarded

#### Scenario: Registration submits another email
- **WHEN** the browser submits a different email while completing registration from a valid Google proof
- **THEN** the browser-submitted email is ignored
- **AND** only an unowned valid verified Google candidate may be stored

#### Scenario: Linked identity has changed email data
- **WHEN** Google returns the exact subject of an existing identity with a missing or changed email
- **THEN** the system resolves the existing D20 user by the stored Google subject
- **AND** it does not replace the D20 account email from the callback

#### Scenario: Unknown identity lacks a verified email
- **WHEN** an unknown valid Google subject has a missing, malformed, or unverified email
- **THEN** the adapter retains the provider UID with no email candidate
- **AND** provider-only registration completion may start

### Requirement: Unknown Google identity completes registration atomically
An unknown valid Google identity SHALL require the guest to choose a valid unique D20 username through the provider-neutral registration-completion page shared with Magic Link and future providers. The completion proof SHALL contain no provider credential, SHALL contain at most the subject and optional verified email candidate required by the server transaction, SHALL expire after at most 10 minutes, MUST NOT appear in a URL or log, and SHALL be cleared after success or a terminal failure. The Google subject and provider details MUST remain inside the authenticated session-bound proof and MUST NOT be exposed through shared-page props or form fields. The system SHALL create the completed user with the username and an unowned valid verified email when available, otherwise null email, and link the Google subject in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL authenticate the new user through the existing D20 session boundary.

#### Scenario: Guest completes Google registration with unused verified email
- **WHEN** a guest with a valid unknown Google subject and unused verified email submits a valid unique username before completion expiry
- **THEN** exactly one completed D20 user is created with that email and username
- **AND** exactly one Google identity for that subject is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary
- **AND** the completion state is cleared

#### Scenario: Guest completes Google registration without verified email
- **WHEN** a guest with a valid unknown Google subject and no acceptable email candidate submits a valid unique username before completion expiry
- **THEN** exactly one completed D20 user is created with null email and that username
- **AND** exactly one Google identity for that subject is linked to the new user
- **AND** the guest is authenticated

#### Scenario: Username validation fails
- **WHEN** the guest submits an invalid or already-used username with otherwise valid unexpired completion state
- **THEN** no user or identity is created
- **AND** the shared provider-neutral completion page reports the username error
- **AND** the guest can submit another username before expiry

#### Scenario: Completion state expires or changes session
- **WHEN** a registration completion proof is expired, malformed, missing, or not bound to the current browser session
- **THEN** no user or identity is created
- **AND** the proof cannot authenticate the caller
- **AND** the player receives a safe retry or local registration action

#### Scenario: Concurrent completions race
- **WHEN** equivalent Google registration completions race for the same username, Google subject, or optional email
- **THEN** database constraints allow at most one owner for each username, non-null email, and Google subject
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Google email never silently merges accounts
The system MUST NOT use a matching Google email as proof that an unknown Google subject owns an existing D20 account. When the verified Google email already belongs to a D20 user, the callback SHALL NOT authenticate or link that user. After valid username completion, it MAY create a distinct account with null email and atomically link the unknown Google subject. Guidance SHALL explain that linking Google to the existing account requires authenticating that account and explicitly linking from Account Settings.

#### Scenario: Unknown Google subject matches an existing email
- **WHEN** an unknown Google subject returns a verified email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Google subject is not linked to the existing user
- **AND** the player may complete a distinct Google-backed account with null email
- **AND** explicit linking to the existing account still requires authenticating that account first
