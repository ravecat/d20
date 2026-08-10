## 1. Enforce the test boundary

- [x] 1.1 Add test-scoped ESLint restrictions for direct computed-style, rectangle, and element width or height dimension APIs.
- [x] 1.2 Verify the lint guard reports the existing prohibited test assertions before refactoring them.

## 2. Refactor frontend browser tests

- [x] 2.1 Replace presentation assertions in the app header and layout browser tests while preserving authentication and landmark behavior coverage.
- [x] 2.2 Replace presentation assertions in the game detail and workspace browser tests while preserving launch, status, control, focus, and interaction coverage.
- [x] 2.3 Confirm frontend tests do not substitute class-name, inline-style, CSS-variable, or exact DOM-shape assertions for removed presentation checks.

## 3. Validate the change

- [x] 3.1 Run the remaining focused browser test files and the game detail unit tests, and confirm no prohibited presentation measurement remains in frontend test sources.
- [x] 3.2 Run frontend formatting checks, lint, type checking, and the complete frontend test suite.
- [x] 3.3 Run strict OpenSpec validation for the completed change.
