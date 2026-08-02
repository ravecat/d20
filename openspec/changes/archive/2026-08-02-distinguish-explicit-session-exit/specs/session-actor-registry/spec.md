## ADDED Requirements

### Requirement: Session actor attachments use a dedicated duplicate Registry

The system SHALL supervise a local `D20.Sessions.Registry` with duplicate keys separately from the unique `D20.Registry`. Each attachment entry SHALL use the actor id as key, the registering Session process as owner PID, and the immutable Session id as value.

#### Scenario: One actor attaches to multiple Sessions

- **WHEN** two live Session processes attach the same actor id
- **THEN** lookup by that actor id returns both `{session_pid, session_id}` pairs

#### Scenario: One Session attaches multiple actors

- **WHEN** one live Session process attaches two actor ids
- **THEN** each actor lookup returns that same Session PID and id

#### Scenario: Existing runtime naming remains unique

- **WHEN** a Session process starts through `D20.Registry` and `:via`
- **THEN** `{:session, session_id}` still resolves to exactly one Session PID and its configured server module
- **AND** `D20.Sessions.Registry` is not used as a `:via` registry

### Requirement: Session processes own idempotent attachment mutations

Only the live Session process SHALL register or unregister its actor attachment entries. `D20.Sessions.Registry.attach/2` and `detach/1` SHALL be idempotent for the calling Session process and SHALL report whether the relationship changed.

#### Scenario: Session process attaches an actor

- **WHEN** a Session process attaches an actor id with its Session id
- **THEN** lookup returns the calling Session PID and Session id under that actor key
- **AND** a repeated attach does not create a duplicate entry

#### Scenario: Session process detaches an actor

- **GIVEN** the calling Session process owns an attachment under an actor key
- **WHEN** it detaches that actor
- **THEN** only entries under that actor key owned by the calling Session process are removed
- **AND** attachments owned by other Session processes remain

#### Scenario: Missing attachment is detached

- **WHEN** the calling Session process detaches an actor it has not attached
- **THEN** the result reports no relationship change
- **AND** Registry contents remain unchanged

### Requirement: Session process termination cleans attachment entries

Attachment entries SHALL share the owner Session process lifetime and SHALL be removed by Registry when that process terminates, without a manual Session termination callback.

#### Scenario: Attached Session terminates

- **GIVEN** one Session process owns attachment entries for multiple actors
- **WHEN** that Session process terminates
- **THEN** its entries disappear from every actor lookup
- **AND** entries owned by other live Session processes remain

### Requirement: Actor Session discovery uses attachment lookup

`D20.Sessions.list/1` SHALL resolve only the runtime entries returned by `D20.Sessions.Registry` for the authenticated actor and SHALL preserve the existing `{pid, {session, slug}}` return shape.

#### Scenario: Actor lists attached Sessions

- **WHEN** an actor has two attachments and unrelated Session runtimes also exist
- **THEN** `D20.Sessions.list/1` returns only the two attached runtimes
- **AND** it does not select every entry from `D20.Registry`

#### Scenario: Registry entry becomes stale during lookup

- **WHEN** an attached Session process terminates between Registry lookup and state resolution
- **THEN** `D20.Sessions.list/1` skips the unavailable runtime
- **AND** other attached live runtimes remain in the result

#### Scenario: Scope has no actor

- **WHEN** `D20.Sessions.list/1` receives a scope without an actor
- **THEN** it returns an empty list
