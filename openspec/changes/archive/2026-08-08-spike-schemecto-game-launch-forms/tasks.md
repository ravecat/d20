## 1. Dependency Setup

- [x] 1.1 Add Schemecto at the reviewed commit and update the Mix lockfile.

## 2. Backend Form Contract

- [x] 2.1 Replace the controller `attrs` prop with a direct Schemecto JSON Schema whose root default contains typed creation values from the changeset data.
- [x] 2.2 Update controller contract coverage for empty, enum, boolean, default-value, and unavailable form states.
- [x] 2.3 Remove the obsolete `D20.Form` serializer and its focused tests after all call sites are migrated.
- [x] 2.4 Name the direct JSON Schema Inertia prop `schema` and update controller contract coverage.

## 3. Frontend Form Consumption

- [x] 3.1 Use the JSON Schema type directly for the shared game launch form contract.
- [x] 3.2 Add compatible `@sjsf/form`, basic component, and AJV validator dependencies and register the basic stylesheet.
- [x] 3.3 Replace D20-owned JSON Schema interpretation and controls with an SJSF form configured directly from the `form` schema and its defaults.
- [x] 3.4 Integrate SJSF submission, processing, and field errors with the Inertia router while preserving the flat session attrs payload.
- [x] 3.5 Update game page unit and browser tests to verify library-rendered controls, schema defaults, typed submission, and server errors.
- [x] 3.6 Remove the obsolete `AttrConfig`, `Attrs`, and `Session.attrs` client contract together with the waiting-room descriptor renderer and tests.
- [x] 3.7 Align the SJSF basic controls with the shell theme and restore the `Play` launch action label.
- [x] 3.8 Register the required SJSF ID builder option and restore launch-form initialization on game detail pages.
- [x] 3.9 Consume the `schema` prop and reserve `form` for the local SJSF form instance across the game page and tests.

## 4. Validation

- [x] 4.1 Run targeted backend controller tests and frontend game page tests.
- [x] 4.2 Run formatting, linting, type checking, dependency checks, broad repository checks, and strict OpenSpec validation.
  - Passed formatting, linting, type checking, production asset build, 501 backend tests, 119 frontend tests with 1 skip, focused launch-form tests in Chromium and Firefox, and strict validation of the change.
  - The first `just check` attempt hit the pre-existing flaky Firefox workspace control test; the isolated test then passed 16/16 across both browsers and the repeated full frontend suite passed.
  - Dependency checks report the existing Postgrex advisory, four unused Mix lock entries, and 52 frontend audit findings; resolving them remains outside this form-initialization fix.
- [x] 4.3 Verify the styled launch form in the running application at desktop and mobile viewports.
- [x] 4.4 Re-run focused controller tests, game page tests, formatting, and type checking after the prop rename.
  - Passed 32 controller tests, 14 game page unit tests, 4 game page browser tests, frontend type checking, and targeted ESLint.
