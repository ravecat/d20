## 1. Backend shared contract

- [x] 1.1 Update Inertia controller coverage to require one nested auth object and reject the former flat shared props.
- [x] 1.2 Replace the two auth publication plugs with one `put_auth_prop/2` implementation that preserves one-time prompt consumption.

## 2. Frontend reactive consumption

- [x] 2.1 Define the global Inertia Auth and AuthPrompt shared-prop types and give the test Page mock the complete default object.
- [x] 2.2 Update Header and AuthDialog to read their auth values from reactive Page data without forwarding mailbox availability.
- [x] 2.3 Convert the focused Header and Layout browser fixtures to the nested auth shape while preserving their existing behavioral assertions.
- [x] 2.4 Add the required auth object to direct Inertia page-component fixtures exposed by the stricter shared-prop type.
- [x] 2.5 Remove the obsolete `status` values that the existing typed GamePage test migration exposed as non-props.
- [x] 2.6 Add the official Svelte XState Store binding and a directly imported `auth` singleton with inline contexts and typed account-dialog transitions.
- [x] 2.7 Move Header and AuthDialog workflow state to the singleton without forwarding auth values or dialog initialization props.
- [x] 2.8 Add deterministic store reset coverage and preserve the focused account-dialog browser scenarios.

## 3. Validation

- [x] 3.1 Format touched files and run the focused PageController, Header browser, and Layout browser tests.
- [x] 3.2 Run frontend lint and type checks, strict OpenSpec validation, auth-prop reference search, and final diff checks.
- [x] 3.3 Run the focused auth store and browser tests, frontend lint and type checks, strict OpenSpec validation, and final diff checks after the store refactor.
