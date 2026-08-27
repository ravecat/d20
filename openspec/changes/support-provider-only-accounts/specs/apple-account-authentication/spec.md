## MODIFIED Requirements

### Requirement: Apple transactions use short-lived encrypted browser state
The system SHALL bind each Apple request to its intent, a safe local return path, and the expected D20 user for linking in the attempt phase of one encrypted, authenticated, HTTP-only, Secure flow cookie. The attempt phase SHALL be usable by the cross-site POST callback, expire after at most 10 minutes, and be consumed by the callback. Unknown-identity registration SHALL replace it with a same-site registration phase in the same cookie containing only the normalized subject, optional acceptable provider-authenticated email candidate, and safe return path. Missing or unusable email MUST NOT prevent this registration phase. The registration state MUST never appear in a URL, browser-visible prop, or log and SHALL expire after at most 10 minutes. D20 SHALL rely on the framework token primitive for encryption, integrity, and age validation while Ueberauth remains responsible for provider state, nonce, ID-token, and authorization-code validation.

#### Scenario: Apple callback lacks a valid attempt
- **WHEN** the callback attempt cookie is missing, malformed, expired, or has an unexpected purpose or intent
- **THEN** no D20 user, identity, or authenticated session is created
- **AND** the player receives a safe local retry action

#### Scenario: Registration state carries no email candidate
- **WHEN** an unknown valid Apple subject returns without a usable email
- **THEN** the registration phase retains the subject and safe return state without requiring email
- **AND** provider-only username completion can continue in the initiating browser

#### Scenario: Registration state is replayed or expires
- **WHEN** registration state is missing, malformed, expired, has an unexpected phase, or is reused after terminal consumption
- **THEN** no D20 user or identity is created
- **AND** the state cannot authenticate the caller

### Requirement: Apple results normalize to minimal trusted identity data
The Apple web adapter SHALL accept only a successful result from the configured Apple strategy with a non-empty stable subject within the provider identity limit. It SHALL use the Apple subject as the opaque provider UID. A returning stored subject MAY omit email. For an unknown subject, a syntactically valid email obtained after signed ID-token validation MAY be retained as an optional verified registration candidate; missing or malformed email SHALL normalize to no candidate and MUST NOT block provider-only registration. The adapter MUST NOT pass Ueberauth structures into Accounts or persist Apple access tokens, refresh tokens, ID tokens, authorization codes, raw claims, name, avatar, relay metadata, or unrelated profile data.

#### Scenario: Initial Apple result includes valid email
- **WHEN** Apple returns a valid stable subject and syntactically valid email for an unknown identity
- **THEN** the adapter returns only provider `apple`, the opaque subject, and the optional verified email candidate
- **AND** Apple credentials and unrelated claims are discarded

#### Scenario: Returning Apple result omits profile data
- **WHEN** Apple returns the exact subject of an existing identity without name or email
- **THEN** the system can resolve the existing D20 user from the stored Apple subject
- **AND** no D20 profile field is replaced

#### Scenario: Unknown Apple result lacks usable email
- **WHEN** an unknown Apple subject has a missing or malformed email
- **THEN** the adapter retains the valid subject with no email candidate
- **AND** provider-only registration completion may start
- **AND** no fabricated email is created

### Requirement: Unknown Apple identity completes registration atomically
An unknown valid Apple subject SHALL require the guest to choose a valid unique D20 username through the shared provider-neutral registration-completion page and short-lived Apple registration state. An acceptable unused personal or private relay email SHALL be stored automatically; absent, unusable, or already-owned email SHALL produce an account with null email. The system SHALL create one completed D20 user with the username and resulting optional email and link the Apple subject in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL consume the state and authenticate the new user through the existing D20 session boundary. The completion page MUST NOT receive the Apple subject, encrypted state, token, raw provider result, or browser-editable email.

#### Scenario: Guest completes Apple registration with unused personal email
- **WHEN** a guest with a valid unknown Apple subject and unused personal email submits a valid unique username before completion expiry
- **THEN** exactly one completed D20 user is created with that email and username
- **AND** exactly one Apple identity for that subject is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary

#### Scenario: Guest completes Apple registration with unused private relay email
- **WHEN** Apple supplies a valid unowned private relay email and the guest submits a valid unique username
- **THEN** D20 accepts the relay address without requiring the personal Apple email
- **AND** the resulting completed user and Apple identity are created atomically

#### Scenario: Guest completes Apple registration without email
- **WHEN** a guest with a valid unknown Apple subject and no acceptable email candidate submits a valid unique username
- **THEN** exactly one completed D20 user is created with null email and that username
- **AND** exactly one Apple identity for that subject is linked to the new user
- **AND** the guest is authenticated

#### Scenario: Username validation fails
- **WHEN** the guest submits an invalid or already-used username with otherwise valid unexpired completion state
- **THEN** no user or identity is created
- **AND** the completion page reports the username error
- **AND** the guest can retry before the registration state expires

#### Scenario: Concurrent Apple registrations race
- **WHEN** equivalent Apple registration completions race for the same username, Apple subject, or optional email
- **THEN** database constraints allow at most one owner for each username, non-null email, and Apple subject
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Apple email never silently merges accounts
The system MUST NOT use a matching Apple personal or private relay email as proof that an unknown Apple subject owns an existing D20 account. When the Apple email already belongs to a D20 user, the callback SHALL NOT authenticate or link that user. After valid username completion, it MAY create a distinct account with null email and atomically link the unknown Apple subject. Guidance SHALL explain that linking Apple to the existing account requires authenticating that account and explicitly linking from Account Settings.

#### Scenario: Unknown Apple subject matches an existing email
- **WHEN** an unknown Apple subject returns an email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Apple subject is not linked to the existing user
- **AND** the player may complete a distinct Apple-backed account with null email
- **AND** explicit linking to the existing account still requires authenticating that account first
