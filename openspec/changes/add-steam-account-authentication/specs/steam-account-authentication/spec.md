## ADDED Requirements

### Requirement: Steam authentication follows provider credentials

The system SHALL expose Steam registration, login, reauthentication, and linking only when Ueberauth's provider allowlist maps `steam` to the community `Ueberauth.Strategy.Steam` and its runtime configuration contains a nonblank `STEAM_API_KEY`. Missing, blank, or mismatched configuration MUST leave Steam unavailable without preventing startup. Only explicit Steam request, callback, completion, cancellation, and settings-link routes SHALL exist. The API key MUST remain server-side and MUST NOT appear in page props, logs, persisted records, or callback state.

#### Scenario: Steam strategy and credential are configured

- **WHEN** the expected community strategy is allowlisted and its API key is nonblank
- **THEN** shared authentication state reports Steam as available
- **AND** explicit Steam routes can participate in authentication

#### Scenario: Steam configuration is unavailable

- **WHEN** the provider allowlist has no expected Steam strategy or the API key is missing or blank
- **THEN** startup continues with Steam omitted from Register, Login, and Account Settings
- **AND** direct Steam requests or callbacks start no provider transaction
- **AND** local methods and other configured providers remain available

### Requirement: Steam authorization uses the community Ueberauth strategy

The system SHALL start Steam through full-document navigation using the allowlisted `ueberauth_steam_strategy` package. The package SHALL own OpenID request construction, provider state, direct verification, and its Steam Web API profile lookup. `D20Web.Auth.SteamController` MUST invoke it through `plug Ueberauth, providers: [:steam]` and MUST NOT construct a second OpenID request or duplicate its remote verification or profile calls. Caller-supplied provider parameters MUST NOT select another Ueberauth strategy.

#### Scenario: Guest starts Steam

- **WHEN** a guest activates an available Steam action
- **THEN** `/auth/steam` invokes the allowlisted community strategy
- **AND** the browser follows that strategy's full-document Steam redirect

#### Scenario: Provider result returns

- **WHEN** the community strategy completes its provider calls
- **THEN** the controller receives only Ueberauth success or failure through the same callback composition used by Google and Discord

### Requirement: Steam callbacks are bound to short-lived D20 intent

Starting Steam SHALL create the community strategy's provider state plus a D20 signed-session intent recording authentication, reauthentication, or link action, issue time, accepted safe local return, and expected current user for account-bound actions. The community strategy SHALL validate its state before returning success. The D20 intent SHALL expire after at most ten minutes and be consumed on success, cancellation, or terminal failure. Reauthentication and linking MUST remain bound to the same current D20 user; linking additionally requires current sudo proof. Neither MAY fall back to another action.

#### Scenario: Valid authentication intent returns

- **WHEN** the same browser returns with unexpired matching state and authentication intent
- **THEN** the community strategy result may continue to D20 identity handling
- **AND** the accepted safe return remains available

#### Scenario: Callback state is invalid

- **WHEN** state or intent is missing, malformed, expired, or mismatched
- **THEN** no account, identity, or session mutation occurs

#### Scenario: Account-bound intent loses its binding

- **WHEN** a reauthentication or link callback has another current user or no current user, or linking lacks sudo proof
- **THEN** no identity is linked and no account is switched
- **AND** the callback does not continue as registration or ordinary login

### Requirement: Community strategy remains the complete Steam protocol boundary

The community strategy SHALL own OpenID request construction, state handling, remote verification, and its Steam Web API profile lookup. After Ueberauth returns success, D20 SHALL validate only the provider tag and canonical UID supplied by that result. D20 MUST NOT repeat callback assertion validation, repeat provider or profile calls, persist OpenID response nonces, add a protocol-specific database operation, replace standard endpoint telemetry, or mutate the callback connection for protocol cleanup.

#### Scenario: Community strategy returns success

- **WHEN** the community strategy returns a successful Ueberauth result
- **THEN** D20 normalizes only its provider tag and canonical SteamID
- **AND** transient profile and raw callback data do not reach Accounts

#### Scenario: Community provider call fails

- **WHEN** the strategy's OpenID verification or profile lookup fails
- **THEN** Ueberauth returns failure to the provider controller
- **AND** no D20 account, identity, or session mutation occurs

#### Scenario: Callback repeats without D20 intent

- **WHEN** a callback is submitted after its short-lived D20 intent has been consumed or expired
- **THEN** it cannot continue to login, registration, reauthentication, or linking
- **AND** D20 creates no provider-specific replay record

### Requirement: Steam results normalize to one minimal identity

The web boundary SHALL accept only successful results from the community `Ueberauth.Strategy.Steam` and normalize its integer or string UID to provider `steam` plus canonical SteamID string. It MUST NOT pass Ueberauth structures into Accounts or persist/import OpenID state, assertion fields, signature, response nonce, Steam profile, API key, credentials, or provider result.

#### Scenario: Valid result is normalized

- **WHEN** the strategy returns a verified canonical SteamID
- **THEN** the adapter returns only provider and provider UID

#### Scenario: UID is malformed

- **WHEN** the result has another provider, non-decimal UID, zero, leading zero, or overflow
- **THEN** normalization fails before lookup or mutation

### Requirement: Returning Steam identity authenticates its exact D20 user

A returning Steam player SHALL resolve only by exact `(steam, canonical SteamID)`. A successful signed-out callback SHALL authenticate that owner through `D20Web.Auth`, rotate the browser session, and redirect only to accepted safe local return. Steam or browser data MUST NOT update account fields or select another user.

#### Scenario: Returning player signs in

- **WHEN** a valid community strategy result maps to one D20 user
- **THEN** that exact user is authenticated through the existing session boundary
- **AND** the previous session is rotated

#### Scenario: Return destination is unsafe

- **WHEN** an attempt supplies an external, protocol-relative, malformed, or backslash-containing destination
- **THEN** it is not stored or used
- **AND** successful login uses the safe fallback

### Requirement: Unknown Steam identity completes provider-only registration

An unknown verified SteamID SHALL create no account until the same browser submits a valid unique D20 username through short-lived, integrity-protected registration completion state. The completion page SHALL expose null email and generic submission metadata but MUST NOT expose SteamID, OpenID values, or provider proof in page props or form fields. Successful completion SHALL atomically create one confirmed user with null email and one exact Steam identity through the provider-neutral Accounts transaction, then clear completion state and authenticate through the existing session boundary. Steam registration MUST NOT collect, infer, require, or fabricate email and MUST NOT create pending provider identity or Magic Link state.

#### Scenario: Unknown Steam player completes registration

- **WHEN** the same browser holds valid completion state and submits a valid unique username
- **THEN** exactly one confirmed user with that username and null email is created
- **AND** exactly one Steam identity links the verified SteamID to that user
- **AND** the player is authenticated and completion state is consumed

#### Scenario: Username validation fails

- **WHEN** completion submits missing, invalid, or already-owned username
- **THEN** no user, identity, or session is created
- **AND** valid completion state remains available for correction

#### Scenario: Completion is missing, expired, consumed, or tampered

- **WHEN** completion token or browser binding is invalid or no longer valid
- **THEN** no user, identity, or session is created
- **AND** completion state is cleared with a generic retry or alternate-method action

#### Scenario: Identity ownership races completion

- **WHEN** the verified SteamID becomes owned before atomic completion commits
- **THEN** user creation rolls back with the identity insert
- **AND** the request never authenticates the winner or discloses its account

#### Scenario: Steam-created account adds email later

- **WHEN** a provider-only Steam user completes the independent Add email verification from Account Settings
- **THEN** email is attached only through issue #242 behavior
- **AND** Steam identity ownership remains unchanged

### Requirement: Steam registration never merges accounts

The system MUST NOT use browser email, Steam profile fields, username similarity, or matching local account data as proof that an unknown SteamID owns an existing account. Browser-controlled email submitted to Steam completion SHALL be ignored. Ownership changes require exact returning identity or explicit authenticated linking.

#### Scenario: Browser submits account-like data during completion

- **WHEN** Steam completion includes email or other fields besides supported username and session options
- **THEN** those fields do not select, merge, or modify another account
- **AND** any created Steam account keeps email null

### Requirement: Steam reauthentication remains account-bound

Steam reauthentication SHALL succeed only when the exact verified SteamID belongs to the current D20 user. Another or unowned SteamID MUST fail without switching or clearing the current account session.

#### Scenario: Current user confirms with linked SteamID

- **WHEN** a current user completes reauthentication with its exact linked SteamID
- **THEN** the same user remains authenticated with refreshed session proof

#### Scenario: Another SteamID returns

- **WHEN** reauthentication verifies a SteamID not owned by the current user
- **THEN** reauthentication fails generically
- **AND** the current D20 account remains selected

### Requirement: Authenticated player explicitly links Steam

Steam linking SHALL be offered only while available and unlinked. Start and callback SHALL require the same current user and sudo proof. The callback SHALL link only verified SteamID and MUST NOT switch accounts, infer ownership, or fall back to login or registration.

#### Scenario: Sudo-valid player links Steam

- **WHEN** a sudo-valid player returns with an unowned verified SteamID
- **THEN** that identity links to the same current user

#### Scenario: Same identity is already linked

- **WHEN** the same user links its existing SteamID
- **THEN** the result is idempotently linked without duplicate row

#### Scenario: Linking conflicts

- **WHEN** SteamID belongs to another user or current user already owns another SteamID
- **THEN** ownership does not change
- **AND** one generic conflict discloses no other account

### Requirement: Storybook represents Steam authentication states

The maintained Storybook catalog SHALL represent Steam in the shared Register and Login provider choices, Account Settings available and linked provider rows, and the unavailable-provider state. The generic Auth Provider Registration Completion story SHALL represent provider-only completion with null email. These references MUST reuse the production provider data shapes and generic pages, and the catalog MUST NOT introduce a Steam-specific Registration Completion story.

#### Scenario: Steam reference states are reviewed

- **WHEN** the authentication and Account Settings Storybook stories render
- **THEN** available Steam registration, login, linking, and linked identity states are directly inspectable
- **AND** the generic Auth Provider story exposes provider-only completion with null email
- **AND** the unavailable-provider story still omits unavailable provider rows

### Requirement: Steam failures fail closed and remain usable

Cancellation, callbacks received while the strategy or credential is unavailable, invalid provider state, community verification or profile failure, missing or consumed D20 intent, invalid SteamID, invalid completion state, username conflict, and identity conflict SHALL create no unauthorized session or partial identity. The system SHALL return to a safe local surface with understandable Steam retry or local-method action. Application diagnostics SHALL record semantic provider outcomes and MUST NOT deliberately include SteamID, email, API key, profile data, or provider result.

#### Scenario: Player cancels Steam

- **WHEN** Steam returns cancellation
- **THEN** no session or identity mutation occurs
- **AND** the player can retry or choose another method

#### Scenario: Provider verification is unavailable

- **WHEN** the community strategy cannot complete OpenID verification or profile lookup
- **THEN** no assertion is trusted and no retry occurs
- **AND** diagnostics contain no provider payload

### Requirement: Steam release is verified before production deployment

The Steam-capable application MUST NOT be deployed to production until automated dependency, adapter, persistence, Accounts, controller, session, configuration, frontend, provider regression, and broad checks pass and staging verifies the exact callback. Manual staging SHALL cover provider-only username completion, returning login, reauthentication, linking, cancellation, repeated or intent-less callback failure, identity conflicts, safe returns, session rotation, missing-credential behavior, and proof that profile data is not imported. Release evidence SHALL identify the third-party adapter and required `STEAM_API_KEY` without exposing its value.

#### Scenario: Staging verification is incomplete

- **WHEN** the complete staging journey, adapter, credential, or callback verification is incomplete
- **THEN** the Steam-capable release is not deployed to production

#### Scenario: Operator rolls back Steam

- **WHEN** an operator removes `STEAM_API_KEY` or an application deployment removes the Steam strategy and routes
- **THEN** new Steam registration, login, reauthentication, and linking cannot start
- **AND** local authentication, users, and identity mappings remain preserved
